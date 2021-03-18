# Ultimate get and run daemon
require "log"
require "redis"
require "./tools/*"
require "./client"
require "./server"

module Crash
  VERSION = "0.1.0"
  Log = ::Log.for("main")

  class Daemon
  	options = Options.new
    Log.info { "Crash version #{VERSION} started" }
    Log.level = :debug if options.settings.debug?
    topic = options.settings.topic
    if options.settings.slave?
      # connects to redis
      client = Client.new(options)
      client.subscribe_me(topic)
    else
      command = options.commands.command
      hosts = options.commands.hosts
      server = Server.new(options)
      
      server.publish_to(topic, hosts, command)
    end
  end
end
