class Watcher
  class Ps
    ParseError = Class.new(RuntimeError)

    # USER               PID  %CPU %MEM      VSZ    RSS   TT  STAT STARTED      TIME COMMAND
    # root                44   0.0  0.0  4351400    824   ??  Ss    9Oct19   1:02.56 /usr/sbin/syslogd
    HEADERS = %w(USER PID CPU MEM VSZ RSS TT STAT STARTED TIME COMMAND).map(&:downcase)
    COMMAND_SLICE = ((HEADERS.size-1)..-1)
    Obj = Struct.new(*HEADERS.map(&:to_sym))

    def self.parse(cmd_output)
      objs = []
      cmd_arr = cmd_output.split("\n")
      cmd_arr.each do |line|
        objs << parse_one(line)
      end
      objs
    end

    def self.parse_one(cmd_output)
      begin
        cmd_arr = cmd_output.split(" ")
        cmd_arr[COMMAND_SLICE] = cmd_arr[COMMAND_SLICE].join(" ")
        obj = Obj.new
        HEADERS.each { |key| obj[key] = cmd_arr[HEADERS.index(key)] }
        obj
      rescue => e
        Log.error(e.inspect)
        raise ParseError.new(e)
      end
    end
  end
end
