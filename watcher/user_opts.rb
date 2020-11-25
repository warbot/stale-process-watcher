class Watcher
  class UserOpts
    def self.parse(opts)
      {
        :pattern          => opts.fetch('GREP', 'provisioning_worker.rb'),
        :sleep_time       => opts.fetch('SLEEPTIME', 50),
        :sleep_diviation  => opts.fetch('SLEEPDIVTIME', 10),
        :process_cap      => opts.fetch('PROCCAP', 200),
        :mode             => opts.fetch('MODE', Watcher::DO_NOTHING),
        :factors          => Factor.parse(opts['FACTORS'], Watcher::FACTORS)
      }
    end

    class Factor
      def self.parse(user_factors, default_factors)
        user_factors ||= ''
        user_factors = user_factors.split(',')
        found_factors = []

        user_factors.each do |user_factor|
          name, weight = user_factor.split(':')
          factor = Watcher::FACTORS_MAP[name]

          if weight
            factor.weight = weight.to_i
          end

          if factor
            found_factors << factor
          end
        end

        found_factors.empty? ? default_factors : found_factors
      end
    end
  end
end
