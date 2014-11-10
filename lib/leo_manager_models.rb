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
module LeoManager

  # ==========================
  # Common Result
  # ==========================
  class Result
    attr_reader :result

    def initialize(h)
      error = h[:error]
      if error == nil
        @result = h[:result]
      else
        @result = error
      end
    end
  end


  # ==========================
  # System Information Model
  # ==========================
  class Status
    # System
    attr_reader :system_info
    # Node Status
    attr_reader :node_stat
    # Storage Status
    attr_reader :storage_stat
    # Gateway Status
    attr_reader :gateway_stat
    # Array of Node
    attr_reader :node_list

    def initialize(h)
      @system_info  = System.new(h[:system_info]) if h.has_key?(:system_info)
      @node_stat    = NodeStat.new(h[:node_stat]) if h.has_key?(:node_stat)
      @storage_stat = StorageStat.new(h[:node_stat]) if h.has_key?(:node_stat)
      @gateway_stat = GatewayStat.new(h[:node_stat]) if h.has_key?(:node_stat)
      @node_list = h[:node_list].map {|node| NodeInfo.new(node) } if h.has_key?(:node_list)
    end

    # System Info
    class System
      attr_reader :version, :ring_size, :ring_cur, :ring_prev

      # number of replicas
      attr_reader :n
      # number of replicas needed for a successful READ operation
      attr_reader :r
      # number of replicas needed for a successful WRITE operation
      attr_reader :w
      # number of replicas needed for a successful DELETE operation
      attr_reader :d

      def initialize(h)
        @version = h[:version]
        @n = Integer(h[:n])
        @r = Integer(h[:r])
        @w = Integer(h[:w])
        @d = Integer(h[:d])
        @ring_size = Integer(h[:ring_size])
        # leo_manager returns ring_hash_(cur|prev) as decimal (not hex)
        @ring_cur  = Integer(h[:ring_hash_cur]).to_s(16)
        @ring_prev = Integer(h[:ring_hash_prev]).to_s(16)
      end
    end

    # Node Info
    class NodeInfo
      attr_reader :type, :node, :state, :ring_cur, :ring_prev, :when

      def initialize(h)
        @type  = h[:type]
        @node  = h[:node]
        @when  = Time.parse(h[:when])
        @state = h[:state]
        @ring_cur  = h[:ring_cur]
        @ring_prev = h[:ring_prev]
      end

      alias joined_at when
    end

    # Node Common Status
    class NodeStat
      @@properties = [:version,
                      :log_dir,
                      :ring_cur,
                      :ring_prev,
                      :vm_version,
                      :total_mem_usage,
                      :system_mem_usage,
                      :procs_mem_usage,
                      :ets_mem_usage,
                      :num_of_procs,
                      :limit_of_procs,
                      :thread_pool_size,
                      :kernel_poll,
                      :wd_rex_interval,
                      :wd_rex_threshold_mem_capacity,
                      :wd_cpu_enabled,
                      :wd_cpu_interval,
                      :wd_cpu_threshold_cpu_load_avg,
                      :wd_cpu_threshold_cpu_util,
                      :wd_io_enabled,
                      :wd_io_interval,
                      :wd_io_threshold_input_per_sec,
                      :wd_io_threshold_output_per_sec,
                      :wd_disk_interval,
                      :wd_disk_threshold_disk_use,
                      :wd_disk_threshold_disk_util
                     ]
      attr_reader *@@properties

      def initialize(h)
        @@properties.each do |property|
          instance_variable_set("@#{property}", h[property])
        end
        @kernel_poll = (h[:kernel_poll] == "true") if h.has_key?(:kernel_poll)
      end
    end

    # Storage Status
    class StorageStat
      @@properties = [:replication_msgs,
                      :sync_vnode_msgs,
                      :rebalance_msgs
                     ]
      attr_reader *@@properties

      def initialize(h)
        @@properties.each do |property|
          instance_variable_set("@#{property}", h[property])
        end
      end
    end

    # Gateway Status
    class GatewayStat
      @@properties = [:handler,
                      :port,
                      :ssl_port,
                      :num_of_acceptors,
                      :http_cache,
                      :cache_workers,
                      :cache_expire,
                      :cache_ram_capacity,
                      :cache_disc_capacity,
                      :cache_disc_threshold_len,
                      :cache_disc_dir_data,
                      :cache_disc_dir_journal,
                      :cache_max_content_len,
                      :max_chunked_objs,
                      :max_len_for_obj,
                      :chunked_obj_len,
                      :reading_chunked_obj_len,
                      :threshold_of_chunk_len
                     ]
      attr_reader *@@properties

      def initialize(h)
        @@properties.each do |property|
          instance_variable_set("@#{property}", h[property])
        end
      end
    end
  end

  # ==========================
  # Assigned file info Model
  # ==========================
  class AssignedFile
    attr_reader :node, :vnode_id, :size, :clock, :checksum, :timestamp, :delete, :num_of_chunks

    def initialize(h)
      @node      = h[:node]
      @vnode_id  = h[:vnode_id]
      @size      = h[:size]
      @clock     = h[:clock]
      @checksum  = h[:checksum]
      timestamp = h[:timestamp]
      @timestamp = timestamp.empty? ? timestamp : Time.parse(timestamp)
      @delete    = h[:delete] != 0 # bool
      @num_of_chunks = h[:num_of_chunks]
    end
  end

  # ==========================
  # Storage Status Model
  # ==========================
  class StorageStat
    attr_reader :active_num_of_objects, :total_num_of_objects,
    :active_size_of_objects, :total_size_of_objects,
    :ratio_of_active_size,
    :last_compaction_start, :last_compaction_end

    alias total_of_objects total_num_of_objects # for compatibility

    def initialize(h)
      @active_num_of_objects  = h[:active_num_of_objects]
      @total_num_of_objects   = h[:total_num_of_objects]
      @active_size_of_objects = h[:active_size_of_objects]
      @total_size_of_objects  = h[:total_size_of_objects]
      @ratio_of_active_size   = h[:ratio_of_active_size]

      last_compaction_start = h[:last_compaction_start]
      if last_compaction_start == "____-__-__ __:__:__"
        @last_compaction_start = nil # you have never done compaction
      else
        @last_compaction_start = Time.parse(last_compaction_start)
      end

      last_compaction_end = h[:last_compaction_end]
      if last_compaction_end == "____-__-__ __:__:__"
        @last_compaction_end = nil
      else
        @last_compaction_end = Time.parse(last_compaction_end)
      end
    end

    def file_size
      warn "property 'file_size' is deprecated"
    end
  end

  # ==========================
  # S3 Credential Model
  # ==========================
  class Credential
    # AWS_ACCESS_KEY_ID
    attr_reader :access_key_id
    # AWS_SECRET_ACCESS_KEY
    attr_reader :secret_access_key

    def initialize(h)
      @access_key_id = h[:access_key_id]
      @secret_access_key = h[:secret_access_key]
    end
  end

  # ==========================
  # Login Info Model
  # ==========================
  RoleDef = {
    1 => :general,
    9 => :admin
  }
  RoleDef.default_proc = proc {|_, key| raise "invalid @user_id: #{key}" }
  RoleDef.freeze

  class LoginInfo
    attr_reader :id, :role_id, :access_key_id, :secret_key, :created_at

    def initialize(h)
      h = h[:user]
      @id = h[:id]
      @role_id = h[:role_id]
      @access_key_id = h[:access_key_id]
      @secret_key = h[:secret_key]
      @created_at = Time.parse(h[:created_at])
    end

    def role
      RoleDef[@role_id]
    end
  end

  # ==========================
  # User Info Model
  # ==========================
  class User
    attr_reader :user_id, :role_id, :access_key_id, :created_at

    def initialize(h)
      @user_id = h[:user_id]
      @role_id = h[:role_id]
      @access_key_id = h[:access_key_id]
      @created_at = Time.parse(h[:created_at])
    end

    def role
      RoleDef[@role_id]
    end
  end

  # ==========================
  # Endpoint Model
  # ==========================
  class Endpoint
    # host of the endpoint
    attr_reader :endpoint
    # When the endpoint created at
    attr_reader :created_at

    def initialize(h)
      @endpoint = h[:endpoint]
      @created_at = Time.parse(h[:created_at])
    end
  end

  # ==========================
  # S3-Bucket Model
  # ==========================
  class Bucket
    # name of bucket
    attr_reader :name
    # name of the bucket's owner
    attr_reader :owner
    # permissions
    attr_reader :permissions
    # when the bucket created at
    attr_reader :created_at

    def initialize(h)
      @name        = h[:bucket]
      @owner       = h[:owner]
      @permissions = h[:permissions]
      @created_at  = Time.parse(h[:created_at])
    end
  end

  # ==========================
  # Compaction Status Model
  # ==========================
  class CompactionStatus
    attr_reader :status, :last_compaction_start,
    :total_targets, :num_of_pending_targets,
    :num_of_ongoing_targets, :num_of_out_of_targets

    def initialize(h)
      @status                 = h[:status]
      @total_targets          = h[:total_targets]
      @num_of_pending_targets = h[:num_of_pending_targets]
      @num_of_ongoing_targets = h[:num_of_ongoing_targets]
      @num_of_out_of_targets  = h[:num_of_out_of_targets]

      last_compaction_start = h[:last_compaction_start]
      if last_compaction_start == "____-__-__ __:__:__"
        @last_compaction_start = nil # you have never done compaction
      else
        @last_compaction_start = Time.parse(last_compaction_start)
      end
    end
  end
end
