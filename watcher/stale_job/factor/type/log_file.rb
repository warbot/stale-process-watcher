class Watcher
  class StaleJob
    module Factor
      module Type
        class LogFile
          extend Weight
          include Exec

          self.weight = 50
          self.cmd = 'stat `readlink /proc/%pid/fd/1`'

          def format_cmd(process)
            pid = process.pid.to_s
            self.class.cmd.sub('%pid', pid)
          end
        end
      end
    end
  end
end
