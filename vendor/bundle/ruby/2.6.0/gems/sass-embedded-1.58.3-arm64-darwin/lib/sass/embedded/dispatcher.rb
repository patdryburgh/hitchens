# frozen_string_literal: true

module Sass
  class Embedded
    # The {Dispatcher} class.
    #
    # It dispatches messages between mutliple instances of {Host} and a single {Compiler}.
    class Dispatcher
      PROTOCOL_ERROR_ID = 0xffffffff

      def initialize
        @compiler = Compiler.new
        @observers = {}
        @id = 0
        @mutex = Mutex.new

        Thread.new do
          loop do
            receive_message
          rescue IOError, Errno::EBADF => e
            @mutex.synchronize do
              @id = PROTOCOL_ERROR_ID
              @observers.values
            end.each do |observer|
              observer.error e
            end
            break
          end
        end
      end

      def subscribe(observer)
        @mutex.synchronize do
          raise EOFError if @id == PROTOCOL_ERROR_ID

          id = @id
          @id = id.next
          @observers[id] = observer
          id
        end
      end

      def unsubscribe(id)
        @mutex.synchronize do
          @observers.delete(id)

          return unless @observers.empty?

          if @id == PROTOCOL_ERROR_ID
            close
          else
            @id = 0
          end
        end
      end

      def close
        @compiler.close
      end

      def closed?
        @compiler.closed?
      end

      def send_message(**kwargs)
        inbound_message = EmbeddedProtocol::InboundMessage.new(**kwargs)
        @compiler.write(inbound_message.to_proto)
      end

      private

      def receive_message
        outbound_message = EmbeddedProtocol::OutboundMessage.decode(@compiler.read)
        oneof = outbound_message.message
        message = outbound_message.public_send(oneof)
        case oneof
        when :error
          @mutex.synchronize do
            @id = PROTOCOL_ERROR_ID
            message.id == PROTOCOL_ERROR_ID ? @observers.values : [@observers[message.id]]
          end.each do |observer|
            observer.public_send(oneof, message)
          end
        when :compile_response, :version_response
          @mutex.synchronize { @observers[message.id] }.public_send(oneof, message)
        when :log_event, :canonicalize_request, :import_request, :file_import_request, :function_call_request
          Thread.new(@mutex.synchronize { @observers[message.compilation_id] }) do |observer|
            observer.public_send(oneof, message)
          end
        else
          raise ArgumentError, "Unknown OutboundMessage.message #{message}"
        end
      end
    end

    private_constant :Dispatcher
  end
end
