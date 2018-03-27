class GuiCreateWorldSeed < Gui
    def initialize(ac, world, generator)
        super(ac, "Enter seed")
        @generator = generator
		@world = world
		@seed = @world.seed.to_s
        addItem(GuiItem.new("ENTER", "Accept"))
        addItem(GuiItem.new("ESCAPE", "Back"))
    end
    
    def tick
        sup.tick
        if @ac.lastKey == "\n" then 
			@world.seed = @seed.to_i
			if @generator == 0 then LandscapeGenFlat.new(@world).generate
			else LandscapeGenSpanningMountains.new(@world).generate end
			runWorld
		elsif @ac.lastKey == "\e" then @ac.switchGui(GuiCreateWorldGenerator.new(@ac, @world.width, @world.height))
		elsif @ac.lastKey == "\b" or @ac.lastKey == 127.chr then
			if @seed.length > 0 then @seed[@seed.length - 1] = "" end
		elsif @ac.lastKey != nil
			@seed[@seed.length] = @ac.lastKey
		end

		@ac.screen.drawText(1, 9, @seed, 8, 0)
    end

	def runWorld
		@ac.switchWorld(@world)
		@world.thePlayer.respawn
        @ac.switchGui(GuiHUD.new(@ac))		
	end
end
