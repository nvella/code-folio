class LandscapeGenPieceCave
	def initialize(world,x,y)
		@world = world		
		@x = x
		@y = y
	end

	def print
		width = 32 + @world.rng.rand(16)
		height = 4 + @world.rng.rand(8)
		direction = 0
		nextDirectionChange = 2 + @world.rng.rand(16)
		nextSystemMove = 4 + @world.rng.rand(2)
		wY = 3

		width.times do |wX|
			wY.times do |wwY|
				@world.setBlock(@x + wX, @y + wwY, BlockAir.new(@world, @x + wX, @y + wwY))
				@world.setBlock(@x + wX, @y - wwY, BlockAir.new(@world, @x + wX, @y - wwY))
			end
		
			if direction == 0 then
				if wY < height then wY += 1 end
			else
				if wY > 3 then wY -= 1 end
			end

			if nextDirectionChange < 1 then
				if direction == 0 then direction = 1 else direction == 0 end
				nextDirectionChange = 2 + @world.rng.rand(16)
			end	

			if nextSystemMove < 1 then
				if direction == 0 then @y -= (1 + @world.rng.rand(1)) else @y += (1 + @world.rng.rand(1)) end
				nextSystemMove = 4 + @world.rng.rand(2)
			end
		
			nextDirectionChange -= 1
			nextSystemMove -= 1
		end

		if @world.rng.rand(100) < 50 then
			LandscapeGenPieceCave.new(@world, @x + width, @y).print
		end
	end
end
