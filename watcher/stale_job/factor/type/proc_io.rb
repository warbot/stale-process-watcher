class Watcher
  class StaleJob
    module Factor
      module Type
        class ProcIO
          extend Weight
          include Exec

          self.weight = 50
          self.cmd = 'cat /proc/%pid/io'

          def format_cmd(process)
            pid = process.pid.to_s
            self.class.cmd.sub('%pid', pid)
          end
        end
      end
    end
  end
end
