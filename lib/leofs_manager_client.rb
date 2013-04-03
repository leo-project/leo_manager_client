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
  VERSION = "0.4.2"

  class Client
    CMD_VERSION           = "version"
    CMD_LOGIN             = "login %s %s"
    CMD_STATUS            = "status %s"
    CMD_START             = "start"
    CMD_DETACH            = "detach %s"
    CMD_SUSPEND           = "suspend %s"
    CMD_RESUME            = "resume %s"
    CMD_REBALANCE         = "rebalance"
    CMD_WHEREIS           = "whereis %s"
    CMD_DU                = "du %s"
    CMD_COMPACT_START     = "compact start %s %s %s"
    CMD_COMPACT_START_ALL = "compact start %s all"
    CMD_COMPACT_SUSPEND   = "compact suspend %s"
    CMD_COMPACT_RESUME    = "compact resume %s"
    CMD_COMPACT_STATUS    = "compact status %s"
    CMD_PURGE             = "purge %s"
    CMD_CRE_USER          = "create-user %s %s"
    CMD_UPD_USER_ROLE     = "update-user-role %s %s"
    CMD_UPD_USER_PASS     = "update-user-password %s %s"
    CMD_DEL_USER          = "delete-user %s"
    CMD_GET_USERS         = "get-users"
    CMD_SET_ENDPOINT      = "set-endpoint %s"
    CMD_DEL_ENDPOINT      = "delete-endpoint %s"
    CMD_GET_ENDPOINTS     = "get-endpoints"
    CMD_ADD_BUCKET        = "add-bucket %s %s"
    CMD_GET_BUCKETS       = "get-buckets"

    USER_ROLES = RoleDef.invert

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

    # Login as specifies user
    # Return::
    #   LoginInfo
    def login(user_id, password)
      LoginInfo.new(sender(CMD_LOGIN % [user_id, password]))
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

    # Execute 'compact start'
    # Return::
    #   _nil_
    def compact_start(node, num_of_targets_or_all, num_of_concurrents=nil)
      case num_of_targets_or_all.to_s
      when /^all$/i
        sender(CMD_COMPACT_START_ALL % node)
      else
        num_of_concurrents = num_of_concurrents ? Integer(num_of_concurrents) : ""
        sender(CMD_COMPACT_START % [node, Integer(num_of_targets_or_all), num_of_concurrents])
      end
      nil
    end

    # Execute 'compact suspend'
    # Return::
    #   _nil_
    def compact_suspend(node)
      sender(CMD_COMPACT_SUSPEND % node)
      nil
    end

    # Execute 'compact suspend'
    # Return::
    #   _nil_
    def compact_resume(node)
      sender(CMD_COMPACT_RESUME % node)
      nil
    end

    # Execute 'compact status'
    # Return::
    #   _nil_
    def compact_status(node)
      compaction = sender(CMD_COMPACT_STATUS % node)[:compaction_status]
      CompactionStatus.new(compaction)
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
    def create_user(user_id, password=nil)
      Credential.new(sender(CMD_CRE_USER % [user_id, password]))
    end

    # Update user role
    # Return ::
    #   _nil_
    def update_user_role(user_id, role)
      role = role.to_sym if role.is_a? String
      role = USER_ROLES[role] if role.is_a? Symbol
      sender(CMD_UPD_USER_ROLE % [user_id, role])
      nil
    end

    # Update user password
    # Return::
    #   _nil_
    def update_user_password(user_id, new_password)
      sender(CMD_UPD_USER_PASS % [user_id, new_password])
      nil
    end

    # Delete user
    # Return::
    #   _nil_
    def delete_user(user_id)
      sender(CMD_DEL_USER % user_id)
      nil
    end

    def get_users
      users = sender(CMD_GET_USERS)[:users]
      users.map {|account| User.new(account) }
    end

    # Insert an endpoint in the system
    # Return::
    #   _nil_
    def set_endpoint(endpoint)
      sender(CMD_SET_ENDPOINT % endpoint)
      nil
    end

    # Remove an endpoint from the system
    # Return::
    #   _nil_
    def delete_endpoint(endpoint)
      sender(CMD_DEL_ENDPOINT % endpoint)
      nil
    end
    alias :del_endpoint :delete_endpoint

    # Retrieve an endpoint in the system
    # Return::
    #   Array of Endpoint
    def get_endpoints
      endpoints = sender(CMD_GET_ENDPOINTS)[:endpoints]
      endpoints.map {|endpoint| Endpoint.new(endpoint) }
    end

    # Add an Bucket in the system
    # Return::
    #   _nil_
    def add_bucket(bucket_name, access_key_id)
      sender(CMD_ADD_BUCKET % [bucket_name, access_key_id])
      nil
    end

    # Retrieve all buckets from the system
    # Return::
    #   Array of Bucket
    def get_buckets
      buckets = sender(CMD_GET_BUCKETS)[:buckets]
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
          line = @socket.readline
          warn line if $DEBUG
          response = JSON.parse(line, symbolize_names: true)
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
  p m.get_buckets()
  p m.whereis("photo/hawaii-0.jpg")
  p m.du("storage_0@127.0.0.1")
  p m.compact_status("storage_0@127.0.0.1")
end
