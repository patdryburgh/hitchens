# frozen_string_literal: true

module Sass
  class Embedded
    # The {Channel} class.
    #
    # It establishes connection between {Host} and {Dispatcher}.
    class Channel
      def initialize
        @dispatcher = Dispatcher.new
        @mutex = Mutex.new
      end

      def close
        @mutex.synchronize do
          @dispatcher.close
        end
      end

      def closed?
        @mutex.synchronize do
          @dispatcher.closed?
        end
      end

      def connect(observer)
        @mutex.synchronize do
          begin
            id = @dispatcher.subscribe(observer)
          rescue EOFError
            @dispatcher = Dispatcher.new
            id = @dispatcher.subscribe(observer)
          end
          Connection.new(@dispatcher, id)
        end
      end

      # The {Connection} between {Host} to {Dispatcher}.
      class Connection
        attr_reader :id

        def initialize(dispatcher, id)
          @dispatcher = dispatcher
          @id = id
        end

        def disconnect
          @dispatcher.unsubscribe(id)
        end

        def send_message(**kwargs)
          @dispatcher.send_message(**kwargs)
        end
      end

      private_constant :Connection
    end

    private_constant :Channel
  end
end
