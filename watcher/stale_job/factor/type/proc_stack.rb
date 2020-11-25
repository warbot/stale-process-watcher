class Watcher
  class StaleJob
    module Factor
      module Type
        class ProcStack
          extend Weight
          include Exec

          self.weight = 1
          self.cmd = 'tail -n 10 /proc/%pid/syscall'

          def format_cmd(process)
            pid = process.pid.to_s
            self.class.cmd.sub('%pid', pid)
          end
        end
      end
    end
  end
end
