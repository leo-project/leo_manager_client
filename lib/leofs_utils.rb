module LeofsUtils
  VERSION = "0.0.1"

  class Manager
    def initialize(host, port, slave_port=nil)
      @host = host
      @port = port
      @slave_port = slave_port
      @socket = TCPSocket.new(@host, @port)
    end

    attr_reader :host, :port, :slave_port

    def send_data(data)
      @socket.write(data) 
    end

    def read
      @socket.read
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  m = LeofsUtils::Manager.new("localhost", 10010)
  m.send_data("status\n")
  m.read
end
