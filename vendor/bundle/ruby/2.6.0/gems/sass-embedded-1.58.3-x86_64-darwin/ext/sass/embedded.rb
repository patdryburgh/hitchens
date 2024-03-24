# frozen_string_literal: true

module Sass
  class Embedded
    class Compiler
      COMMAND = [
        File.absolute_path('sass_embedded/src/dart', __dir__),
        File.absolute_path('sass_embedded/src/dart-sass-embedded.snapshot', __dir__)
      ].freeze
    end
  end
end
