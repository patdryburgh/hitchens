# frozen_string_literal: true

module Sass
  module Value
    # Sass's string type.
    #
    # @see https://sass-lang.com/documentation/js-api/classes/SassString
    class String
      include Value

      # @param text [::String]
      # @param quoted [::Boolean]
      def initialize(text = '', quoted: true)
        @text = text.freeze
        @quoted = quoted
      end

      # @return [::String]
      attr_reader :text

      # @return [::Boolean]
      def quoted?
        @quoted
      end

      # @return [::Boolean]
      def ==(other)
        other.is_a?(Sass::Value::String) && other.text == text
      end

      # @return [Integer]
      def hash
        @hash ||= text.hash
      end

      # @return [String]
      def assert_string(_name = nil)
        self
      end

      # @param sass_index [Number]
      # @return [Integer]
      def sass_index_to_string_index(sass_index, name = nil)
        index = sass_index.assert_number(name).assert_integer(name)
        raise Sass::ScriptError.new('String index may not be 0', name) if index.zero?

        if index.abs > text.length
          raise Sass::ScriptError.new("Invalid index #{sass_index} for a string with #{text.length} characters", name)
        end

        index.negative? ? text.length + index : index - 1
      end
    end
  end
end
