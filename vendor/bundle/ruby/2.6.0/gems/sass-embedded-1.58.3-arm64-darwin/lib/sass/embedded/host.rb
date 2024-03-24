# frozen_string_literal: true

require_relative 'host/function_registry'
require_relative 'host/importer_registry'
require_relative 'host/logger_registry'
require_relative 'host/value_protofier'

module Sass
  class Embedded
    # The {Host} class.
    #
    # It communicates with {Dispatcher} and handles the host logic.
    class Host
      def initialize(channel)
        @channel = channel
      end

      def compile_request(path:,
                          source:,
                          importer:,
                          load_paths:,
                          syntax:,
                          url:,
                          charset:,
                          source_map:,
                          source_map_include_sources:,
                          style:,
                          functions:,
                          importers:,
                          alert_ascii:,
                          alert_color:,
                          logger:,
                          quiet_deps:,
                          verbose:)
        compile_response = await do
          alert_color = $stderr.tty? if alert_color.nil?

          @function_registry = FunctionRegistry.new(functions, alert_color: alert_color)
          @importer_registry = ImporterRegistry.new(importers, load_paths, alert_color: alert_color)
          @logger_registry = LoggerRegistry.new(logger)

          send_message(compile_request: EmbeddedProtocol::InboundMessage::CompileRequest.new(
            id: id,
            string: unless source.nil?
                      EmbeddedProtocol::InboundMessage::CompileRequest::StringInput.new(
                        source: source,
                        url: url&.to_s,
                        syntax: Protofier.to_proto_syntax(syntax),
                        importer: (@importer_registry.register(importer) unless importer.nil?)
                      )
                    end,
            path: (File.absolute_path(path) unless path.nil?),
            style: Protofier.to_proto_output_style(style),
            charset: charset,
            source_map: source_map,
            source_map_include_sources: source_map_include_sources,
            importers: @importer_registry.importers,
            global_functions: @function_registry.global_functions,
            alert_ascii: alert_ascii,
            alert_color: alert_color,
            quiet_deps: quiet_deps,
            verbose: verbose
          ))
        end

        Protofier.from_proto_compile_response(compile_response)
      end

      def version_request
        version_response = await do
          send_message(version_request: EmbeddedProtocol::InboundMessage::VersionRequest.new(
            id: id
          ))
        end

        "sass-embedded\t#{version_response.implementation_version}"
      end

      def log_event(message)
        @logger_registry.log(message)
      end

      def compile_response(message)
        resolve(message)
      end

      def version_response(message)
        resolve(message)
      end

      def canonicalize_request(message)
        send_message(canonicalize_response: @importer_registry.canonicalize(message))
      end

      def import_request(message)
        send_message(import_response: @importer_registry.import(message))
      end

      def file_import_request(message)
        send_message(file_import_response: @importer_registry.file_import(message))
      end

      def function_call_request(message)
        send_message(function_call_response: @function_registry.function_call(message))
      end

      def error(message)
        reject(CompileError.new(message.message, nil, nil, nil))
      end

      private

      def await
        @connection = @channel.connect(self)
        @async = Async.new
        yield
        @async.await
      ensure
        @connection&.disconnect
      end

      def resolve(value)
        @async.resolve(value)
      end

      def reject(reason)
        @async.reject(reason)
      end

      def id
        @connection.id
      end

      def send_message(**kwargs)
        @connection.send_message(**kwargs)
      end
    end

    private_constant :Host
  end
end
