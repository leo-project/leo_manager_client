  ## ======================================================================
  ## CLASS
  ## ======================================================================
  ## @doc System Information Model
  ##
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
