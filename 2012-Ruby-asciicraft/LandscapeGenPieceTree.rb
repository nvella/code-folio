class LandscapeGenPieceTree
	def initialize(world,x,y)
		@world = world		
		@x = x
		@y = y
	end

	def print
		if @world.getBlock(@x + 4, @y + 1).class == BlockDirt or @world.getBlock(@x + 4, @y + 1).class == BlockGrass then
			9.times do |leaveX|
				@world.setBlock(@x + leaveX, @y - 3, BlockLeaves.new(@world, @x + leaveX, @y - 3))
			end

			7.times do |leaveX| 
				@world.setBlock(@x + leaveX + 1, @y - 4, BlockLeaves.new(@world, @x + leaveX + 1, @y - 4))
			end

			5.times do |leaveX|
				@world.setBlock(@x + leaveX + 2, @y - 5, BlockLeaves.new(@world, @x + leaveX + 2, @y - 5))
			end

			4.times do |logY|
				@world.setBlock(@x + 4, @y - logY, BlockLog.new(@world, @x + 4, @y - logY))
			end
		end
	end
end
