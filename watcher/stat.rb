class Watcher
  class Stat
    RETENTION_SIZE = 3

    def initialize(process, opts = {})
      @process = process
      @factors = opts.fetch(:factors)
      @data = {}
      @factors.each { |f| @data[f] = [] }
    end

    def [](key)
      @data[key]
    end

    def []=(key, value)
      if @data[key].size >= RETENTION_SIZE
        @data[key] = @data[key].drop(1)
      end
      @data[key] << [Time.now, value]
    end

    def without_timestamp(key)
      @data[key].map do |element|
        element[1]
      end
    end

    def each
      @factors.each do |factor|
        yield(factor, without_timestamp(factor))
      end
    end

    def to_s
      r = []
      r << '----------------------------------------------------------------'
      r << @process.inspect
      @factors.each do |factor|
        r << "\t#{factor}"
        @data[factor].each do |output|
          r << " * #{output[0]}\n#{output[1]}"
        end
      end
      r << '----------------------------------------------------------------'
      r.join("\n")
    end
  end
end
