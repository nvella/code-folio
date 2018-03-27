class GuiIngame < Gui
    def initialize(ac)
        super(ac, "Game paused")
        addItem(GuiItem.new("ESCAPE", "Resume"))
		addItem(GuiItem.new("c", "Cheats"))
		addItem(GuiItem.new("r", "Render and display (requires rmagick)"))
        addItem(GuiItem.new("q", "Save and quit"))
    end
    
    def tick
        sup.tick
        @ac.pause
        if @ac.lastKey == "\e" then 
			@ac.switchGui(GuiHUD.new(@ac))
			@ac.unpause
		end
        if @ac.lastKey == "c" then 
			@ac.switchGui(GuiCheatBlock.new(@ac))
		end			
		if @ac.lastKey == "q" then
            @ac.save
            @ac.switchWorld(nil)
			@ac.unpause
			@ac.switchGui(GuiMainmenu.new(@ac))		        
		end	

		if @ac.lastKey == "r" then
			@ac.save
			%x{ruby 'asciimap/asciimap.rb' 'world.gz'}
		end
    end
end
