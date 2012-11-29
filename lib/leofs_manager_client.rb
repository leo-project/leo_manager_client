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
  VERSION = "0.2.8"

  class Client
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
    CMD_S3_CRE_USER      = "s3-create-user %s %s"
    CMD_S3_GET_KEYS      = "s3-get-keys"
    CMD_S3_SET_ENDPOINT  = "s3-set-endpoint %s"
    CMD_S3_DEL_ENDPOINT  = "s3-delete-endpoint %s"
    CMD_S3_GET_ENDPOINTS = "s3-get-endpoints"
    CMD_S3_ADD_BUCKET    = "s3-add-bucket %s %s"
    CMD_S3_GET_BUCKETS   = "s3-get-buckets"

    # ======================================================================
    # APIs
    # ======================================================================
    # Constructor
    #
    def initialize(*servers)
      @servers = parse_servers(servers)
      set_current_server
      @mutex = Mutex.new
      connect
    end

    # servers to connect 
    attr_reader :servers
    # the server currently connected
    attr_reader :current_server

    # Retrieve LeoFS's version from LeoFS Manager
    # Return::
    #   Version of LeoFS
    def version
      h = sender(CMD_VERSION)
      return h[:result]
    end

    # Retrieve LeoFS's system status from LeoFS Manager
    # Return::
    #   Status 
    def status(node=nil)
      Status.new(sender(CMD_STATUS % node))
    end

    # Launch LeoFS's storage cluster
    # Return::
    #   _nil_
    def start
      sender(CMD_START)
      nil
    end

    # Leave a node from the storage cluster
    # Return::
    #   _nil_
    def detach(node)
      sender(CMD_DETACH % node)
      nil
    end

    # Suspend a node in the storage cluster
    # Return::
    #   _nil_
    def suspend(node)
      sender(CMD_SUSPEND % node)
      nil
    end

    # Resume a node in the storage cluster
    # Return::
    #   _nil_
    def resume(node)
      sender(CMD_RESUME % node)
      nil
    end

    # Execute 'rebalance' in the storage cluster
    # Return::
    #   _nil_
    def rebalance
      sender(CMD_REBALANCE)
      nil
    end

    # Retrieve assigned file information
    # Return::
    #   Array of AssignedFile
    def whereis(path)
      assigned_info = sender(CMD_WHEREIS % path)[:assigned_info]
      assigned_info.map {|h| AssignedFile.new(h)}
    end

    # Retrieve storage status from the storage
    # Return::
    #   StorageStat
    def du(node)
      StorageStat.new(sender(CMD_DU % node))
    end

    # Execute 'compaction'
    # Return::
    #   _nil_
    def compact(node)
      sender(CMD_COMPACT % node)
      nil
    end

    # Purge a cache in gateways
    # Return::
    #   _nil_
    def purge(path)
      sender(CMD_PURGE % path)
      nil
    end

    # Generate credential for LeoFS
    # Return::
    #   Credential
    def s3_create_user(user_id, password)
      Credential.new(sender(CMD_S3_CRE_USER % [user_id, password]))
    end

    def s3_get_keys
      users = sender(CMD_S3_GET_KEYS)[:users]
      users.map {|account| User.new(account) }
    end

    # Insert an endpoint in the system
    # Return::
    #   _nil_
    def s3_set_endpoint(endpoint)
      sender(CMD_S3_SET_ENDPOINT % endpoint)
      nil
    end

    # Remove an endpoint from the system
    # Return::
    #   _nil_
    def s3_delete_endpoint(endpoint)
      sender(CMD_S3_DEL_ENDPOINT % endpoint)
      nil
    end
    alias :s3_del_endpoint :s3_delete_endpoint

    # Retrieve an endpoint in the system
    # Return::
    #   Array of Endpoint
    def s3_get_endpoints
      endpoints = sender(CMD_S3_GET_ENDPOINTS)[:endpoints]
      endpoints.map {|endpoint| Endpoint.new(endpoint) }
    end

    # Add an Bucket in the system
    # Return::
    #   _nil_
    def s3_add_bucket(bucket_name, access_key_id)
      sender(CMD_S3_ADD_BUCKET % [bucket_name, access_key_id])
      nil
    end

    # Retrieve all buckets from the system
    # Return::
    #   Array of Bucket
    def s3_get_buckets
      buckets = sender(CMD_S3_GET_BUCKETS)[:buckets]
      buckets.map {|bucket| Bucket.new(bucket) }
    end

    # Disconnect to LeoFS Manager explicitly
    # Return::
    #   _nil_
    def disconnect!
      disconnect
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

          raise "Invalid Port Number: #{port}" unless 0 <= port && port <= 65535
          { :host => host, :port => port, :retry_count => 0 }
        else
          server
        end
      end
    end

    def set_current_server
      @servers.delete(@current_server) if @current_server
      raise "No servers to connect" if @servers.empty?
      @current_server = @servers.first
    end

    # Connect to LeoFS Manager
    def connect
      retry_count = 0
      begin
        @socket = TCPSocket.new(@current_server[:host], @current_server[:port])
      rescue => ex
        warn "Faild to connect: #{ex.class} (server: #{@current_server})"
        warn ex.message
        retry_count += 1
        if retry_count > 3
          set_current_server
          warn "Connecting another server: #{@current_server}"
          retry_count = 0
        end
        sleep 1
        retry
      end
      @socket.autoclose = true
      nil
    end

    def disconnect
      @socket.close if @socket && !@socket.closed?
    end

    def reconnect
      disconnect
      sleep 1
      connect
    end

    # Send a request to LeoFS Manager
    # Return::
    #   Hash
    def sender(command)
      response = nil
      begin
        @mutex.synchronize do
          @socket.print "#{command}\r\n"
          response = JSON.parse(@socket.readline, symbolize_names: true)
        end
      rescue EOFError => ex
        warn "EOFError occured (server: #{@current_server})"
        reconnect
      rescue => ex
        raise "An Error occured: #{ex.class} (server: #{@current_server})\n#{ex.message}"
      else
        raise response[:error] if response.has_key?(:error)
        return response
      end
    end
  end
end

# This section runs only when the file executed directly.
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
