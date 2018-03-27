class GuiHUD < Gui
    def initialize(ac)
        super(ac, "")
    end
    
    def tick
		case @ac.lastKey 
		when "w" 
			@ac.theWorld.thePlayer.setDirection(0)
		when "d" 
			@ac.theWorld.thePlayer.setDirection(1)
		when "s" 
			@ac.theWorld.thePlayer.setDirection(2)
		when "a" 
			@ac.theWorld.thePlayer.setDirection(3)
		when "[" 
			@ac.theWorld.thePlayer.moveForward
        when "]"
			@ac.theWorld.thePlayer.placeBlock
		when "p"
			@ac.theWorld.thePlayer.breakBlock
        when "\e"
			@ac.switchGui(GuiIngame.new(@ac))
		when "e"
			@ac.theWorld.thePlayer.setCurrentInventorySlot(@ac.theWorld.thePlayer.currentInventorySlot + 1)
			if @ac.theWorld.thePlayer.currentInventorySlot >= 8 then @ac.theWorld.thePlayer.setCurrentInventorySlot(0) end		
		when " "
			@ac.theWorld.thePlayer.jump		
		when "`"
			@ac.theWorld.rollback(8)	
		when "!"
			(@ac.theWorld.blockLog.length / 8).times do
				@ac.theWorld.rollback(8)
				@ac.save
				%x{ruby 'asciimap/asciimapanimate.rb' 'world.gz'}
			end
			
		end

		renderInventory
		renderHealthbar
		renderTimescale
		renderCoords
    end

	def renderCoords
		@ac.screen.drawText(50,19,"x: #{@ac.theWorld.thePlayer.x} - y: #{@ac.theWorld.thePlayer.y}", 0, 1)
	end

	def renderHealthbar
		if @ac.theWorld.thePlayer.health < 3 then		
			fgCol = 1
		else
			fgCol = 2
		end
 
		@ac.screen.drawText(0,19,"Health: ", 0, fgCol)
		if not @ac.theWorld.thePlayer.health < 0 then		
			@ac.theWorld.thePlayer.health.times do |n|
				@ac.screen.drawText(8 + n, 19, " ", fgCol, fgCol)
			end
		end
	end

	def renderTimescale
		@ac.screen.drawText(20,19,"Time: " + @ac.theWorld.time.to_s + " Timeunit: " + @ac.theWorld.blockLog.length.to_s, 0, 1)
	end

	def renderInventory
		8.times do |n|
			s = n * 4
			if @ac.theWorld.thePlayer.getInventorySlot(n)[0] != nil then
				@ac.screen.setPixel(s, 20, @ac.theWorld.thePlayer.getInventorySlot(n)[0].new(@ac.theWorld, 0, 0).getPixel)
				if @ac.theWorld.thePlayer.getInventorySlot(n)[1] < 10 then @ac.screen.drawText(s + 2, 20, @ac.theWorld.thePlayer.getInventorySlot(n)[1].to_s, 0, 7)
                else @ac.screen.drawText(s + 1, 20, @ac.theWorld.thePlayer.getInventorySlot(n)[1].to_s, 0, 7) end
			end			
			if @ac.theWorld.thePlayer.currentInventorySlot == n then
				@ac.screen.setPixel(s + 3, 20, Pixel.new("<", 1, 7))
			else
				@ac.screen.setPixel(s + 3, 20, Pixel.new("|", 0, 7))
			end		
		end
	end
end
