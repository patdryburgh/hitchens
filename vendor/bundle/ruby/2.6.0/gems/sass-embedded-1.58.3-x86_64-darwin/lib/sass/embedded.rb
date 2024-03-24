# frozen_string_literal: true

require_relative '../../ext/sass/embedded'
require_relative '../../ext/sass/embedded_sass_pb'
require_relative 'compile_error'
require_relative 'compile_result'
require_relative 'embedded/async'
require_relative 'embedded/channel'
require_relative 'embedded/compiler'
require_relative 'embedded/dispatcher'
require_relative 'embedded/host'
require_relative 'embedded/protofier'
require_relative 'embedded/structifier'
require_relative 'embedded/varint'
require_relative 'embedded/version'
require_relative 'logger/silent'
require_relative 'logger/source_location'
require_relative 'logger/source_span'
require_relative 'value'

# The Sass module.
#
# This communicates with Embedded Dart Sass using the Embedded Sass protocol.
#
# @example
#   Sass.compile('style.scss')
#
# @example
#   Sass.compile_string('h1 { font-size: 40px; }')
module Sass
  @instance = nil
  @mutex = Mutex.new

  # rubocop:disable Layout/LineLength
  class << self
    # Compiles the Sass file at +path+ to CSS.
    # @overload compile(path, load_paths: [], charset: true, source_map: false, source_map_include_sources: false, style: :expanded, functions: {}, importers: [], alert_ascii: false, alert_color: nil, logger: nil, quiet_deps: false, verbose: false)
    # @param (see Embedded#compile)
    # @return (see Embedded#compile)
    # @raise (see Embedded#compile)
    # @see Embedded#compile
    def compile(path, **kwargs)
      instance.compile(path, **kwargs)
    end

    # Compiles a stylesheet whose contents is +source+ to CSS.
    # @overload compile_string(source, importer: nil, load_paths: [], syntax: :scss, url: nil, charset: true, source_map: false, source_map_include_sources: false, style: :expanded, functions: {}, importers: [], alert_ascii: false, alert_color: nil, logger: nil, quiet_deps: false, verbose: false)
    # @param (see Embedded#compile_string)
    # @return (see Embedded#compile_string)
    # @raise (see Embedded#compile_string)
    # @see Embedded#compile_string
    def compile_string(source, **kwargs)
      instance.compile_string(source, **kwargs)
    end

    # @param (see Embedded#info)
    # @return (see Embedded#info)
    # @raise (see Embedded#info)
    # @see Embedded#info
    def info
      instance.info
    end

    private

    def instance
      return @instance if @instance

      @mutex.synchronize do
        return @instance if @instance

        @instance = Embedded.new
        at_exit do
          @instance.close
        end
      end

      @instance
    end
  end
  # rubocop:enable Layout/LineLength

  # The {Embedded} host for using dart-sass-embedded. Each instance creates
  # its own communication {Channel} with a dedicated compiler process.
  #
  # @example
  #   embedded = Sass::Embedded.new
  #   result = embedded.compile_string('h1 { font-size: 40px; }')
  #   result = embedded.compile('style.scss')
  #   embedded.close
  class Embedded
    def initialize
      @channel = Channel.new
    end

    # Compiles the Sass file at +path+ to CSS.
    # @param path [String]
    # @param load_paths [Array<String>] Paths in which to look for stylesheets loaded by rules like
    #   {@use}[https://sass-lang.com/documentation/at-rules/use] and {@import}[https://sass-lang.com/documentation/at-rules/import].
    # @param charset [Boolean] By default, if the CSS document contains non-ASCII characters, Sass adds a +@charset+
    #   declaration (in expanded output mode) or a byte-order mark (in compressed mode) to indicate its encoding to
    #   browsers or other consumers. If +charset+ is +false+, these annotations are omitted.
    # @param source_map [Boolean] Whether or not Sass should generate a source map.
    # @param source_map_include_sources [Boolean] Whether Sass should include the sources in the generated source map.
    # @param style [String, Symbol] The OutputStyle of the compiled CSS.
    # @param functions [Hash<String, Proc>] Additional built-in Sass functions that are available in all stylesheets.
    # @param importers [Array<Object>] Custom importers that control how Sass resolves loads from rules like
    #   {@use}[https://sass-lang.com/documentation/at-rules/use] and {@import}[https://sass-lang.com/documentation/at-rules/import].
    # @param alert_ascii [Boolean] If this is +true+, the compiler will exclusively use ASCII characters in its error
    #   and warning messages. Otherwise, it may use non-ASCII Unicode characters as well.
    # @param alert_color [Boolean] If this is +true+, the compiler will use ANSI color escape codes in its error and
    #   warning messages. If it's +false+, it won't use these. If it's +nil+, the compiler will determine whether or
    #   not to use colors depending on whether the user is using an interactive terminal.
    # @param logger [Object] An object to use to handle warnings and/or debug messages from Sass.
    # @param quiet_deps [Boolean] If this option is set to +true+, Sass won’t print warnings that are caused by
    #   dependencies. A “dependency” is defined as any file that’s loaded through +load_paths+ or +importer+.
    #   Stylesheets that are imported relative to the entrypoint are not considered dependencies.
    # @param verbose [Boolean] By default, Dart Sass will print only five instances of the same deprecation warning per
    #   compilation to avoid deluging users in console noise. If you set verbose to +true+, it will instead print every
    #   deprecation warning it encounters.
    # @return [CompileResult]
    # @raise [CompileError]
    # @see https://sass-lang.com/documentation/js-api/modules#compile
    def compile(path,
                load_paths: [],

                charset: true,
                source_map: false,
                source_map_include_sources: false,
                style: :expanded,

                functions: {},
                importers: [],

                alert_ascii: false,
                alert_color: nil,
                logger: nil,
                quiet_deps: false,
                verbose: false)
      raise ArgumentError, 'path must be set' if path.nil?

      Host.new(@channel).compile_request(
        path: path,
        source: nil,
        importer: nil,
        load_paths: load_paths,
        syntax: nil,
        url: nil,
        charset: charset,
        source_map: source_map,
        source_map_include_sources: source_map_include_sources,
        style: style,
        functions: functions,
        importers: importers,
        alert_color: alert_color,
        alert_ascii: alert_ascii,
        logger: logger,
        quiet_deps: quiet_deps,
        verbose: verbose
      )
    end

    # Compiles a stylesheet whose contents is +source+ to CSS.
    # @param source [String]
    # @param importer [Object] The importer to use to handle loads that are relative to the entrypoint stylesheet.
    # @param load_paths [Array<String>] Paths in which to look for stylesheets loaded by rules like
    #   {@use}[https://sass-lang.com/documentation/at-rules/use] and {@import}[https://sass-lang.com/documentation/at-rules/import].
    # @param syntax [String, Symbol] The Syntax to use to parse the entrypoint stylesheet.
    # @param url [String] The canonical URL of the entrypoint stylesheet. If this is passed along with +importer+, it's
    #   used to resolve relative loads in the entrypoint stylesheet.
    # @param charset [Boolean] By default, if the CSS document contains non-ASCII characters, Sass adds a +@charset+
    #   declaration (in expanded output mode) or a byte-order mark (in compressed mode) to indicate its encoding to
    #   browsers or other consumers. If +charset+ is +false+, these annotations are omitted.
    # @param source_map [Boolean] Whether or not Sass should generate a source map.
    # @param source_map_include_sources [Boolean] Whether Sass should include the sources in the generated source map.
    # @param style [String, Symbol] The OutputStyle of the compiled CSS.
    # @param functions [Hash<String, Proc>] Additional built-in Sass functions that are available in all stylesheets.
    # @param importers [Array<Object>] Custom importers that control how Sass resolves loads from rules like
    #   {@use}[https://sass-lang.com/documentation/at-rules/use] and {@import}[https://sass-lang.com/documentation/at-rules/import].
    # @param alert_ascii [Boolean] If this is +true+, the compiler will exclusively use ASCII characters in its error
    #   and warning messages. Otherwise, it may use non-ASCII Unicode characters as well.
    # @param alert_color [Boolean] If this is +true+, the compiler will use ANSI color escape codes in its error and
    #   warning messages. If it's +false+, it won't use these. If it's +nil+, the compiler will determine whether or
    #   not to use colors depending on whether the user is using an interactive terminal.
    # @param logger [Object] An object to use to handle warnings and/or debug messages from Sass.
    # @param quiet_deps [Boolean] If this option is set to +true+, Sass won’t print warnings that are caused by
    #   dependencies. A “dependency” is defined as any file that’s loaded through +load_paths+ or +importer+.
    #   Stylesheets that are imported relative to the entrypoint are not considered dependencies.
    # @param verbose [Boolean] By default, Dart Sass will print only five instances of the same deprecation warning per
    #   compilation to avoid deluging users in console noise. If you set verbose to +true+, it will instead print every
    #   deprecation warning it encounters.
    # @return [CompileResult]
    # @raise [CompileError]
    # @see https://sass-lang.com/documentation/js-api/modules#compileString
    def compile_string(source,
                       importer: nil,
                       load_paths: [],
                       syntax: :scss,
                       url: nil,

                       charset: true,
                       source_map: false,
                       source_map_include_sources: false,
                       style: :expanded,

                       functions: {},
                       importers: [],

                       alert_ascii: false,
                       alert_color: nil,
                       logger: nil,
                       quiet_deps: false,
                       verbose: false)
      raise ArgumentError, 'source must be set' if source.nil?

      Host.new(@channel).compile_request(
        path: nil,
        source: source,
        importer: importer,
        load_paths: load_paths,
        syntax: syntax,
        url: url,
        charset: charset,
        source_map: source_map,
        source_map_include_sources: source_map_include_sources,
        style: style,
        functions: functions,
        importers: importers,
        alert_color: alert_color,
        alert_ascii: alert_ascii,
        logger: logger,
        quiet_deps: quiet_deps,
        verbose: verbose
      )
    end

    # @return [String] Information about the Sass implementation.
    # @see https://sass-lang.com/documentation/js-api/modules#info
    def info
      @info ||= Host.new(@channel).version_request
    end

    def close
      @channel.close
    end

    def closed?
      @channel.closed?
    end
  end
end
