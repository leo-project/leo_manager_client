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
      values = hash.values.map do |s|
        case s
        when Hash
          self.class.new(s)
        when Array
          s.map {|ss| self.class.new ss }
        else
          s
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

  def initialize(host, port, slave_port=nil)
    @host = host
    @port = port
    @slave_port = slave_port
    @socket = TCPSocket.new(@host, @port)
  end

  attr_reader :host, :port, :slave_port

  Commands.each do |command|
    define_method(command) do |*args|
      command = __method__
      res_class = Response.const_get(self.class.classify(command))
      begin
        @socket.puts command
        hash = JSON.parse(@socket.gets, symbolize_names: true)
      rescue => ex
        
      end
      res_class.new(hash)
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  require "pp"

  m = LeoFSManager.new("localhost", 10020)
  p m.status
=begin
  LeoFSUtils::Manager::Commands.each do |command|
    puts command
    m.send(command)
  end
=end
end
