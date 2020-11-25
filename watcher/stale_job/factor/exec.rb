begin
  require "posix/spawn"
rescue LoadError
  Watcher::Log.error "Could not load `posix/spawn'"
end

class Watcher
  class StaleJob
    module Factor
      module Exec
        def self.included(base)
          base.class.send(:attr_accessor, :cmd, :timeout)
        end

        ExecError = Class.new(StandardError)
        TIMEOUT = 3

        attr_writer :timeout, :pid
        attr_reader :cmd, :cmd_str

        def timeout
          @timeout || self.class.timeout || TIMEOUT
        end

        def exec(process)
          pid = process.pid
          @cmd_str = format_cmd(process)
          @cmd = POSIX::Spawn::Child.build(cmd_str, :timeout => timeout)

          begin
            @cmd.exec!
          rescue POSIX::Spawn::TimeoutExceeded => e
            Log.error("Timeout during execution pid: #{pid} of cmd: #{cmd_str}. #{e.message}")
            return (@cmd.out << @cmd.err)
          rescue => e
            Log.error("Error during execution pid: #{pid} of cmd: #{cmd_str}. #{e.message}")
            # raise ExecError.new(e)
          end

          @cmd.out
        end

        private

        def format_cmd(process)
          self.class.cmd
        end
      end
    end
  end
end
