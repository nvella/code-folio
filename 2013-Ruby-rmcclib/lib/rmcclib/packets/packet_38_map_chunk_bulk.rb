module RMCCLib::Packets
  class Packet38MapChunkBulk < Packet
    attr_reader :chunk_column_count, :skylight_sent, :raw_data, :metadata
    
    def initialize chunk_column_count = 0, skylight_sent = false, raw_data = RMCCLib::SmartStringIO.new, metadata = []
      super 0x38
      @chunk_column_count = chunk_column_count
      @skylight_sent = skylight_sent
      @raw_data = raw_data
      @metadata = []
    end
    
    def read socket
      @chunk_column_count = socket.read_short
      length_of_compressed_data = socket.read_int
      @skylight_sent = socket.read_bool
      @raw_data = RMCCLib::SmartStringIO.new Zlib.inflate socket.read(length_of_compressed_data)
      metadata = RMCCLib::SmartStringIO.new socket.read(@chunk_column_count * 12)
      
      #chunk_column_count.times do |i| TODO: Unpack this packet in a thread and merge into world.
      #  chunk_col = RMCCLib::ChunkColumn.new metadata.read_int, metadata.read_int
      #  primary_bitmap = metadata.read_ushort
      #  add_bitmap = metadata.read_ushort
      #
      #  chunk_col.read true, primary_bitmap, add_bitmap, raw_data
      #  
      #  @world.chunk_columns["#{chunk_col.x},#{chunk_col.z}"] = chunk_col
      #end
      
      chunk_column_count.times do |i|
        @metadata[i] = {}
        @metadata[i]['chunk_x'] = metadata.read_int
        @metadata[i]['chunk_z'] = metadata.read_int
        @metadata[i]['primary_bitmap'] = metadata.read_ushort
        @metadata[i]['add_bitmap'] = metadata.read_ushort
      end
    end
    
    def write socket
      socket.write @id
      
      # TODO: Implement sending world chunk bulks.
    end
  end
end