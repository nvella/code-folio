module RMCCLib
  class NBT < Hash
    include JavaStreamIO
    
    def initialize
      @data = {}
    end
    
    def [] key
      @data[key]
    end
    
    def []= key, value
      @data[key] = value
    end
    
    def read stream
      @data = read_raw stream
    end
    
    def read_raw stream
      out = {}
      while true do
        byte = stream.read(1)
        if byte == nil or byte.ord == 0 then break end
        
        name = stream.read(stream.read_ushort).force_encoding 'UTF-8'
        out[name] = read_tag stream, byte.ord
      end
      out
    end
      
    def read_tag stream, tag_id
      case tag_id
      when 1 
        return stream.read_byte
      when 2
        return stream.read_short
      when 3
        return stream.read_int
      when 4
        return stream.read_long
      when 5
        return stream.read_float
      when 6
        return stream.read_double
      when 7
        out = []
        stream.read_int.times {out.push stream.read_byte}
        return out
      when 8
        return stream.read(stream.read_ushort).force_encoding 'UTF-8'
      when 9
        out = []
        subtag_id = stream.read_byte
        stream.read_int.times do
          out.push read_tag(stream, subtag_id)
        end
        return out
      when 10 
        read_raw stream
      when 11
        out = []
        stream.read_int.times {out.push stream.read_int}
        return out
      end
    end
  end
end