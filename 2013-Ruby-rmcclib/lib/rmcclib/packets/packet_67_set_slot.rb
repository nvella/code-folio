module RMCCLib::Packets
  class Packet67SetSlot < Packet
    attr_reader :reason, :game_mode
    
    def initialize window_id = 0, slot_id = 0, slot = nil
      super 0x67
      @window_id = window_id
      @slot_id = slot_id
      @slot = slot
    end
    
    def read socket
      @window_id = socket.read_byte
      @slot_id = socket.read_short
      @slot = RMCCLib::Slot.new
      @slot.read socket
    end
    
    def write socket
      socket.write_ubyte @id
      socket.write_byte @window_id
      socket.write_short @slot_id
      @slot.write socket
    end
  end
end