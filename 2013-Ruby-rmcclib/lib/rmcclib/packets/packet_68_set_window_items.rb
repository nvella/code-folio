module RMCCLib::Packets
  class Packet68SetWindowItems < Packet
    attr_reader :window_id, :slots
    
    def initialize window_id = 0, slots = []
      super 0x68
      @window_id = window_id
      @slots = slots
    end
    
    def read socket
      @window_id = socket.read_byte
      length_of_slot_array = socket.read_short
      length_of_slot_array.times do |i|
        slots[i] = RMCCLib::Slot.new
        slots[i].read socket
      end
    end
    
    def write socket
      socket.write_ubyte @id
      socket.write_byte @window_id
      socket.write_short @slots.length
      @slots.each do |slot|
        slot.write socket
      end
    end
  end
end