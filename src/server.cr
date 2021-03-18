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
    end
  end
end
