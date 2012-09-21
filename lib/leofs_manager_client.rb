# ======================================================================
#
#  LeoFS Manager Client
#
#  Copyright (c) 2012 Rakuten, Inc.
#
#  This file is provided to you under the Apache License,
#  Version 2.0 (the "License"); you may not use this file
#  except in compliance with the License.  You may obtain
#  a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing,
#  software distributed under the License is distributed on an
#  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
#  KIND, either express or implied.  See the License for the
#  specific language governing permissions and limitations
#  under the License.
#
# ======================================================================
require "socket"
require "json"
require "delegate"

class LeoFSManager
  VERSION = "0.2.0"

  ## LeoFS-related commands:
  CMD_VERSION         = "version"
  CMD_STATUS          = "status"
  CMD_START           = "start"
  CMD_DETACH          = "detach"
  CMD_SUSPEND         = "suspend"
  CMD_RESUME          = "resume"
  CMD_REBALANCE       = "rebalance"
  CMD_WHEREIS         = "whereis"
  CMD_DU              = "du"
  CMD_COMPACT         = "compact"
  CMD_PURGE           = "purge"
  CMD_S3_GEN_KEY      = "s3-gen-key"
  CMD_S3_SET_ENDPOINT = "s3-set-endpoint"
  CMD_S3_DEL_ENDPOINT = "s3-delete-endpoint"
  CMD_S3_GET_ENDPOINT = "s3-get-endpoint"
  CMD_S3_ADD_BUCKET   = "s3-add-bucket"
  CMD_S3_GET_BUCKETS  = "s3-get-buckets"

  attr_reader :servers, :current_server

  ## ======================================================================
  ## APIs
  ## ======================================================================
  ## @doc
  ##
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
    res = set_current_server
    connect
  end

  ## @doc Retrieve LeoFS's version from LeoFS Manager
  ## @return version
  def version
    h = sender(CMD_VERSION)
    return  h[:result]
  end

  ## @doc Retrieve LeoFS's system status from LeoFS Manager
  ## @return
  def status
    h = sender(CMD_STATUS)
    ## @TODO - Map to SystemInfo.class and NodeInfo.class
    return h
  end

  ## @doc Launch LeoFS's storage cluster
  ## @return null
  def start
    h = sender(CMD_START)
    if h[:result]
      null
    else
      p "Exception!!"
    end
  end


  ## ======================================================================
  ## CLASS
  ## ======================================================================
  ## @doc System Information Model
  ##
  class SystemInfo    
  end

  ## @doc Node Info Model
  ##
  class NodeInfo
  end

  ## @doc Error
  ##
  class Error < StandardError; end


  ## @doc
  ##
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


  ## ======================================================================
  ## PRIVATE
  ## ======================================================================
  private

  ## @doc
  ##
  def set_current_server
    raise Error, "No servers to connect" if @servers.empty?
    @current_server = @servers.first
  end

  ## @doc Connect to LeoFS Manager
  ##
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

  ## @doc Handle exceptions
  ##
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

  ## @doc Send a request to LeoFS Manager
  ## @return Hash
  def sender(command)
    begin
      @socket.puts command
      hash = JSON.parse(@socket.gets, symbolize_names: true)
    rescue => ex
      warn "An Error occured: #{ex.class} (server: #{@current_server})"
      warn ex.message
      handle_exception
      retry
    end
    return hash
  end
end


## ======================================================================
## 
## ======================================================================
if __FILE__ == $PROGRAM_NAME
  require "pp"

  $DEBUG = true
  m = LeoFSManager.new("localhost:10020", "localhost:10021")
  p m.status
  p m.version

end
