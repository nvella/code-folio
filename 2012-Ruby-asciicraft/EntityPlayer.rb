class EntityPlayer < Entity
    attr_reader :direction, :currentInventorySlot
    
    def initialize(world)
        super(world)
        @direction = 0
        @reachDistance = 8
		@timeSinceLastBreak = 0
		@inventory = []
		@currentInventorySlot = 0
		8.times do |x|
			@inventory[x] = []
            @inventory[x][1] = 0
		end
    end

	def setInventorySlot(number, block, count)
		@inventory[number][0] = block
		@inventory[number][1] = count
	end

	def setCurrentInventorySlot(number)
		@currentInventorySlot = number
	end

	def getInventorySlot(number)
		return @inventory[number]
	end
    
    def tick
		if @health == 500 then
			return
		end

		if @timeSinceLastBreak > 0 then @timeSinceLastBreak -= 1 end

		sup.tick
       
    end
    
    def placeBlock
        if getInventorySlot(@currentInventorySlot)[0] == nil then return end
    
        @reachDistance.times do |n|
			case @direction
		        when 0
					ay = @y - n
		            ay += 1
		            if not @world.getBlock(@x, @y - n).noclip? and @world.getBlock(@x, ay).id == 0 then
						if @world.getBlock(@x, @y - n).canBeUsed? then 
							@world.getBlock(@x, @y - n).use(self)     
							break
						end   
						if n > 1 then   
	  						b = getInventorySlot(@currentInventorySlot)[0].new(@world, 0, 0)
				            b.setPosition(@x, ay)
							@world.setBlock(@x, ay, b)
							decreaseInventory
				            break
						end
		            end
		        when 1
					ax = @x + n
		            ax -= 1
		            if not @world.getBlock(@x + n, @y).noclip? and @world.getBlock(ax, @y).id == 0 then
						if @world.getBlock(@x + n, @y).canBeUsed? then 
							@world.getBlock(@x + n, @y).use(self)     
							break
						end  
						if n > 1 then
				            b = getInventorySlot(@currentInventorySlot)[0].new(@world, 0, 0)
				            b.setPosition(ax, @y)
				            @world.setBlock(ax, @y, b)
							decreaseInventory                        
							break
						end
		            end
		            when 2
		                ay = @y + n
		                ay -= 1
		                if not @world.getBlock(@x, @y + n).noclip? and @world.getBlock(@x, ay).id == 0 then
							if @world.getBlock(@x, @y + n).canBeUsed? then 
								@world.getBlock(@x, @y + n).use(self)     
								break
							end  
							if n > 1 then
				                b = getInventorySlot(@currentInventorySlot)[0].new(@world, 0, 0)
				                b.setPosition(@x, ay)
								@world.setBlock(@x, ay, b)
				                decreaseInventory
				                break
							end
		                end
		            when 3
		                ax = @x - n
		                ax += 1
		                if not @world.getBlock(@x - n, @y).noclip? and @world.getBlock(ax, @y).id == 0 then
							if @world.getBlock(@x - n, @y).canBeUsed? then 
								@world.getBlock(@x - n, @y).use(self)     
								break
							end  
							if n > 1 then
				                b = getInventorySlot(@currentInventorySlot)[0].new(@world, 0, 0)
				                b.setPosition(ax, @y)
				                @world.setBlock(ax, @y, b)
				                decreaseInventory
							    break
							end
			            end
			end
		end    
    end
    
    def decreaseInventory
        if getInventorySlot(@currentInventorySlot)[1] == 1 then
            @inventory[@currentInventorySlot][0] = nil
            @inventory[@currentInventorySlot][1] = 0
        else
            setInventorySlot(@currentInventorySlot, getInventorySlot(@currentInventorySlot)[0], getInventorySlot(@currentInventorySlot)[1] - 1)
        end
    end

	def putBlockIntoInventory(b)
		if b.new(@world, 0, 0).getDrop == nil then return end
        8.times do |n|
			if getInventorySlot(n)[0] != nil then #This prevents the game from throwing a nil exception when trying to compare nil.getDrop.id and b.getDrop.id
		        if b.new(@world, 0, 0).getDrop.id == getInventorySlot(n)[0].new(@world, 0, 0).getDrop.id and getInventorySlot(n)[1] < 64 then
		            setInventorySlot(n, b.new(@world, 0, 0).getDrop.class, getInventorySlot(n)[1] + 1)
		            return true
		        end
			end
        end
		
		8.times do |n|
		    if getInventorySlot(n)[0] == nil then
                setInventorySlot(n, b.new(@world, 0, 0).getDrop.class, getInventorySlot(n)[1] + 1)
                return true            
            end
		end
        
        return false
	end

    def breakBlock
		if @timeSinceLastBreak > 0 then return end
		@timeSinceLastBreak = 4
        @reachDistance.times do |n|
            case @direction
                when 0
                    if not @world.getBlock(@x, @y - n).noclip? then
						if not @world.getBlock(@x, @y - n).canBreak? then break end                        
						putBlockIntoInventory(@world.getBlock(@x, @y - n).class)
                        b = BlockAir.new(@world, @x, @y - n)                        
						@world.setBlock(@x, @y -n, b)
                        break
                    end
                when 1
                    if not @world.getBlock(@x + n, @y).noclip? then
						if not @world.getBlock(@x + n, @y).canBreak? then break end
                        putBlockIntoInventory(@world.getBlock(@x + n, @y).class)
                        b = BlockAir.new(@world, @x + n, @y)
                        @world.setBlock(@x + n, @y, b)
                        break
                    end
                when 2
                    if not @world.getBlock(@x, @y + n).noclip? then
						if not @world.getBlock(@x, @y + n).canBreak? then break end
                        putBlockIntoInventory(@world.getBlock(@x, @y + n).class)
                        b = BlockAir.new(@world, @x, @y + n)
                        @world.setBlock(@x, @y + n, b)
                        break
                    end
                when 3
                    if not @world.getBlock(@x - n, @y).noclip? then
						if not @world.getBlock(@x - n, @y).canBreak? then break end
                        putBlockIntoInventory(@world.getBlock(@x - n, @y).class)
                        b = BlockAir.new(@world, @x - n, @y)
                        @world.setBlock(@x - n, @y, b)
                        break
                    end
            end
		end
    end
    
	def moveForward
		case @direction
			when 1 then setPosition(@x + 1, @y)
			when 3 then setPosition(@x - 1, @y)
		end
	end
    
    def setDirection(direction)
        @direction = direction
    end
    
    def getPixel
		if @health == 500 then return Pixel.new("~", 0, 0) end

    	bg = 252
		fg = 0
    
		case @direction
			when 0 then return Pixel.new("^", bg, fg)
		    when 1 then return Pixel.new(">", bg, fg)
		    when 2 then return Pixel.new("v", bg, fg)
		 	when 3 then return Pixel.new("<", bg, fg)
        end
    end

	def respawn
		setHealth(10)
		setPosition(@world.spawnX,@world.spawnY)
	end
end
