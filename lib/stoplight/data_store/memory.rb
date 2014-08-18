# coding: utf-8

module Stoplight
  module DataStore
    class Memory < Base
      def initialize
        @data = {}
      end

      def names
        all_thresholds.keys
      end

      def purge
        names
          .select { |l| failures(l).empty? }
          .each   { |l| delete(l) }
      end

      def delete(name)
        clear_attempts(name)
        clear_failures(name)
        all_states.delete(name)
        all_thresholds.delete(name)
      end

      def color(name)
        case state(name)
        when STATE_LOCKED_GREEN
          COLOR_GREEN
        when STATE_LOCKED_RED
          COLOR_RED
        when STATE_UNLOCKED
          failures = self.failures(name)
          return COLOR_GREEN if failures.size < Stoplight.threshold(name)
          return COLOR_RED if failures.empty?

          if Time.now - failures.last.time > Stoplight.timeout(name)
            COLOR_YELLOW
          else
            COLOR_RED
          end
        else
          fail ArgumentError
        end
      end

      # @group Attempts

      def attempts(name)
        all_attempts[name] || 0
      end

      def record_attempt(name)
        all_attempts[name] ||= 0
        all_attempts[name] += 1
      end

      def clear_attempts(name)
        all_attempts.delete(name)
      end

      # @group Failures

      def failures(name)
        @data[failures_key(name)] || []
      end

      def record_failure(name, error)
        (@data[failures_key(name)] ||= []).push(Failure.new(error))
      end

      def clear_failures(name)
        @data.delete(failures_key(name))
      end

      # @group State

      def state(name)
        all_states[name] || STATE_UNLOCKED
      end

      def set_state(name, state)
        validate_state!(state)
        all_states[name] = state
      end

      # @group Threshold

      def threshold(name)
        all_thresholds[name]
      end

      def set_threshold(name, threshold)
        all_thresholds[name] = threshold
      end

      # @group Timeout

      def timeout(name)
        all_timeouts[name]
      end

      def set_timeout(name, timeout)
        all_timeouts[name] = timeout
      end

      private

      def all_attempts
        @data[attempts_key] ||= {}
      end

      def all_states
        @data[states_key] ||= {}
      end

      def all_thresholds
        @data[thresholds_key] ||= {}
      end

      def all_timeouts
        @data[timeouts_key] ||= {}
      end
    end
  end
end
