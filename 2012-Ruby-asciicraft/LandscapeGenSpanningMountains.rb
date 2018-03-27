class LandscapeGenSpanningMountains
    def initialize(world)
		@world = world

		###############
		# Notes for tweaking these values	
	
		#1: Make sure directionChangeMin is larger tha heightChangeMin for non-rough landscape
		#2: Maxes are not really maxes, mins can be higher than maxes
		
		@heightChangeMin = 2
		@heightChangeMax = 2
		@directionChangeMin = 16
		@directionChangeMax = 64
    end
    
    def generate
		topY = @world.height - 64 - @world.rng.rand(4)
		nextHeightChange = @heightChangeMin + @world.rng.rand(@heightChangeMax)
		nextDirectionChange = @directionChangeMin + @world.rng.rand(@directionChangeMax)
		direction = 1 #0 = up, 1 = down
		@world.setSpawn(0, topY - 1)
		@world.width.times do |x|

			if nextHeightChange < 1 then
				if direction > 0 then
					if topY < (@world.height - 48) then
						topY += @world.rng.rand(2) 
					end
				else 
					if topY > 4 then
						topY -= @world.rng.rand(2) 
					end
				end
				nextHeightChange = @heightChangeMin + @world.rng.rand(@heightChangeMax)
			end

			if nextDirectionChange < 1 then
				if direction == 0 then 
					direction = 1 
				else 
					direction = 0 
				end	
				nextDirectionChange = @directionChangeMin + @world.rng.rand(@directionChangeMax)
			end

			@world.setBlock(x, topY, BlockGrass.new(@world, x, topY))
			generateY(x, topY)

			nextHeightChange -= 1
			nextDirectionChange -= 1

		end

		decorate

		@world.width.times do |x|
			@world.setBlock(x,@world.height - 1,BlockBedrock.new(@world, x,@world.height - 1))
		end
		spawnX = ((@world.width / 2) - 16) + @world.rng.rand(32)
		@world.setSpawn(spawnX, getHighestBlockY(spawnX) - 1)
    end
    
    def generateY(x, startY)
		y = startY
		while true do
			y += 1
			if @world.getBlock(x,y).class == BlockMissingblo then break end
			
			if @world.getBlock(x,y).class == BlockAir then
				@world.setBlock(x,y,fillInBlankAccordingToY(startY, y).new(@world, x, y))
			end	
		end
    end

	def fillInBlankAccordingToY(startY, y)
		if y < startY + 4 then
			return BlockDirt
		elsif y > @world.height - 4 then
			if @world.rng.rand(6) == 0 then return BlockStone else return BlockBedrock end
		else
			return BlockStone
		end
		
	end

	def decorate
		nextTree = 12 + @world.rng.rand(8)
		nextCave = 48 + @world.rng.rand(24)
		
		@world.width.times do |x|

			if nextTree < 1 then
				LandscapeGenPieceTree.new(@world, x - 4, getHighestBlockY(x) - 1).print
				nextTree = 12 + @world.rng.rand(8)
			end

			if nextCave < 1 then
				LandscapeGenPieceCave.new(@world, x, getHighestBlockY(x) + 32).print
				nextCave = 48 + @world.rng.rand(24)
			end

			nextTree -= 1
			nextCave -= 1
		end
	end

	def getHighestBlockY(x)
		@world.height.times do |y|
			if @world.getBlock(x,y).class != BlockAir then return y end
		end
	end
end
