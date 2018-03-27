class GuiMainmenu < Gui
    def initialize(ac)
        super(ac, ac.versionString)

		@pusleToggle = false
		@logoX = 0
		@ticksSinceLogoInc = 0 
		@middleY = @ac.screen.height / 2
		@quit = "[Q]UIT".center(@ac.screen.width)
		@new = "[N]EW WORLD".center(@ac.screen.width)
		@load = "[L]OAD world.gz".center(@ac.screen.width)
    end
    
	def drawLogo(x,y)#10        20        30        40        50
		#   01234567890123456789012345678901234567890123456789012345678
        # 0 ##### ##### ##### ##### ##### ##### ##### ##### ##### #####
		# 1 #   # #     #       #     #   #     #   # #   # #       #
		# 2 ##### ##### #       #     #   #     ##### ##### #####   #
		# 3 #   #     # #       #     #   #     #  #  #   # #       #
		# 4 #   # ##### ##### ##### ##### ##### #   # #   # #       #
		#
		
		5.times {|i| blotBox(x + i, y, 25)}
		5.times {|i| blotBox(x + 6 + i, y, 25)}
		5.times {|i| blotBox(x + 12 + i, y, 25)}
		5.times {|i| blotBox(x + 18 + i, y, 25)}
		5.times {|i| blotBox(x + 24 + i, y, 25)}
		5.times {|i| blotBox(x + 30 + i, y, 25)}
		5.times {|i| blotBox(x + 36 + i, y, 25)}
		5.times {|i| blotBox(x + 42 + i, y, 25)}
		5.times {|i| blotBox(x + 48 + i, y, 25)}
		5.times {|i| blotBox(x + 54 + i, y, 25)}

		blotBox(x, y + 1, 27)
		blotBox(x + 4, y + 1, 27)
		blotBox(x + 6, y + 1, 27)
		blotBox(x + 12, y + 1, 27)
		blotBox(x + 20, y + 1, 27)
		blotBox(x + 26, y + 1, 27)
		blotBox(x + 30, y + 1, 27)
		blotBox(x + 36, y + 1, 27)
		blotBox(x + 40, y + 1, 27)
		blotBox(x + 42, y + 1, 27)
		blotBox(x + 46, y + 1, 27)
		blotBox(x + 48, y + 1, 27)
		blotBox(x + 56, y + 1, 27)

		5.times {|i| blotBox(x + i, y + 2, 31)}
		5.times {|i| blotBox(x + 6 + i, y + 2, 31)}
		blotBox(x + 12, y + 2, 31)
		blotBox(x + 20, y + 2, 31)
		blotBox(x + 26, y + 2, 31)
		blotBox(x + 30, y + 2, 31)
		5.times {|i| blotBox(x + 36 + i, y + 2, 31)}
		5.times {|i| blotBox(x + 42 + i, y + 2, 31)}
		5.times {|i| blotBox(x + 48 + i, y + 2, 31)}
		blotBox(x + 56, y + 2, 31)

		blotBox(x, y + 3)
		blotBox(x + 4, y + 3)	
		blotBox(x + 10, y + 3)	
		blotBox(x + 12, y + 3)
		blotBox(x + 20, y + 3)
		blotBox(x + 26, y + 3)
		blotBox(x + 30, y + 3)
		blotBox(x + 36, y + 3)
		blotBox(x + 39, y + 3)
		blotBox(x + 42, y + 3)
		blotBox(x + 46, y + 3)
		blotBox(x + 48, y + 3)
		blotBox(x + 56, y + 3)

		blotBox(x, y + 4)
		blotBox(x + 4, y + 4)
		5.times {|i| blotBox(x + 6 + i, y + 4)}
		5.times {|i| blotBox(x + 12 + i, y + 4)}
		5.times {|i| blotBox(x + 18 + i, y + 4)}
		5.times {|i| blotBox(x + 24 + i, y + 4)}
		5.times {|i| blotBox(x + 30 + i, y + 4)}
		blotBox(x + 36, y + 4)
		blotBox(x + 40, y + 4)
		blotBox(x + 42, y + 4)
		blotBox(x + 46, y + 4)
		blotBox(x + 48, y + 4)
		blotBox(x + 56, y + 4)
		@ac.screen.drawText(x, y + 4, "By Nick", 256, 3)
	end

	def blotBox(x,y, colour = 32)
		@ac.screen.setPixel(x, y, Pixel.new(" ", colour, colour))
	end

    def tick
		#@ac.screen.drawText
		@ac.screen.width.times do |x|
			@ac.screen.width.times do |y|
				@ac.screen.setPixel(x, y, Pixel.new(" ", 15, 15))
			end
		end

		@ac.screen.drawText(0, @middleY - 1, @quit, 256, 32)
		@ac.screen.drawText(0, @middleY, @new, 256, 32)
		@ac.screen.drawText(0, @middleY + 1, @load, 256, 32)

		@ticksSinceLogoInc += 1
		if @ticksSinceLogoInc > 2 then
			@logoX += 1	
			@ticksSinceLogoInc = 0
		end
		if @logoX > (@ac.screen.width + 2) then @logoX = -59 end 
		drawLogo(@logoX,1)

        if @ac.lastKey == "n" then 
			@ac.switchGui(GuiCreateWorldSize.new(@ac))	
		end		
		if @ac.lastKey == "l" then 
			@ac.switchGui(GuiHUD.new(@ac))
			WorldSaveNexus.new(@ac, "world.gz").readFile						        
		end		
		if @ac.lastKey == "q" then @ac.stop end	
	end
end
