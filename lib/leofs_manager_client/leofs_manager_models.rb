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
module LeoFSManager

  ## ======================================================================
  ## CLASS
  ## ======================================================================
  ## @doc System Information Model
  ##
  class Status
    attr_reader :node_stat, :system_info, :node_list

    def initialize(h)
      @node_stat = Node.new(h[:node_stat]) if h.has_key?(:node_stat)
      @system_info = System.new(h[:system_info]) if h.has_key?(:system_info)
      @node_list = h[:node_list].map {|node| Node.new(node) } if h.has_key?(:node_list)
    end

    class System
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

    ## @doc Node Status Model
    ##
    class Node
      attr_reader :version, :type, :node, :state, :log_dir, :ring_cur, :ring_prev, :joined_at,
                  :tota_mem_usage, :system_mem_usage,  :procs_mem_usage, :ets_mem_usage, :num_of_procs

      def initialize(h)
        @version   = h[:version]
        @type      = h[:type]
        @node      = h[:node]
        @state     = h[:state]
        @log_dir   = h[:log_dir]
        @ring_cur  = h[:ring_cur]
        @ring_prev = h[:ring_prev]
        @joined_at = h[:when]
        @total_mem_usage  = h[:total_mem_usage]
        @system_mem_usage = h[:system_mem_usage]
        @procs_mem_usage  = h[:procs_mem_usage]
        @ets_mem_usage    = h[:ets_mem_usage]
        @num_of_procs     = h[:num_of_procs]
      end
    end
  end


  ## @doc Assigned file info Model
  ##
  class AssignedFile
    attr_reader :node, :vnode_id, :size, :clock, :checksum, :timestamp, :delete

    def initialize(h)
      @node      = h[:node]
      @vnode_id  = h[:vnode_id]
      @size      = h[:size]
      @clock     = h[:clock]
      @checksum  = h[:checksum]
      @timestamp = h[:timestamp]
      @delete    = h[:delete]
    end
  end

  ## @doc Storage Status Model
  ##
  class StorageStat
    attr_reader :file_size, :total_of_objects

    def initialize(h)
      @file_size = h[:file_size]
      @total_of_objects = h[:total_of_objects]
    end
  end


  ## @doc Credential Model
  ##
  class Credential
    attr_reader :access_key_id, :secret_access_key

    def initialize(h)
      @access_key_id = h[:access_key_id]
      @secret_access_key = h[:secret_access_key]
    end
  end


  ## @doc Endpoint
  ##
  class Endpoint
    attr_reader :endpoint, :created_at

    def initialize(h)
      @endpoint = h[:endpoint]
      @created_at = h[:created_at]
    end
  end


  ## @doc S3-Bucket Model
  ##
  class Bucket
    attr_reader :name, :owner, :created_at

    def initialize(h)
      @name       = h[:bucket]
      @owner      = h[:owner]
      @created_at = h[:created_at]
    end
  end
end