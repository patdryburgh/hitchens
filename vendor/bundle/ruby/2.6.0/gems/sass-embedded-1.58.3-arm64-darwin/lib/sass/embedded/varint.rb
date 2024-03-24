# frozen_string_literal: true

module Sass
  class Embedded
    # The {Varint} module.
    #
    # It reads and writes varints.
    module Varint
      module_function

      def read(readable)
        value = bits = 0
        loop do
          byte = readable.readbyte
          value |= (byte & 0x7f) << bits
          bits += 7
          break if byte < 0x80
        end
        value
      end

      def write(writeable, value)
        bytes = []
        until value < 0x80
          bytes << ((value & 0x7f) | 0x80)
          value >>= 7
        end
        bytes << value
        writeable.write bytes.pack('C*')
      end
    end

    private_constant :Varint
  end
end
