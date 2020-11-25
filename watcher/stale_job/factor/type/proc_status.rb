class Watcher
  class StaleJob
    module Factor
      module Type
        class ProcStatus
          extend Weight
          include Exec

          self.weight = 90
          self.cmd = 'cat /proc/%pid/status'

          def format_cmd(process)
            pid = process.pid.to_s
            self.class.cmd.sub('%pid', pid)
          end
        end
      end
    end
  end
end
