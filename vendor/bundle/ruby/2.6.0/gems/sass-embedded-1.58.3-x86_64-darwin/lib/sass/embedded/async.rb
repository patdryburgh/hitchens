# frozen_string_literal: true

module Sass
  class Embedded
    # The {Async} class.
    #
    # It awaits until the promise is resolved or rejected.
    class Async
      module State
        PENDING = 0
        FULFILLED = 1
        REJECTED = 2
      end

      private_constant :State

      def initialize
        @result = nil
        @state = State::PENDING

        @condition_variable = ConditionVariable.new
        @mutex = Mutex.new
      end

      def resolve(value)
        @mutex.synchronize do
          return unless @state == State::PENDING

          @result = value
          @state = State::FULFILLED
          @condition_variable.broadcast
        end
      end

      def reject(reason)
        @mutex.synchronize do
          return unless @state == State::PENDING

          @result = reason
          @state = State::REJECTED
          @condition_variable.broadcast
        end
      end

      def await
        @mutex.synchronize do
          @condition_variable.wait(@mutex) if @state == State::PENDING

          raise @result if @state == State::REJECTED

          @result
        end
      end
    end

    private_constant :Async
  end
end
