# ======================================================================
#
#  LeoFS Manager Client
#
#  Copyright (c) 2012-2014 Rakuten, Inc.
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

require_relative "leo_manager_models"

module LeoManager
  VERSION = "0.4.11"

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
    CMD_DELETE_BUCKET     = "delete-bucket %s %s"
    CMD_GET_BUCKETS       = "get-buckets"
    CMD_UPDATE_ACL        = "update-acl %s %s %s"
    CMD_RECOVER_FILE      = "recover file %s"
    CMD_RECOVER_NODE      = "recover node %s"
    CMD_RECOVER_RING      = "recover ring %s"

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
    # ==== Return
    #   Version of LeoFS
    def version
      h = call(CMD_VERSION)
      return h[:result]
    end

    # Retrieve LeoFS's system status from LeoFS Manager
    # ==== Args
    #   node :: Node
    # ==== Return
    #   Status
    def status(node=nil)
      Status.new(call(CMD_STATUS % node))
    end

    # Login as specifies user
    # ==== Args
    #   user_id  :: user id
    #   password :: password
    # ==== Return
    #   LoginInfo
    def login(user_id, password)
      LoginInfo.new(call(CMD_LOGIN % [user_id, password]))
    end

    # Launch LeoFS's storage cluster
    # ==== Return
    #   Result
    def start
      Result.new(call(CMD_START))
    end

    # Leave a node from the storage cluster
    # ==== Args
    #   node :: a storage node
    # ==== Return
    #   Result
    def detach(node)
      Result.new(call(CMD_DETACH % node))
    end

    # Suspend a node in the storage cluster
    # ==== Args
    #   node :: a storage node
    # ==== Return
    #   Result
    def suspend(node)
      Result.new(call(CMD_SUSPEND % node))
    end

    # Resume a node in the storage cluster
    # ==== Args
    #   node :: a storage node
    # ==== Return
    #   Result
    def resume(node)
      Result.new(call(CMD_RESUME % node))
    end

    # Execute relocate of objects - "rebalance" in the storage cluster
    # ==== Return
    #   Result
    def rebalance
      Result.new(call(CMD_REBALANCE))
    end

    # Retrieve assigned file information
    # ==== Args
    #   path :: an object path
    # ==== Return
    #   Array of AssignedFile
    def whereis(path)
      assigned_info = call(CMD_WHEREIS % path)[:assigned_info]
      assigned_info.map {|h| AssignedFile.new(h)}
    end

    # Retrieve storage status from the storage
    # ==== Args
    #   node :: a storage node
    # ==== Return
    #   StorageStat
    def du(node)
      StorageStat.new(call(CMD_DU % node))
    end

    # Execute data comaction in a storage node
    # ==== Args
    #   node :: a storage node
    #   num_of_targets_or_all :: a number of targets - [integer | all]
    #   num_of_concurrents    :: a number of concurrents
    # ==== Return
    #   Result
    def compact_start(node, num_of_targets_or_all, num_of_concurrents=nil)
      case num_of_targets_or_all.to_s
      when /^all$/i
        Result.new(call(CMD_COMPACT_START_ALL % node))
      else
        num_of_concurrents = num_of_concurrents ? Integer(num_of_concurrents) : ""
        Result.new(call(CMD_COMPACT_START % [node, Integer(num_of_targets_or_all), num_of_concurrents]))
      end
    end

    # Execute 'compact suspend'
    # ==== Args
    #   node :: a storage node
    # ==== Return
    #   Result
    def compact_suspend(node)
      Result.new(call(CMD_COMPACT_SUSPEND % node))
    end

    # Execute 'compact suspend'
    # ==== Args
    #   node :: a storage node
    # ==== Return
    #   Result
    def compact_resume(node)
      Result.new(call(CMD_COMPACT_RESUME % node))
    end

    # Execute 'compact status'
    # ==== Args
    #   node :: a storage node
    # ==== Return
    #   CompactionStatus
    def compact_status(node)
      compaction = call(CMD_COMPACT_STATUS % node)[:compaction_status]
      CompactionStatus.new(compaction)
    end

    # Purge a cache in the gateways
    # ==== Args
    #   path :: an object path
    # ==== Return
    #   Result
    def purge(path)
      Result.new(call(CMD_PURGE % path))
    end

    # Generate credential of a user
    # ==== Args
    #   user_id  :: user id
    #   password :: password
    # ==== Return
    #   Credential
    def create_user(user_id, password=nil)
      Credential.new(call(CMD_CRE_USER % [user_id, password]))
    end

    # Update role of a user
    # ==== Args
    #   user_id :: user id
    #   role    :: operation role of a user
    # ==== Return
    #   Result
    def update_user_role(user_id, role)
      role = role.to_sym if role.is_a? String
      role = USER_ROLES[role] if role.is_a? Symbol
      Result.new(call(CMD_UPD_USER_ROLE % [user_id, role]))
    end

    # Update password of a user
    # ==== Args
    #   user_id      :: user id
    #   new_password :: new password
    # ==== Return
    #   Result
    def update_user_password(user_id, new_password)
      Result.new(call(CMD_UPD_USER_PASS % [user_id, new_password]))
    end

    # Delete a user
    # ==== Args
    #   user_id :: user id
    # ==== Return
    #   Result
    def delete_user(user_id)
      Result.new(call(CMD_DEL_USER % user_id))
    end

    # Retrieve a user
    # ==== Return
    #   Map
    def get_users
      users = call(CMD_GET_USERS)[:users]
      users.map {|account| User.new(account) }
    end

    # Insert an endpoint in the system
    # ==== Args
    #   endpoint :: an endpoint
    # ==== Return
    #   Result
    def set_endpoint(endpoint)
      Result.new(call(CMD_SET_ENDPOINT % endpoint))
    end

    # Remove an endpoint from the system
    # ==== Args
    #   endpoint :: an endpoint
    # ==== Return
    #   nil
    def delete_endpoint(endpoint)
      Result.new(call(CMD_DEL_ENDPOINT % endpoint))
    end
    alias :del_endpoint :delete_endpoint

    # Retrieve an endpoint in the system
    # ==== Return
    #   Array of Endpoint
    def get_endpoints
      endpoints = call(CMD_GET_ENDPOINTS)[:endpoints]
      endpoints.map {|endpoint| Endpoint.new(endpoint) }
    end

    # Add an Bucket in the system
    # ==== Args
    #   bucket_name :: a bucket name
    #   access_key_id :: access key id
    # ==== Return
    #   Result
    def add_bucket(bucket_name, access_key_id)
      Result.new(call(CMD_ADD_BUCKET % [bucket_name, access_key_id]))
    end

    # Delete an Bucket in the system
    # ==== Args
    #   bucket_name :: a bucket name
    #   access_key_id :: access key id
    # ==== Return
    #   Result
    def delete_bucket(bucket_name, access_key_id)
      Result.new(call(CMD_DELETE_BUCKET % [bucket_name, access_key_id]))
    end

    # Retrieve all buckets from the system
    # ==== Return
    #   Array of Bucket
    def get_buckets
      buckets = call(CMD_GET_BUCKETS)[:buckets]
      buckets.map {|bucket| Bucket.new(bucket) }
    end

    # Update acl of a bucket
    # ==== Args
    #   bucket_name   :: a bucket name
    #   access_key_id :: access key id
    #   acl :: acl of a bucket
    # ==== Return
    #   Result
    def update_acl(bucket, accesskey, acl)
      Result.new(call(CMD_UPDATE_ACL % [bucket, accesskey, acl]))
    end

    # Recover file
    # ==== Args
    #   path :: an object path
    # ==== Return
    #   Result
    def recover_file(path)
      Result.new(call(CMD_RECOVER_FILE % path))
    end

    # Recover node
    # ==== Args
    #   node :: a storage node
    # ==== Return
    #   Result
    def recover_node(node)
      Result.new(call(CMD_RECOVER_NODE % node))
    end

    # Recover ring
    # ==== Args
    #   node :: a storage node
    # ==== Return
    #   Result
    def recover_ring(node)
      Result.new(call(CMD_RECOVER_RING % node))
      nil
    end

    # Disconnect to LeoFS Manager explicitly
    # ==== Return
    #   Result
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
    def call(command)
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
        reconnect
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
  m = LeoManager::Client.new("localhost:10020", "localhost:10021")
  p m.version

  p "[status]"
  p m.status

  p "[status storage_0@127.0.0.1]"
  p m.status("storage_0@127.0.0.1")

  p "[status gateway_0@127.0.0.1]"
  p m.status("gateway_0@127.0.0.1")

  p "[add-bucket]"
  p m.add_bucket("photo", "05236")

  p "[get-buckets #1]"
  p m.get_buckets()

  p "[update-acl]"
  p m.update_acl("photo", "05236", "public-read")

  p "[get-buckets #2]"
  p m.get_buckets()

  p "[update-acl]"
  p m.update_acl("photo", "05236", "public-read-write")

  p "[get-buckets #3]"
  p m.get_buckets()

  p "[du storage_0@127.0.0.1]"
  p m.du("storage_0@127.0.0.1")

  p "[compact status storage_0@127.0.0.1]"
  p m.compact_status("storage_0@127.0.0.1")
end
