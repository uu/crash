require "option_parser"
require "ini"
require "log"
require "validator"

module Crash
  class Settings
    property config_path = "/etc/crash.ini"
    property port = "6379"
    property server = "127.0.0.1"
    property user = "" # redis ACL
    property pass = ""
    property topic = "commands"
    property? debug = false
    property? godmode = false
    property? slave = false
  end

  class Commands
    property hosts = "" # limit by hostname
    property command = Array(String).new
  end

  class Options

    getter settings
    getter commands
    Log = ::Log.for("config")

    def initialize
      @settings = Settings.new
      @commands = Commands.new

      OptionParser.parse do |p|
        p.banner = "crash [-d] [-h] [-v] [-l host1,host2] [-c /etc/crash.ini] command"

        p.on("-c /etc/crash.ini", "--config=/etc/crash.ini", "Main config") do |config|
          @settings.config_path = config
        end

        p.on("-l hosts", "--limit hosts", "Limit command only to hosts.") do |hosts|
          @commands.hosts = hosts
        end

        p.on("-d", "If set, debug messsages will be shown.") do
          @settings.debug = true
        end

        p.on("--godmode", "Godmode. Not asking for the host limit") do
          @settings.godmode = true
        end

        p.on("-h", "--help", "Displays this message.") do
          puts p
          exit
        end

        p.on("-v", "--version", "Displays version.") do
          puts VERSION
          exit
        end

        p.unknown_args do |args|
          # this is where the command live ¯\_(ツ)_/¯
          @commands.command = args
        end
    
      end rescue abort "Invalid arguments, see --help."
      parse_config(@settings.config_path)
    end

    private def parse_config(config)
      parsed = INI.parse(File.read(config))
      begin
        server = parsed["redis"]["server"]
        port = parsed["redis"]["port"]
        abort "invalid server '#{server}'" unless Valid.ip?(server)
        @settings.server = server
        abort "invalid port '#{port}'" unless Valid.port?(port)
        @settings.port = port
        @settings.user = parsed["redis"]["user"]
        @settings.pass = parsed["redis"]["pass"]
        @settings.topic = parsed["redis"]["topic"]
        @settings.slave = parsed["main"]["slave"] == "true" ? true : false # https://github.com/crystal-lang/crystal/issues/7538
        Log.info { "Config loaded #{@settings.slave?}" }
      rescue
        abort "Config parsing failed"
      end
    end
  end
end

