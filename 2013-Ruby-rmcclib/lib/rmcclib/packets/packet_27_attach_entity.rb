module RMCCLib::Packets
  class Packet27AttachEntity < Packet
    attr_reader :entity_id, :vehicle_id, :leash
  
    def initialize entity_id = 0, vehicle_id = 0, leash = false
      super 0x27
      @entity_id = entity_id
      @vehicle_id = vehicle_id
      @leash = leash
    end
    
    def read socket
      @entity_id = socket.read_int
      @vehicle_id = socket.read_int
      @leash = socket.read_bool
    end
    
    def write socket
      socket.write_ubyte @id
      socket.write_int @entity_id
      socket.write_int @vehicle_id
      socket.write_bool @leash
    end
  end
end