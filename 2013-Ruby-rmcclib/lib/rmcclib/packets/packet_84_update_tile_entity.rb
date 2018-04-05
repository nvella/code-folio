module RMCCLib::Packets
  class Packet84UpdateTileEntity < Packet
    attr_reader :x, :y, :z, :action, :nbt
  
    def initialize x = 0, y = 0, z = 0, action = 0, nbt = RMCCLib::NBT.new
      super 0x84
      @x = x
      @y = y
      @z = z
      @action = action
      @nbt = nbt
    end
    
    def read socket
      @x = socket.read_int
      @y = socket.read_short
      @z = socket.read_int
      @action = socket.read_byte
      
      data_length = socket.read_ushort
      if data_length > 0 then
        @nbt = RMCCLib::NBT.new
        @nbt.read RMCCLib::SmartGzipReader.new RMCCLib::SmartStringIO.new(socket.read data_length)
      end
    end
        
    # No writing for this packet until writing in RMCCLib::NBT is implemented.
  end
end