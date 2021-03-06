module Crash
  class Client
    Log = ::Log.for("client")
    def initialize(@options : Crash::Options)
      settings = @options.settings
      Log.level = :debug if settings.debug?

      @redis = Redis.new(host: settings.server, port: settings.port.to_i, reconnect: true)
      # ugly hack for command while redis is in subscrube mode
      @respond = Redis.new(host: settings.server, port: settings.port.to_i, reconnect: true)
      Log.debug { "listening #{settings.server}:#{settings.port}" }
    end

    def subscribe_me(topic : String)

      backoff = 1
      me = System.hostname

      x = -> {
        begin
          @redis.subscribe(topic) do |on|
            on.message do |channel, message|
              Log.debug { "got #{message}" }
              parsed = message.split(":")
              hosts = parsed[0].split(",")
              command = if parsed.size > 1
                parsed[1]
              else
                nil
              end

              matched = hosts.select { |h| me.match(/#{h}/) || h.match(/^all$/) }

              if matched.empty?
                Log.debug { "not me" }
              else
                Log.debug { "hosts: #{matched}" }
                if command.nil? || command.empty?
                  Log.error { "Empty command" }
                else
                  Log.debug { "command: #{command}" }
                  @respond.set("#{me}", "--in-progress--")
                  response = run_cmd(command)
                  responder(response)
                end
              end
            end
          end
        rescue
          sleep backoff
          :__retry__ # no retry in crystal https://github.com/crystal-lang/crystal/issues/1736
        end
      }
      loop do
        break unless x.call == :__retry__
      end
    end

    private def run_cmd(command, env = nil) : String
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      parsed = command.split(" ")
      cmd  = parsed[0]
      if parsed.size > 1
        args  = parsed[1..]
      end

      status = Process.run(cmd, args: args, env: env, output: stdout, error: stderr, shell: true)
      if status.success?
        stdout.to_s
      else
        stderr.to_s
      end
    end

    private def responder(payload : String)
      me = System.hostname
      Log.debug { "redis.set #{me}: #{payload}" }
      @respond.set("#{me}", "#{payload}")
    end
  end
end

