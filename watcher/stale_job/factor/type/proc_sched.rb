class Watcher
  class StaleJob
    module Factor
      module Type
        class ProcSched
          extend Weight
          include Exec

          self.weight = 100
          self.cmd = 'cat /proc/%pid/sched'

          def format_cmd(process)
            pid = process.pid.to_s
            self.class.cmd.sub('%pid', pid)
          end
        end
      end
    end
  end
end
