module RMCCLib::Packets
  class Packet2CEntityProperties < Packet
    attr_reader :entity_id, :properities
  
    def initialize entity_id = 0, properties = {}
      super 0x2C
      @entity_id = entity_id
      @properties = properties
    end
    
    def read socket
      @entity_id = socket.read_int
      @properties = {}
      socket.read_int.times do
        key = socket.read_string
        value = socket.read_double
        list = []
        
        socket.read_short.times do
          array  = []
          array.push socket.read_long
          array.push socket.read_long
          array.push socket.read_double
          array.push socket.read_byte
          list.push array
        end
        @properties[key] = [value, list]
      end
    end
    
    def write socket
      socket.write_ubyte @id
      socket.write_int @entity_id
      socket.write_int @properties.length
      @properties.each do |key, data|
        socket.write_string key
        socket.write_double data[0]
        socket.write_short data[1].length
        data[1].each do |values|
          socket.write_long values[0]
          socket.write_long values[1]
          socket.write_double values[2]
          socket.write_short values[3]
        end
      end
    end
  end
end