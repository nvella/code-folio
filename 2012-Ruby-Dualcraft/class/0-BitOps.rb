module Dualcraft
  class BitOps
    def self.byte_to_bits(byte)
      out = []
      8.times do |i|
        out.push(byte[i])
      end
      return out
    end
    
    def self.bits_to_byte(bits)
      out = 0
      bits.length.times do |i|
        if bits[i] == 1 then
          out += 2 ** i
        end
      end
      return out
    end
  end
end
