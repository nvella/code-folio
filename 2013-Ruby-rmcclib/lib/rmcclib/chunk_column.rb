module RMCCLib
  class ChunkColumn
    attr_accessor :x, :z
  
    def initialize x = 0, z = 0
      @x = x
      @z = z
      @biomes = []
      @block_ids = {}
      @metadata = {}
      @block_light = {}
      @sky_light = {}
    end

    def get_block x, y, z
      chunk_y = y / 16
      chunk_rel_y = y % 16
      pos = (chunk_rel_y * 256) + (z * 16) + x
      if @block_ids[chunk_y] == nil then return Block.new 0, 0, 0, 0 end
      return Block.new @block_ids[chunk_y][pos].ord, 0, 0, 0
    end
    
    def set_block x, y, z, b
      chunk_y = y / 16
      pos = (y * 256) + (z * 16) + x
      if @block_ids[chunk_y] == nil then 
        @block_ids[chunk_y] = "\0" * 4096
        @metadata[chunk_y] = "\0" * 2048
        @block_light[chunk_y] = "\0" * 2048
        @sky_light[chunk_y] = "\0" * 2048
      end
      
      @block_ids[chunk_y][pos] = b.id.chr
#      @metadata[chunk_y][pos] = b.metadata.chr TODO: Figure this out
#      @sky_light[chunk_y][pos] = b.block_light TODO: Figure this out as well
#      @sky_light[chunk_y][pos] = b.sky_light
    end
    
    def read ground_up, primary_bitmap, add_bitmap, stream
      # Thanks to DavidEGrayson's redstone-bot2 for helping me find out how to do this correctly.
 
      chunks_todo = []
      chunks_to_wipe = []
      16.times {|bit| if primary_bitmap[bit] == 1 then chunks_todo.push bit else chunks_to_wipe.push bit end}
      
      # Block IDs
      chunks_todo.each do |chunk_y| 
        @block_ids[chunk_y] = stream.read 4096
      end
      
      # Metadata
      chunks_todo.each do |chunk_y|
        @metadata[chunk_y] = stream.read 2048     
      end
      
      # Block Light
      chunks_todo.each do |chunk_y|
        @block_light[chunk_y] = stream.read 2048   
      end
      
      # Sky Light
      chunks_todo.each do |chunk_y|
        @sky_light[chunk_y] = stream.read 2048   
      end
      
      
      256.times do
        @biomes.push stream.read_ubyte
      end
    end
  end
end
