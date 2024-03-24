# frozen_string_literal: true

module Sass
  # The built-in Node.js package importer. This loads pkg: URLs from node_modules
  # according to the standard Node.js resolution algorithm.
  #
  # @see https://sass-lang.com/documentation/js-api/classes/nodepackageimporter/
  class NodePackageImporter
    def initialize(entry_point_directory)
      raise ArgumentError, 'entry_point_directory must be set' if entry_point_directory.nil?

      @entry_point_directory = File.absolute_path(entry_point_directory)
    end
  end
end
