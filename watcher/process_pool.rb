class Watcher
  class ProcessPool < Hash
    def initialize(*args)
      @_mem = []
      super
    end

    def cap=(size)
      @cap = size
    end

    def []=(key, value)
      unless has_key?(key)
        @_mem << key
      end

      if @_mem.size > @cap
        self.delete(@_mem[0])
        @_mem = @_mem.drop(1)
      end

      super
    end
  end
end
