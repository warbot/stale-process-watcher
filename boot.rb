class Watcher
  require "workers/watcher/logger"
  require "workers/watcher/process"
  require "workers/watcher/process_pool"
  require "workers/watcher/stat"
  require "workers/watcher/ps"
  require "workers/watcher/farm"
  require "workers/watcher/user_opts"

  require "workers/watcher/stale_job/factor"
  require "workers/watcher/stale_job/factor/type/strace"
  require "workers/watcher/stale_job/factor/type/log_file"
  require "workers/watcher/stale_job/factor/type/proc_sched"
  require "workers/watcher/stale_job/factor/type/proc_status"
  require "workers/watcher/stale_job/factor/type/proc_io"
  require 'workers/watcher/stale_job/factor/type/proc_stack'

  FACTORS = [
    StaleJob::Factor::Type::LogFile,
    StaleJob::Factor::Type::Strace,
    StaleJob::Factor::Type::ProcIO,
    StaleJob::Factor::Type::ProcSched,
    StaleJob::Factor::Type::ProcStatus
  ]

  MODES = [
    KILL = 'kill',
    DO_NOTHING = 'do nothing'
  ]

  PROCESS_CAP = 200
  FACTORS_MAP = {}

  FACTORS.each do |factor|
    name = factor.name.split('::').last
    FACTORS_MAP[name] = factor
  end

  def initialize
    @process_pool = ProcessPool.new
    @process_pool.cap = PROCESS_CAP
    @farm = Farm.new(@process_pool)
  end

  attr_accessor :mode, :pattern, :sleep_time, :sleep_diviation
  attr_writer :factors, :process_cap
  attr_reader :process_count, :process_pool, :farm

  def factors
    @factors || FACTORS
  end

  def process_cap=(size)
    @process_pool.cap = size
  end

  def act_mode(process, score)
    pid = process.pid
    uuid = process.uuid
    stat = process_pool[pid]

    case score
    when 0..49
      Log.info "Process pid: #{pid}, uuid: #{uuid} is healthy."\
        " Score: #{total_weight}."\
        "\nEvidences: #{stat}"
    when 50..99
      Log.warn "Process pid: #{pid}, uuid: #{uuid} can be stuck."\
        "\nScore per factor: #{r.inspect}."\
        "\nScore: #{total_weight}."\
        "\nEvidences: #{stat}"
    else
      Log.warn "Process pid: #{pid}, uuid: #{uuid} is stuck."\
        "\nScore per factor: #{r.inspect}."\
        "\nScore: #{total_weight}."\
        "\nEvidences: #{stat}"
    end

    Log.info "Mode set: #{mode}"

    if mode == KILL
      Log.warn "Killing process: #{process.inspect}" \
        ". Command: `kill -KILL #{pid}'"
      ::Process.kill("KILL", pid)
    else
      Log.warn "Ignoring process: #{process.inspect}"
    end
  end

  def tictac
    processes = Watcher::Process.find_by_pattern(self.pattern)
    @process_count = processes.count
    Log.info "Found #{self.process_count} processes matching: `#{self.pattern}'"\
      "\nPIDs: #{processes.map(&:pid).join(', ')}"

    processes.each do |process|
      farm.harvest(process, factors)
      score = farm.bake(process)
      act(process, score)
    end
  end

  def tictac_pause
    sleep_seconds = sleep_time.to_i + rand(sleep_diviation.to_i)
    Log.info("Sleeping for #{sleep_seconds} seconds...")
    sleep(sleep_seconds)
  end

  def self.boot
    Log.level = Logger::INFO
    Log.info("Starting watcher")

    usr_opts                 = UserOpts.parse(ENV)
    watcher                  = Watcher.new
    watcher.pattern          = usr_opts[:pattern]
    watcher.sleep_time       = usr_opts[:sleep_time]
    watcher.sleep_diviation  = usr_opts[:sleep_diviation]
    watcher.process_cap      = usr_opts[:process_cap]
    watcher.mode             = usr_opts[:mode]
    watcher.factors          = usr_opts[:factors]

    Log.info("Loading factors: #{watcher.factors.inspect}")
    Log.info("Registering processes...")

    loop do
      begin
        watcher.tictac
        watcher.tictac_pause
      rescue => e
        Log.error "Watcher caught unexpected exception: #{e.message}."\
          "Backtrace: #{e.backtrace.join("\n")}"
        if ENV['STOP_ON_ERROR'] == '1'
          raise e
        end
      rescue SignalException => e
        Log.info "Exit with #{e.inspect}"
        raise e
      end
    end
  end
end

# FACTORS=ProcIO:50,Strace:99 MODE=kill SLEEPTIME=30 BOOT=1 STOP_ON_ERROR=0\
#   GREP=provision_worker.rb bundle exec ruby boot.rb
if ENV['BOOT'] == '1'
  Watcher.boot
end
