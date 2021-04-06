module Crash
  class Server
    Log = ::Log.for("server")
    def initialize(@options : Crash::Options)
      settings = @options.settings
      Log.level = :debug if settings.debug?

      @redis = Redis.new(host: settings.server, port: settings.port.to_i, reconnect: true)
      Log.debug { "connected to #{settings.server}:#{settings.port}" }
    end

    def publish_to(topic : String, hosts : String, command : Array(String))
      payload = "#{hosts}:#{command.join(" ")}"
      @redis.publish(topic, payload)
      sleep 2 # give it some time to populate names
      callback_get
    end

    def callback_get
      timeout = @options.commands.timeout
      hosts = @redis.keys("*")
      Log.debug { "hosts: #{hosts}" }
      hosts.each do |host|
        typ = @redis.type("#{host}")
        if typ == "string"
          0.upto(timeout.to_i) do |cnt|
            payload = host_get("#{host}")
            break if payload
            sleep 1 # ask every second
            if cnt == timeout.to_i
              Log.error { "#{host} timed out" }
            end
          end
        end
      end
    end

    private def host_get(host) : String | Bool | Nil
      payload = @redis.get("#{host}")
      if payload == "--in-progress--"
        Log.debug { "#{host}: in progress" }
        false
      else
        Log.info { "#{host}: #{payload}" }
        @redis.del("#{host}")
        payload
      end
    end
  end
end
