module RMCCLib::Packets
  class Packet33ChunkData < Packet
    attr_reader :chunk_x, :chunk_z, :ground_up_continuous, :primary_bitmap, :add_bitmap, :data
  
    def initialize chunk_x = 0, chunk_z = 0, ground_up_continuous = true, primary_bitmap = 0, add_bitmap = 0, data = RMCCLib::SmartStringIO.new
      super 0x33
      @chunk_x = chunk_x
      @chunk_z = chunk_z
      @ground_up_continuous = ground_up_continuous
      @primary_bitmap = primary_bitmap
      @add_bitmap = add_bitmap
      @data = data
    end
    
    def read socket
      @chunk_x = socket.read_int
      @chunk_x = socket.read_int
      @ground_up_continous = socket.read_bool 
      @primary_bitmap = socket.read_ushort           
      @add_bitmap = socket.read_ushort
      @data = Zlib.inflate socket.read(socket.read_int)  
    end
    
    #def write socket TODO: Chunk writing code in ChunkColumn, misc code here
    #  socket.write_ubyte @id
    #  socket.write_int @random_id
    #end
  end
end
