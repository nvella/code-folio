module Dualcraft
  class Chunk
    attr_accessor :blocks
    attr_reader :width, :height, :length
  
    def initialize(world)
      @world = world
      @width = 64
      @height = 256
      @length = 2
      create_block_array
    end
    
    def create_block_array
      @blocks = [] # x, y, z
      @width.times do |x|
        @blocks[x] = []
        @height.times do |y|
          @blocks[x][y] = []
          @length.times do |z|
            @blocks[x][y][z] = nil
          end
        end
      end
    end
    
    def save_chunk(location)
      File.open(location, "w") do |file|
        @width.times do |x|
          @height.times do |y| 
            @length.times do |z|
              if @blocks[x][y][z] != nil then
                if z > 0 then
                  b = 128
                else
                  b = 0
                end
                b += x
                file.write(b.chr)
                file.write(y.chr)
                file.write(@blocks[x][y][z].id.chr)
                file.write(@blocks[x][y][z].md.chr)
                lvlbyte = BitOps.bits_to_byte(BitOps.byte_to_bits(@blocks[x][y][z].light_level)[0..3] + [0, 0, 0, 0])
                file.write(lvlbyte.chr)
              end
            end
          end
        end
      end
    end
    
    def load_chunk(location)
      create_block_array
      d = ""
      File.open(location, "r") do |file|
        d = file.read
      end

      (d.length / 5).floor.times do |i|
        b = d.getbyte(i * 5)
        
        z = b[7]
        if z > 0 then
          x = b - 128
        else
          x = b
        end
        
        y = d.getbyte((i * 5) + 1)
        id = d.getbyte((i * 5) + 2)
        md = d.getbyte((i * 5) + 3)
        lightlvl = BitOps.bits_to_byte(BitOps.byte_to_bits(d.getbyte((i * 5) + 4))[0..3])
        bl = $dualcraft_blocks[id].new(@world)
        bl.md = md
        bl.light_level = lightlvl
        @blocks[x][y][z] = bl
      end
    end

    def reverse
      new_array = []
      @width.times do |x|
        new_array[x] = []
        @height.times do |y|
          new_array[x][y] = []
          @length.times do |z|
            new_array[x][y][z] = @blocks[(@width - 1) - x][y][z]
          end
        end
      end
      
      return new_array
    end

    def reverse!
      @blocks = reverse
    end
  end
end         
      
