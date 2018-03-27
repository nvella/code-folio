module Dualcraft  
  class WorldGeneratorMountains
    def initialize(world)
      @world = world

      ###############
      # Notes for tweaking these values  
  
      #1: Make sure directionChangeMin is larger than heightChangeMin for non-rough landscape
      #2: Maxes are not really maxes, mins can be higher than maxes
    
      @heightChangeMin = 1 # 2 
      @heightChangeMax = 2 # 2
      @directionChangeMin = 16
      @directionChangeMax = 64
      @rng = Random.new
    end

    def createValues
      values = {}      
      values["topY"] = 256 - 64 - @rng.rand(4)
      values["nextHeightChange"] = @heightChangeMin + @rng.rand(@heightChangeMax)
      values["nextDirectionChange"] = @directionChangeMin + @rng.rand(@directionChangeMax)
      values["direction"] = 1 #0 = up, 1 = down
      return values
    end
      
    def generate(cx)
      @rng = Random.new(@world.seed + cx)
      chunk = Chunk.new(@world)
      
      if cx < 0 then
        values = @world.gen_data[cx + 1]
      else
        values = @world.gen_data[cx - 1]
      end

      if values == nil then values = createValues end

      #@values["topY"] = @world.height - 64 - @rng.rand(4)
      #@values["nextHeightChange"] = @heightChangeMin + @rng.rand(@heightChangeMax)
      #@values["nextDirectionChange"] = @directionChangeMin + @rng.rand(@directionChangeMax)
      #@values["direction"] = 1 #0 = up, 1 = down
      #@world.setSpawn(0, topY - 1)
      chunk.width.times do |x|
        if values["nextHeightChange"] < 1 then
          if values["direction"] > 0 then
            if values["topY"] < (chunk.height - 48) then
              values["topY"] += @rng.rand(2) 
            end
          else 
            if values["topY"] > 4 then
              values["topY"] -= @rng.rand(2) 
            end
          end
          values["nextHeightChange"] = @heightChangeMin + @rng.rand(@heightChangeMax)
        end
          
        if values["nextDirectionChange"] < 1 then
          if values["direction"] == 0 then 
            values["direction"] = 1 
          else 
            values["direction"] = 0 
          end  
          values["nextDirectionChange"] = @directionChangeMin + @rng.rand(@directionChangeMax)
        end

        chunk.blocks[x][values["topY"]][0] = BlockGrass.new(@world)
        generateY(x, values["topY"], chunk)

        values["nextHeightChange"] -= 1
        values["nextDirectionChange"] -= 1
      end

      @world.gen_data[cx] = values
      if cx < 0 then chunk.reverse! end
      return chunk
    end
      
    def generateY(x, startY, chunk)
      y = startY
      while true do
        y -= 1
        if y < 0 then break end
      
        if chunk.blocks[x][y][0] == nil then
          chunk.blocks[x][y][0] = fillInBlankAccordingToY(startY, y).new(@world)
        end  
      end
    end

    def fillInBlankAccordingToY(startY, y)
      if y > startY - 4 then
        return BlockDirt
      else
        return BlockStone
      end
    end

    def getHighestBlockY(x)
      @chunk.height.times do |y|
        if @chunk.getBlock(x, @chunk.height - y, 0) != nil then return y end
      end
    end
  end
end
