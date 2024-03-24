# frozen_string_literal: true

module Sass
  # An exception thrown by Sass Script.
  class ScriptError < StandardError
    def initialize(message, name = nil)
      super(name.nil? ? message : "$#{name}: #{message}")
    end
  end
end
