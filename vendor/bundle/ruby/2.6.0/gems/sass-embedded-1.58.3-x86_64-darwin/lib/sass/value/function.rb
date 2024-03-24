# frozen_string_literal: true

module Sass
  module Value
    # Sass's function type.
    #
    # @see https://sass-lang.com/documentation/js-api/classes/SassFunction
    class Function
      include Value

      # @overload initialize(id)
      #   @param id [Numeric]
      # @overload initialize(signature, callback)
      #   @param signature [::String]
      #   @param callback [Proc]
      def initialize(id_or_signature, callback = nil)
        if id_or_signature.is_a? Numeric
          @id = id_or_signature
        else
          @signature = id_or_signature
          @callback = callback
        end
      end

      # @return [Integer, nil]
      attr_reader :id

      # @return [::String, nil]
      attr_reader :signature

      # @return [Proc, nil]
      attr_reader :callback

      # @return [::Boolean]
      def ==(other)
        if id.nil?
          other.equal? self
        else
          other.is_a?(Sass::Value::Function) && other.id == id
        end
      end

      # @return [Integer]
      def hash
        id.nil? ? signature.hash : id.hash
      end

      # @return [Function]
      def assert_function(_name = nil)
        self
      end
    end
  end
end
