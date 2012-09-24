module LeoFSManager
  ## ======================================================================
  ## CLASS
  ## ======================================================================
  ## @doc System Information Model
  ##
  class Status
    class SystemInfo
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

      attr_reader :version, :n, :r, :w, :d, :ring_size, :ring_cur, :ring_prev
    end

    ## @doc Node Info Model
    ##
    class NodeInfo
      def initialize(h)
        @type      = h[:type]
        @node      = h[:node]
        @state     = h[:state]
        @ring_cur  = h[:ring_cur]
        @ring_prev = h[:ring_prev]
        @joined_at = h[:when]
      end

      attr_reader :type, :node, :state, :ring_cur, :ring_prev, :joined_at
    end

    ## @doc Node Status Model
    ##
    class NodeStat
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

      attr_reader :version, :log_dir, :ring_cur, :ring_prev, :tota_mem_usage,
                  :system_mem_usage,  :procs_mem_usage, :ets_mem_usage, :num_of_procs
    end

    def initialize(h)
      @node_stat = NodeStat.new(h[:node_stat]) if h.has_key?(:node_stat)
      @system_info = SystemInfo.new(h[:system_info]) if h.has_key?(:system_info)
      @node_list = h[:node_list].map {|node| NodeInfo.new(node) } if h.has_key?(:node_list)
    end

    attr_reader :node_stat, :system_info, :node_list
  end

  class WhereInfo
    def initialize(h)
      @node = h[:node]
      @vnode_id = h[:vnode_id]
      @size = h[:size]
      @clock = h[:clock]
      @checksum = h[:checksum]
      @timestamp = h[:timestamp]
      @delete = h[:delete]
    end
 
    attr_reader :node, :vnode_id, :size, :clock, :checksum, :timestamp, :delete 
  end

  class DiskUsage
    def initialize(h)
      @file_size = h[:file_size]
      @total_of_objects = h[:total_of_objects] 
    end

    attr_reader :file_size, :total_of_objects
  end

  class Credential
    def initialize(h)
      @access_key_id = h[:access_key_id] 
      @secret_access_key = h[:secret_access_key]
    end

    attr_reader :access_key_id, :secret_access_key
  end

  class Endpoint
    def initialize(h)
      @endpoint = h[:endpoint]
      @created_at = h[:created_at]
    end

    attr_reader :endpoint, :created_at
  end

  class Bucket
    def initialize(h)
      p h
      @name = h[:bucket]
      @owner = h[:owner]
      @created_at = Time.parse(h[:created_at])
    end
  end
end
