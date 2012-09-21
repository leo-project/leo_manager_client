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

module LeoFSManager
  VERSION = "0.2.0"

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
  ## CLASS
  ## ======================================================================
  ## @doc System Information Model
  ##
  class SystemInfo
    attr_reader :version, :n, :r, :w, :d, :ring_size, :ring_cur, :ring_prev

    def initialize(h)
      @version = h[:version]
      @n = h[:n]
      @r = h[:r]
      @w = h[:w]
      @d = h[:d]
      @ring_size = h[:ring_size]
      @ring_cur  = h[:ring_cur]
      @ring_prev = h[:ring_prev]
    end
  end

  ## @doc Node Info Model
  ##
  class NodeInfo
    attr_reader :type, :node, :state, :ring_cur, :ring_prev, :joined_at

    def initialize(h)
      @type      = h[:type]
      @node      = h[:node]
      @state     = h[:state]
      @ring_cur  = h[:ring_cur]
      @ring_prev = h[:ring_prev]
      @joined_at = h[:when]
    end
  end

  ## @doc Node Status Model
  ##
  class NodeStat
    attr_reader :version, :log_dir, :ring_cur, :ring_prev, :tota_mem_usage, :system_mem_usage, 
                :procs_mem_usage, :ets_mem_usage, :num_of_procs

    def initialize(h)
      @type      = h[:version]
      @log_dir   = h[:log_dir]
      @ring_cur  = h[:ring_cur]
      @ring_prev = h[:ring_prev]
      @total_mem_usage  = h[:total_mem_usage]
      @system_mem_usage = h[:system_mem_usage]
      @procs_mem_usage  = h[:procs_mem_usage]
      @ets_mem_usage    = h[:ets_mem_usage]
      @num_of_procs     = h[:num_of_procs]
    end
  end

  ## @doc
  ##
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
      command = CMD_STATUS % node
      command.rstrip!
      h1 = sender(command)
  
      raise h1[:error] if h1.has_key?(:error)
      if h1.has_key?(:system_info)
        system_info = SystemInfo.new(h1[:system_info])
        node_list = h1[:node_list].map {|h2| NodeInfo.new(h2) }
        return {:system_info => system_info, :node_list => node_list}
      elsif h1.has_key?(:node_stat)
        node_stat = NodeStat.new(h1[:node_stat])
        return node_stat
      end
    end
  
    ## @doc Launch LeoFS's storage cluster
    ## @return null
    def start
      h = sender(CMD_START)
      raise h[:error] if h.has_key?(:error)
      nil
    end
  
    def detach(node)
      h = sender(CMD_DETACH % node)
      raise h[:error] if h.has_key?(:error)
      h[:result]
    end
  
    def resume(node)
      h = sender(CMD_RESUME % node)
      raise h[:error] if h.has_key?(:error)
      h[:result]
    end
  
    def rebalance
      h = sender(CMD_REBALANCE % node)
      raise h[:error] if h.has_key?(:error)
      h[:result]
    end
  
    def whereis(path)
      h = sender(CMD_WHEREIS % path)
      raise h[:error] if h.has_key?(:error)
      h[:result]
    end
  
    def du(node)
      h = sender(CMD_DU % node)
      raise h[:error] if h.has_key?(:error)
      h[:result]
    end
  
    def compact(node)
      h = sender(CMD_COMPACT % node)
      raise h[:error] if h.has_key?(:error)
      h[:result]
    end
  
    def purge(path)
      h = sender(CMD_PURGE % path)
      raise h[:error] if h.has_key?(:error)
      h[:result]
    end
  
    def s3_gen_key(user_id)
      h = sender(CMD_S3_GEN_KEY % user_id)
      raise h[:error] if h.has_key?(:error)
      h[:result]
    end
  
    def s3_set_endpoint(endpoint)
      h = sender(CMD_S3_SET_ENDPOINT % endpoint)
      raise h[:error] if h.has_key?(:error)
      h[:result]
    end
  
    def s3_del_endpoint(endpoint)
      h = sender(CMD_S3_DEL_ENDPOINT % endpoint)
      raise h[:error] if h.has_key?(:error)
      h[:result]
    end
  
    def s3_get_endpoints(endpoint)
      h = sender(CMD_S3_GET_ENDPOINTS % endpoint)
      raise h[:error] if h.has_key?(:error)
      h[:result]
    end
  
    def s3_add_endpoint(bucket, access_key_id)
      h = sender(CMD_S3_ADD_ENDPOINT % [endpoint, access_key_id])
      raise h[:error] if h.has_key?(:error)
      h[:result]
    end
  
    def s3_get_buckets
      h = sender(CMD_S3_GET_BUCKETS)
      raise h[:error] if h.has_key?(:error)
      h[:result]
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
end

## ======================================================================
##
## ======================================================================
if __FILE__ == $PROGRAM_NAME
  require "pp"

  $DEBUG = true
  m = LeoFSManager.new("localhost:10020", "localhost:10021")
  p m.version
  p m.status
  p m.status("storage_0@127.0.0.1")
end
