# frozen_string_literal: true

module Sass
  class Embedded
    # The {Protofier} module.
    #
    # It converts Pure Ruby types and Protobuf Ruby types.
    module Protofier
      module_function

      def from_proto_compile_response(compile_response)
        oneof = compile_response.result
        result = compile_response.public_send(oneof)
        case oneof
        when :failure
          raise CompileError.new(
            result.message,
            result.formatted,
            result.stack_trace,
            from_proto_source_span(result.span)
          )
        when :success
          CompileResult.new(
            result.css,
            result.source_map,
            result.loaded_urls
          )
        else
          raise ArgumentError, "Unknown CompileResponse.result #{result}"
        end
      end

      def from_proto_source_span(source_span)
        return if source_span.nil?

        Logger::SourceSpan.new(from_proto_source_location(source_span.start),
                               from_proto_source_location(source_span.end),
                               source_span.text,
                               source_span.url,
                               source_span.context)
      end

      def from_proto_source_location(source_location)
        return if source_location.nil?

        Logger::SourceLocation.new(source_location.offset,
                                   source_location.line,
                                   source_location.column)
      end

      def to_proto_syntax(syntax)
        case syntax&.to_sym
        when :scss
          EmbeddedProtocol::Syntax::SCSS
        when :indented
          EmbeddedProtocol::Syntax::INDENTED
        when :css
          EmbeddedProtocol::Syntax::CSS
        else
          raise ArgumentError, 'syntax must be one of :scss, :indented, :css'
        end
      end

      def to_proto_output_style(style)
        case style&.to_sym
        when :expanded
          EmbeddedProtocol::OutputStyle::EXPANDED
        when :compressed
          EmbeddedProtocol::OutputStyle::COMPRESSED
        else
          raise ArgumentError, 'style must be one of :expanded, :compressed'
        end
      end
    end

    private_constant :Protofier
  end
end
