class GuiCreateWorldGenerator < Gui
    def initialize(ac, wwidth, wheight)
        super(ac, "Select world generator")
        @worldWidth = wwidth
        @worldHeight = wheight
		@world = World.new(@ac, @worldWidth, @worldHeight)  
        addItem(GuiItem.new("f", "Flatlands"))
        addItem(GuiItem.new("m", "Spanning Mountains"))
        addItem(GuiItem.new("q", "Back"))
    end
    
    def tick
        sup.tick
        if @ac.lastKey == "f" then 
			@ac.switchGui(GuiCreateWorldSeed.new(@ac, @world, 0))
		end		
		if @ac.lastKey == "m" then
			@ac.switchGui(GuiCreateWorldSeed.new(@ac, @world, 1))
		end		
		if @ac.lastKey == "q" then @ac.switchGui(GuiCreateWorldSize.new(@ac)) end
    end
end
