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
require "time"

require_relative "leofs_manager_client/leofs_manager_models"

module LeoFSManager
  VERSION = "0.2.1"

  class Remover
    def initialize(data)
      @data = data
    end

    def call(*args)
      socket = @data[0]
      socket.close if socket && !socket.closed?
      warn "Closed socket: #{socket}" if $DEBUG
    end
  end

  class Client
    ## LeoFS-related commands:
    CMD_VERSION          = "version"
    CMD_STATUS           = "status %s"
    CMD_START            = "start"
    CMD_DETACH           = "detach %s"
    CMD_SUSPEND          = "suspend %s"
    CMD_RESUME           = "resume %s"
    CMD_REBALANCE        = "rebalance"
    CMD_WHEREIS          = "whereis %s"
    CMD_DU               = "du %s"
    CMD_COMPACT          = "compact %s"
    CMD_PURGE            = "purge %s"
    CMD_S3_GEN_KEY       = "s3-gen-key %s"
    CMD_S3_SET_ENDPOINT  = "s3-set-endpoint %s"
    CMD_S3_DEL_ENDPOINT  = "s3-delete-endpoint %s"
    CMD_S3_GET_ENDPOINTS = "s3-get-endpoints"
    CMD_S3_ADD_BUCKET    = "s3-add-bucket %s %s"
    CMD_S3_GET_BUCKETS   = "s3-get-buckets"

    ## ======================================================================
    ## APIs
    ## ======================================================================
    ## @doc Constructor
    ##
    def initialize(*servers)
      @servers = parse_servers(servers)
      set_current_server
      final = Remover.new(@data = [])
      ObjectSpace.define_finalizer(self, final)
      connect
    end

    attr_reader :servers, :current_server

    ## @doc Retrieve LeoFS's version from LeoFS Manager
    ## @return version
    def version
      h = sender(CMD_VERSION)
      return h[:result]
    end

    ## @doc Retrieve LeoFS's system status from LeoFS Manager
    ## @return
    def status(node=nil)
      Status.new(sender(CMD_STATUS % node))
    end

    ## @doc Launch LeoFS's storage cluster
    ## @return nil
    def start
      sender(CMD_START)
      nil
    end

    ## @doc Leave a node from the storage cluster
    ##
    def detach(node)
      sender(CMD_DETACH % node)
      nil
    end

    ## @doc Suspend a node in the storage cluster
    ##
    def suspend(node)
      sender(CMD_SUSPEND % node)
      nil
    end

    ## @doc Resume a node in the storage cluster
    ##
    def resume(node)
      sender(CMD_RESUME % node)
      nil
    end

    ## @doc Execute 'rebalance' in the storage cluster
    ##
    def rebalance
      sender(CMD_REBALANCE)
      nil
    end

    ## @doc Retrieve assigned file information
    ##
    def whereis(path)
      whereis = sender(CMD_WHEREIS % path)[:buckets]
      whereis.map {|h| WhereInfo.new(h)}
    end

    ## @doc Retrieve storage status from the storage
    ##
    def du(node)
      DiskUsage.new(sender(CMD_DU % node))
    end

    ## @doc Execute 'compaction'
    ##
    def compact(node)
      sender(CMD_COMPACT % node)
      nil
    end

    ## @doc Purge a cache in gateways
    ##
    def purge(path)
      sender(CMD_PURGE % path)
      nil
    end

    ## @doc Generate credential for LeoFS
    ##
    def s3_gen_key(user_id)
      Credential.new(sender(CMD_S3_GEN_KEY % user_id))
    end

    ## @doc Insert an endpoint in the system
    ##
    def s3_set_endpoint(endpoint)
      sender(CMD_S3_SET_ENDPOINT % endpoint)
      nil
    end

    ## @doc Remove an endpoint from the system
    ##
    def s3_del_endpoint(endpoint)
      sender(CMD_S3_DEL_ENDPOINT % endpoint)
      nil
    end

    ## @doc Retrieve an endpoint in the system
    ##
    def s3_get_endpoints
      endpoints = sender(CMD_S3_GET_ENDPOINTS)[:endpoints]
      endpoints.map {|endpoint| Endpoint.new(endpoint) }
    end
  
    def s3_add_bucket(bucket_name, access_key_id)
      sender(CMD_S3_ADD_BUCKET % [bucket_name, access_key_id])
      nil
    end

    ## @doc Retrieve all buckets from the system
    ##
    def s3_get_buckets
      buckets = sender(CMD_S3_GET_BUCKETS)[:buckets]
      buckets.map {|bucket| Bucket.new(bucket) }
    end

    ## ======================================================================
    ## PRIVATE
    ## ======================================================================
    private

    def parse_servers(servers)
      servers.map do |server|
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
    end

    ## @doc
    ##
    def set_current_server
      raise Error, "No servers to connect" if @servers.empty?
      @current_server = @servers.first
    end

    ## @doc Connect to LeoFS Manager
    ##
    def connect
      retry_count = 0
      begin
        @socket = TCPSocket.new(@current_server[:host], @current_server[:port])
        @data[0] = @socket
      rescue => ex
        warn "Faild to connect: #{ex.class} (server: #{@current_server})"
        warn ex.message
        retry_count += 1
        if retry_count > 3
          warn "Connecting another server..."
          @socket.close if @socket && !@socket.closed?
          @servers.delete(@current_server)
          set_current_server
          retry_count = 0
        end
        retry
      end
    end

    ## @doc Send a request to LeoFS Manager
    ## @return Hash
    def sender(command)
      begin
        @socket.puts command
        response = JSON.parse(@socket.gets, symbolize_names: true)
      rescue => ex
        raise "An Error occured: #{ex.class} (server: #{@current_server})\n#{ex.message}"
      end
      raise response[:error] if response.has_key?(:error)
      return response
    end
  end
end


if __FILE__ == $PROGRAM_NAME
  require "pp"

  $DEBUG = true
  m = LeoFSManager::Client.new("localhost:10020", "localhost:10021")
  p m.version
  p m.status
  p m.status("storage_0@127.0.0.1")
  p m.s3_get_buckets()
  p m.whereis("photo/hawaii-0.jpg")
end
