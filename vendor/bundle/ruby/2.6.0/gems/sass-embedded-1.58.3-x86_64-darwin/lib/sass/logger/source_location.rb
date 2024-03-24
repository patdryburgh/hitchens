# frozen_string_literal: true

module Sass
  module Logger
    # A specific location within a source file.
    #
    # This is always associated with a {SourceSpan} which indicates which file it refers to.
    #
    # @see https://sass-lang.com/documentation/js-api/interfaces/SourceLocation
    class SourceLocation
      # @return [Integer]
      attr_reader :offset, :line, :column

      def initialize(offset, line, column)
        @offset = offset
        @line = line
        @column = column
      end
    end
  end
end
