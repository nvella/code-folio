class Entity
    attr_reader :x, :y, :health, :fileData

    def initialize(world, id=0)
        @world = world
        @x = 0
        @y = 0
        @health = 10
		@voidDamageTick = 0
        @fallTick = 2
		@fallWait = 2
		@fallDamage = 0
        @id = 0
        @fileData = []
		16.times do |x|
			@fileData[x] = 0
		end
    end

	def tick
		@voidDamageTick += 1
        @fallTick -= 1

		if @world.getBlock(@x,@y + 1).noclip? and @fallTick < 1 then		
			
			if @world.getBlock(@x, @y).class == BlockWater then
				@fallTick = @fallWait * 4
				@fallDamage = 0
			else            
				@fallTick = @fallWait
            	@fallDamage += 1
			end

			setPosition(@x, @y + 1)
		end
		
		if not @world.getBlock(@x,@y).noclip? then
			@health -= 1
		end

		if not @world.getBlock(@x,@y + 1).noclip? then		
			if @fallDamage > 4 then
				@fallDamage -= 4			        
				@health -= @fallDamage
			end
			@fallDamage = 0			
		end

		if @y >= @world.height and @voidDamageTick >= 2 then
			@voidDamageTick = 0
			@health -= 2
		end
	end
    
    def setPosition(x,y)
		if not @world.getBlock(x,y).noclip? then return end
		@x = x
       	@y = y
    end

	def jump
		if not @world.getBlock(@x,@y + 1).noclip? then	
			if @world.getBlock(@x, @y).class == BlockWater then
				@fallTick = @fallWait * 4
			else    	
				@fallTick = 6	
			end		
			setPosition(@x, @y - 1)
			return true		
		end
		return false
	end
    
    def setHealth(health)
        @health = health
    end
    
    def setData(id, data)
		@fileData[id] = data
	end
	
	def setDataTable(data)
		@fileData = data
	end
end
