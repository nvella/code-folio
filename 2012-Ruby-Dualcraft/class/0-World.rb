module Dualcraft
  FOG_COLOR = [0xffff6c00, 0xff00d8e4, 0xff00d8e4, 0xffff5d00, 0xff93162b, #day
               0xff93162b, #sunset
               0xff000038, 0xff290070, 0xff5d0079, #night
               0xff75001f] #sunrise
               
  LIGHT_LEVELS = [13,      15,         15,        15,          13,
                  11,
                  8,       5,          8,
                  11]
                  
  DAY_LENGTH = 36000
                

  class World
    include Tickable
    attr_accessor :name, :chunks, :gen_data, :seed, :time
    
    def initialize(name = "world", seed = (rand(1000000000) - 500000000))
      @name = name
      @entities = []
      @chunks = {}
      @lightmap = {}
      @chunk_active_table = {}
      @seed = seed
      @time = 0
      @gen_data = {}
      @generator = WorldGeneratorMountains.new(self)
      if not Dir.exists?("worlds/#{@name}") then Dir.mkdir("worlds/#{@name}") end
      @auto_save_ticks = 0
    end
    
    def current_player
      @entities.each do |entity|
        if entity.class == EntityPlayer then return entity end
      end
      return nil
    end
    
    def load_world
      if not File.exists?("worlds/#{@name}/info.json") then return end
      @entities = []
      @gen_data = {}
      data = {}
      File.open("worlds/#{@name}/info.json", "r") {|file| data = JSON.parse(file.read)}
      @gen_data = data["gen_data"]
      @seed = data["seed"]
      @time = data["time"]
      data["entities"].each do |entity|
        e = $dualcraft_entities[entity["id"]].new(self)
        e.data = entity
        @entities.push(e)
      end
    end
    
    def save_world
      @chunks.each do |x, c|
        c.save_chunk("worlds/#{@name}/c.#{x}.dat")
      end
      save_metadata
    end

    def save_metadata
      data = {}
      data["gen_data"] = @gen_data
      data["seed"] = @seed
      data["time"] = @time
      data["entities"] = []
      @entities.each do |entity|
        data["entities"].push(entity.data)
      end
      File.open("worlds/#{@name}/info.json", "w") {|f| f.write(JSON.pretty_generate(data))}      
    end
    
    def load_chunk(x)
      puts("Loading chunk #{x}...")
      if not File.exists?("worlds/#{name}/c.#{x}.dat") then
        puts("Chunk #{x} does not exist. Generating...")
        @chunks[x] = @generator.generate(x)
      else
        @chunks[x] = Chunk.new(self)
        @chunks[x].load_chunk("worlds/#{name}/c.#{x}.dat")
      end
    end
    
    def unload_chunk(x)
      puts("Unloading chunk #{x}...")
      if @chunks[x] != nil then
        @chunks[x].save_chunk("worlds/#{@name}/c.#{x}.dat")
      else
        puts("@chunks[#{x}] equaled nil, couldn't save chunk.")
      end
      @chunks.delete(x)
    end
    
    def get_block(x, y, z)
      chunkX = (x / 64).floor
      relativeX = x % 64
      @chunk_active_table[chunkX] = 0

      if @chunks[chunkX] == nil then load_chunk(chunkX) end
      return @chunks[chunkX].blocks[relativeX][y][z]
    end
    
    def set_block(x, y, z, b)
      chunkX = (x / 64).floor
      relativeX = x % 64
      @chunk_active_table[chunkX] = 0

      if @chunks[chunkX] == nil then load_chunk(chunkX) end
      @chunks[chunkX].blocks[relativeX][y][z] = b
    end
    
    def update
      @auto_save_ticks += 1
      @time += 1
      if @time > DAY_LENGTH then @time = 0 end

      @chunk_active_table.each {|cx, t| if t != nil then @chunk_active_table[cx] += 1 end}
      @chunk_active_table.each do |cx, t|
        if t != nil and t > (60 * 4) then
          unload_chunk(cx)
          @chunk_active_table.delete(cx)        
        end
      end

      if current_player == nil then @entities.push(EntityPlayer.new(self)) end
      @entities.each do |entity|
        entity.do_effects
        entity.update
      end
      if @auto_save_ticks > 240 then
        @auto_save_ticks = 0
        save_world
      end
    end

    def get_light
      chunkX = (x / 64).floor
      relativeX = x % 64
      @chunk_active_table[chunkX] = 0

      if @chunks[chunkX] == nil then load_chunk(chunkX) end
      return @chunks[chunkX].light_map[relativeX][y]
    end

    def set_light(light_level)
      chunkX = (x / 64).floor
      relativeX = x % 64
      @chunk_active_table[chunkX] = 0

      if @chunks[chunkX] == nil then load_chunk(chunkX) end
      @chunks[chunkX].light_map[relativeX][y] = light_level
    end

    def update_lighting
      16.times { lighting_pass }
    end

    def lighting_pass
      @chunks.each do |cx, c|
        64.times.each do |x|
          256.times.each do |y|
            2.times.each do |z|
              #@lightmap[cx] = 
            end
          end
        end
      end
    end
    
    def skylight
      frac = (@time * 0.0000277777777777777777).floor
      return LIGHT_LEVELS[frac]
    end
  end
end
