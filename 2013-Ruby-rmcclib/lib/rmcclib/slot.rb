module RMCCLib
  class Slot
    attr_accessor :item_id, :item_count, :item_damage, :nbt
  
    def initialize item_id = 0, item_count = 0, item_damage = 0, nbt = NBT.new
      @item_id = item_id
      @item_count = item_count
      @item_damage = item_damage
    end
    
    def read stream
      @item_id = stream.read_short
      if @item_id == -1 then return end
      @item_count = stream.read_byte
      @item_damage = stream.read_short
      nbt_length = stream.read_short
      if nbt_length < 0 then return end
      @nbt = NBT.new
      @nbt.read SmartGzipReader.new SmartStringIO.new(stream.read(nbt_length))
    end
    
    def write stream
      stream.write_short @item_id
      if @item_id == -1 then return end
      stream.write_byte @item_count
      stream.write_short @item_damage
      stream.write_short -1 # TODO: NBT
    end
  end
end