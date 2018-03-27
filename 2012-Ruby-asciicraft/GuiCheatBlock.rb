class GuiCheatBlock < Gui
    def initialize(ac)
        super(ac, "Block cheating menu")
        addItem(GuiItem.new("w", "Water source"))
		addItem(GuiItem.new("l", "Leaves"))
		addItem(GuiItem.new("a", "Air w/ Star"))
		addItem(GuiItem.new("s", "sapling"))
		addItem(GuiItem.new("!", "Spacetime Snapshot"))
        addItem(GuiItem.new("q", "Back"))
    end
    
    def tick
        sup.tick
        if @ac.lastKey == "w" then @ac.theWorld.thePlayer.setInventorySlot(0, BlockWater, 64) end
		if @ac.lastKey == "l" then @ac.theWorld.thePlayer.setInventorySlot(0, BlockLeaves, 64) end		
		if @ac.lastKey == "a" then @ac.theWorld.thePlayer.setInventorySlot(0, BlockAir, 64) end
		if @ac.lastKey == "s" then @ac.theWorld.thePlayer.setInventorySlot(0, BlockSapling, 64) end
		if @ac.lastKey == "!" then @ac.theWorld.thePlayer.setInventorySlot(0, BlockSpacetimeSnapshot, 64) end	
		if @ac.lastKey == "q" then
            @ac.switchGui(GuiIngame.new(@ac))        
		end	
    end
end
