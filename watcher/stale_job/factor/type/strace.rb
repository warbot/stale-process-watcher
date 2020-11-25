class Watcher
  class StaleJob
    module Factor
      module Type
        class Strace
          extend Weight
          include Exec

          self.weight = 100
          self.timeout = 0.5
          self.cmd = 'strace -p %pid | tail -n 3'

          def format_cmd(process)
            pid = process.pid.to_s
            self.class.cmd.sub('%pid', pid)
          end
        end
      end
    end
  end
end
