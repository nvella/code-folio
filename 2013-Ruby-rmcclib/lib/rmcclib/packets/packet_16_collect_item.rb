module RMCCLib::Packets
  class Packet16CollectItem < Packet
    attr_reader :item_entity_id, :player_entity_id
  
    def initialize item_entity_id = 0, player_entity_id = 0
      super 0x16
      @item_entity_id = item_entity_id
      @player_entity_id = player_entity_id
    end
    
    def read socket
      @item_entity_id = socket.read_int
      @player_entity_id = socket.read_int
    end
    
    def write socket
      socket.write_ubyte @id
      socket.write_int @item_entity_id 
      socket.write_int @player_entity_id 
    end
  end
end
