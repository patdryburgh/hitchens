# frozen_string_literal: true

module Sass
  module Value
    # Sass's argument list type.
    #
    # An argument list comes from a rest argument. It's distinct from a normal {List} in that it may contain a keyword
    # map as well as the positional arguments.
    #
    # @see https://sass-lang.com/documentation/js-api/classes/SassArgumentList
    class ArgumentList < Value::List
      # @param contents [Array<Value>]
      # @param keywords [Hash<::String, Value>]
      # @param separator [::String]
      def initialize(contents = [], keywords = {}, separator = ',')
        super(contents, separator: separator)

        @id = 0
        @keywords_accessed = false
        @keywords = keywords.transform_keys(&:to_s).freeze
      end

      # @return [Hash<::String, Value>]
      def keywords
        @keywords_accessed = true
        @keywords
      end

      private

      def initialize_copy(orig)
        super
        @id = 0
      end
    end
  end
end
