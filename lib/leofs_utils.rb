require "socket"
require "json"
require "delegate"

class LeoFSManager
  VERSION = "0.0.1"

  Commands = [
    :detach, :suspend, :resume,
    :start, :rebalance, :whereis,
    :du, :compact, :purge,
    :s3_gen_key, :s3_set_endpoint,
    :s3_delete_endpoint,
    :s3_get_endpoints,
    :s3_get_buckets,
    :version, :status,
    :history, :quit
  ]

  def self.classify(command)
    class_name = command.to_s
    class_name.gsub!(/([a-z0-9]+)_?/) { $1.capitalize }
    class_name
  end

  class RecurStruct < DelegateClass(Struct)
    def initialize(hash)
      values = hash.values.map do |value|
        case value
        when Hash
          self.class.new(value)
        when Array
          value.map {|s| self.class.new(s) }
        else
          value
        end
      end
      super(Struct.new(*hash.keys).new(*values))
    end

    def inspect
      "#<#{self.class} #{to_hash}>"
    end

    def to_hash
      Hash[__getobj__.each_pair.to_a]
    end
  end

  class Response 
    Commands.each do |command|
      response = LeoFSManager.classify(command)
      const_set(response, Class.new(RecurStruct))
    end
  end

  def initialize(*servers)
    servers.map! do |server|
      if server.is_a? String
        m = server.match(/(?<host>.+):(?<port>[0-9]{1,5})/)
        { :host => m[:host], :port => m[:port] }
      else
        server
      end
    end

    @servers = servers
    @current_server = @servers.sample

    begin
      @socket = TCPSocket.new(@current_server[:host], @current_server[:port])
    rescue => ex
      warn "faild to connect (server: #{@current_server})"
      warn ex.message
      @socket.close if @socket && !@socket.closed?
      sleep 3
      warn "retrying..."
      retry
    end
  end

  attr_reader :servers, :current_server

  Commands.each do |command|
    define_method(command) do |*args|
      command = __method__
      res_class = Response.const_get(self.class.classify(command))
      begin
        @socket.puts command
        hash = JSON.parse(@socket.gets, symbolize_names: true)
      rescue => ex
        warn "an error occured (server: #{@current_server})"
        warn ex.message
        @socket.close if @socket && !@socket.closed?
        @servers.delete(@servers)
      end
      res_class.new(hash)
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  require "pp"

  m = LeoFSManager.new("localhost:10020")
  p m.status
=begin
  LeoFSUtils::Manager::Commands.each do |command|
    puts command
    m.send(command)
  end
=end
end
