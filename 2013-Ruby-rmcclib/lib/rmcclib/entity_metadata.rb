module RMCCLib
  class EntityMetadata < Hash
    include JavaStreamIO
  
    def read stream
      # an implementation of the c-like psuedocode for reading entity metadata found on wiki.vg:
    
      while true do
        byte = stream.read_ubyte
        if byte == 127 then break end
        index = byte & 0x1f
        type = byte >> 5
        
        case type
        when 0 # byte
          self[index] = stream.read_byte
        when 1 # short
          self[index] = stream.read_short
        when 2 # int
          self[index] = stream.read_int
        when 3 # float
          self[index] = stream.read_float
        when 4 # string (string16)
          self[index] = stream.read_string
        when 5 # slot
          self[index] = Slot.new
          self[index].read stream
        when 6 # x, y, z (all int)
          self[index] = [stream.read_int, stream.read_int, stream.read_int]
        end
      end
    end
    
    def write
      # TODO: writing code.
    end
  end
end