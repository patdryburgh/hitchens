# frozen_string_literal: true

module Sass
  class Embedded
    class Host
      # The {FunctionRegistry} class.
      #
      # It stores sass custom functions and handles function calls.
      class FunctionRegistry
        attr_reader :global_functions

        def initialize(functions, alert_color:)
          functions = functions.transform_keys(&:to_s)

          @global_functions = functions.keys
          @functions_by_name = functions.transform_keys do |signature|
            index = signature.index('(')
            if index
              signature.slice(0, index)
            else
              signature
            end
          end

          @id = 0
          @functions_by_id = {}
          @ids_by_function = {}

          @highlight = alert_color
        end

        def register(function)
          return if @ids_by_function.key?(function)

          id = @id
          @id = id.next

          @ids_by_function[function] = id
          @functions_by_id[id] = function

          id
        end

        def function_call(function_call_request)
          arguments = function_call_request.arguments.map do |argument|
            value_protofier.from_proto(argument)
          end

          success = value_protofier.to_proto(get(function_call_request).call(arguments))
          accessed_argument_lists = arguments
                                    .select do |argument|
                                      argument.is_a?(Sass::Value::ArgumentList) && argument.instance_eval do
                                        @keywords_accessed
                                      end
                                    end
                                    .map { |argument| argument.instance_eval { @id } }

          EmbeddedProtocol::InboundMessage::FunctionCallResponse.new(
            id: function_call_request.id,
            success: success,
            accessed_argument_lists: accessed_argument_lists
          )
        rescue StandardError => e
          EmbeddedProtocol::InboundMessage::FunctionCallResponse.new(
            id: function_call_request.id,
            error: e.full_message(highlight: @highlight, order: :top)
          )
        end

        private

        def get(function_call_request)
          case function_call_request.identifier
          when :name
            @functions_by_name[function_call_request.name]
          when :function_id
            @functions_by_id[function_call_request.function_id]
          end
        end

        def value_protofier
          @value_protofier ||= ValueProtofier.new(self)
        end
      end

      private_constant :FunctionRegistry
    end
  end
end
