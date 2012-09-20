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

  Interval = 3

  def self.classify(command)
    class_name = command.to_s
    class_name.gsub!(/([a-z0-9]+)_?/) { $1.capitalize }
    class_name
  end

  class Error < StandardError; end

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

    def eql?(other)
      to_hash == other.to_hash
    end

    def inspect
      "#<#{self.class} #{to_hash}>"
    end

    def to_hash
      hash = Hash[__getobj__.each_pair.to_a]
      hash.each do |key, value|
        hash[key] = value.to_hash if value.is_a? RecurStruct
      end
    end
  end

  class Remover
    def initialize(data)
      @data = data
    end

    def call(*args)
      socket = @data[0]
      warn "Closing socket: #{socket}" if $DEBUG
      socket.close if socket && !socket.closed?
      warn "Closed socket: #{socket}" if $DEBUG
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
        host = m[:host]
        port = Integer(m[:port])
        raise Error, "Invalid Port Number: #{port}" unless 0 <= port && port <= 65535
        { :host => host, :port => port, :retry_count => 0 }
      else
        server
      end
    end

    @data = []
    final = Remover.new(@data)
    ObjectSpace.define_finalizer(self, final)

    @servers = servers
    set_current_server
    connect
  end

  attr_reader :servers, :current_server

  private

  def set_current_server
    raise Error, "No servers to connect" if @servers.empty?
    @current_server = @servers.first 
  end

  def connect
    begin
      @socket = TCPSocket.new(@current_server[:host], @current_server[:port])
      @data[0] = @socket
    rescue => ex
      warn "Faild to connect: #{ex.class} (server: #{@current_server})"
      warn ex.message
      handle_exception
      retry
    end
  end

  def handle_exception
    @current_server[:retry_count] += 1
    if @current_server[:retry_count] < 3
      warn "Retrying..."
    else
      warn "Connecting another server..."
      @socket.close if @socket && !@socket.closed?
      @servers.delete(@current_server)
      set_current_server
    end
  end

  Commands.each do |command|
    define_method(command) do |*args|
      command = __method__
      line = args.unshift(command).join(" ")
      res_class = Response.const_get(self.class.classify(command))
      begin
        @socket.puts line
        hash = JSON.parse(@socket.gets, symbolize_names: true)
      rescue => ex
        warn "An Error occured: #{ex.class} (server: #{@current_server})"
        warn ex.message
        handle_exception
        retry
      end
      return res_class.new(hash)
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  require "pp"

  $DEBUG = true
  m = LeoFSManager.new("localhost:10020", "localhost:10021")
  p m.status
end
