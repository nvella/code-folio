class World
	include BlockList

	attr_accessor :width, :height, :thePlayer, :generated, :spawnX, :spawnY, :time, :entityList, :blockTable, :dataStore, :blockLog
	attr_reader :seed, :rng   

	def initialize(ac, w, h, seed = rand(Time.now.to_i))
        @ac = ac
        @width = w
        @height = h
        @blockTable = []
        @thePlayer = EntityPlayer.new(self)
        @generated = false
		@spawnX = 0
		@spawnY = 0
		@time = 0
		self.seed = seed # Needs to be called as if it came from outside the object
		initBlockArray
		@entityList = []
		@flag = 0
		@dataStore = []
		@blockLog = []
    end


    def initBlockArray
        @width.times do |x|
            @blockTable[x] = []
            @height.times do |y|
                @blockTable[x][y] = BlockAir.new(self,x,y)
				if @rng.rand(128) > 124 then @blockTable[x][y].setMetadata(1) end
            end
        end
    end

	def seed=(seed)
		@ac.log.log("seed")
		@seed = seed
		@rng = Random.new(seed)
	end

	def setSpawn(x,y)
		@spawnX = x
		@spawnY = y
	end

	def getForegroundColour
		if @time < 5400 then return 6
		elsif @time < 5600 then return 220
		elsif @time < 5650 then return 214
		elsif @time < 5700 then return 202
		elsif @time < 5750 then return 196
		elsif @time < 5800 then return 126
		elsif @time < 5850 then return 55
		elsif @time < 5900 then return 19
		elsif @time < 5950 then return 18
		elsif @time < 11400 then return 17
		elsif @time < 11600 then return 18
		elsif @time < 11650 then return 19
		elsif @time < 11700 then return 55
		elsif @time < 11750 then return 126
		elsif @time < 11800 then return 196
		elsif @time < 11850 then return 202
		elsif @time < 11900 then return 214
		elsif @time < 12000 then return 220
		end

		return rand(255)
	end
    
    def setBlock(x,y,block)
		if x >= @width or y >= @height or x < 0 or y < 0 then return false end
		log = []
		log.push(x, y, @blockTable[x][y].id, block.id)
        @blockTable[x][y] = block
		@blockLog.push(log)
		return true
    end
    
	def rollback(actions)
		actions.times do
			entry = @blockLog.pop
			if entry != nil then @blockTable[entry[0]][entry[1]] = getBlockForID(entry[2]).new(self, entry[0], entry[1]) end
		end
	end

    def getBlock(x,y)
		if x < 0 or y < 0 then return BlockMissingblo.new end
		if x >= @width or y >= @height then return BlockMissingblo.new end
		
		return @blockTable[x][y]
    end
    
    def render
        startX = 40 - @thePlayer.x
        startY = 10 - @thePlayer.y
        
        @entityList.each do |x|
        
        end
        
        79.times do |x|
			19.times do |y|
				if x == 40 and y == 10 then
					@ac.screen.setPixel(x,y,@thePlayer.getPixel)
				else
					@ac.screen.setPixel(x,y,getBlock(x - startX,y - startY).getPixel)
				end
			end
		end
    end
    
    def spawnEntity(entity)
		@entityTable.push(entity)
	end

    def tick
		@time += 4
		if @time >= 12000 then
			@time = 0
		end
		@thePlayer.tick
		@entityList.each do |entity| 
			entity.tick
		end
		
		startX = @thePlayer.x - 64
        startY = @thePlayer.y - 64
		endX = 64 + @thePlayer.x
		endY = 64 + @thePlayer.y

		128.times do |x|
            128.times do |y|
				if (startX + x) > -1 and (startY + y) > -1 and (startX + x) < @width and (startY + y) < @height then
					if @blockTable[startX + x][startY + y].x != startX + x or @blockTable[startX + x][startY + y].y != startY + y then 
						@blockTable[startX + x][startY + y].setPosition(startX + x, startY + y) 
						@ac.log.log("Block @ #{x + startX},#{y + startY} had its position set wrongly!")
					end
					@blockTable[startX + x][startY + y].tick
				end
            end
        end
		        
		render
    end
end
