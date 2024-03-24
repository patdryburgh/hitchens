# frozen_string_literal: true

require 'open3'

module Sass
  class Embedded
    # The {Compiler} class.
    #
    # It runs the `dart-sass-embedded` process.
    class Compiler
      def initialize
        @stdin, @stdout, @stderr, @wait_thread = Open3.popen3(*COMMAND, chdir: __dir__)
        @stdin.binmode
        @stdout.binmode
        @stdin_mutex = Mutex.new
        @stdout_mutex = Mutex.new

        Thread.new do
          loop do
            warn(@stderr.readline, uplevel: 1)
          rescue IOError, Errno::EBADF
            break
          end
        end
      end

      def close
        @stdin_mutex.synchronize do
          @stdin.close unless @stdin.closed?
          @stdout.close unless @stdout.closed?
          @stderr.close unless @stderr.closed?
        end

        @wait_thread.value
      end

      def closed?
        @stdin_mutex.synchronize do
          @stdin.closed?
        end
      end

      def write(payload)
        @stdin_mutex.synchronize do
          Varint.write(@stdin, payload.length)
          @stdin.write(payload)
        end
      end

      def read
        @stdout_mutex.synchronize do
          length = Varint.read(@stdout)
          @stdout.read(length)
        end
      end
    end

    private_constant :Compiler
  end
end
