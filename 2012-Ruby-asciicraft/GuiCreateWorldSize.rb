class GuiCreateWorldSize < Gui
    def initialize(ac)
        super(ac, "Select world size")
        addItem(GuiItem.new("b", "Big - 128*128"))
        addItem(GuiItem.new("l", "Large - 256*128"))
        addItem(GuiItem.new("h", "Huge - 512*128"))
        addItem(GuiItem.new("c", "Bigger than Huge- 1024*128"))
		addItem(GuiItem.new("!", "meep - 8192*128"))
		addItem(GuiItem.new("#", "The end will never come - 16384*256"))
        addItem(GuiItem.new("q", "Back"))
    end
    
    def tick
        sup.tick
        case @ac.lastKey
            when "b" then @ac.switchGui(GuiCreateWorldGenerator.new(@ac, 128, 128))
            when "l" then @ac.switchGui(GuiCreateWorldGenerator.new(@ac, 256, 128))
            when "h" then @ac.switchGui(GuiCreateWorldGenerator.new(@ac, 512, 128))
            when "c" then @ac.switchGui(GuiCreateWorldGenerator.new(@ac, 1024, 128))
			when "!" then @ac.switchGui(GuiCreateWorldGenerator.new(@ac, 8192, 128))
			when "#" then @ac.switchGui(GuiCreateWorldGenerator.new(@ac, 16384, 256))
            when "q" then @ac.switchGui(GuiMainmenu.new(@ac))
        end
    end
end
