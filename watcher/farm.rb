class Watcher
  class Farm
    FACTOR_MIN_SIZE = Watcher::Stat::RETENTION_SIZE

    def initialize(process_pool)
      @process_pool = process_pool
    end

    def harvest(process, factors)
      stat = @process_pool[process.pid] || Watcher::Stat.new(process, :factors => factors)
      @process_pool[process.pid] = stat

      factors.each do |f|
        stat[f] = f.new.exec(process)
      end

      stat
    end

    def bake(process)
      stat = @process_pool[process.pid]
      r = {}
      total_weight = 0
      pid = process.pid
      uuid = process.uuid

      stat.each do |f, results|
        if results.size >= FACTOR_MIN_SIZE && results.uniq.size == 1
          r[f] = f.weight
          total_weight += r[f]
        elsif results.size < FACTOR_MIN_SIZE
          Log.debug "Not enough data to evaluate. "\
            "Size: #{results.size}. Need: #{FACTOR_MIN_SIZE}"
        end
      end

      total_weight
    end
  end
end
