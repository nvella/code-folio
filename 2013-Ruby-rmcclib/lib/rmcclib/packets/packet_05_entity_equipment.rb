module RMCCLib::Packets
  class Packet05EntityEquipment < Packet
    attr_reader :entity_id, :slot_id, :slot
    
    def initialize entity_id = 0, slot_id = 0, slot = RMCCLib::Slot.new
      super 0x05
      @entity_id = entity_id
      @slot_id = slot_id
      @slot = slot
    end
    
    def read socket
      @entity_id = socket.read_int
      @slot_id = socket.read_short
      @slot = RMCCLib::Slot.new
      @slot.read socket
    end
    
    def write socket
      socket.write_ubyte @id
      socket.write_int @entity_id
      socket.write_short @slot_id
      @slot.write socket
    end
  end
end
