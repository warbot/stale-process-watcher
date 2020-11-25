class Watcher
  class Process
    attr_accessor :uuid, :data

    def self.find_by_uuid(uuid)
      output = exec_cmd("ps aux | grep #{uuid}")

      obj = Ps.parse(output)[0]
      instance = new
      instance.data = obj
      instance.uuid = uuid
      instance
    end

    # ProcTable.ps.select { |a| a.cmdline =~ /ruby\s.*\/provisioning_worker.rb\s\d+\s#{uuid}$/ }
    def self.find_by_pattern(str)
      r = []
      output = exec_cmd("ps aux | grep '#{str}'")
      objs = Ps.parse(output)

      objs.each do |obj|
        uuid = worker_uuid(obj.command)
        next unless uuid
        instance = new
        instance.data = obj
        instance.uuid = uuid
        r << instance
      end

      r
    end

    def pid
      self.data.pid
    end

    private

    class << self
      def exec_cmd(cmd)
        `#{cmd}`
      end

      def uuid_matcher
        '[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}'
      end

      def worker_uuid(cmdline)
        matched = cmdline.match(/ruby\s.*\/provisioning_worker.rb\s\d+\s(#{uuid_matcher})/)
        return nil unless matched
        matched[1]
      end
    end
  end
end
