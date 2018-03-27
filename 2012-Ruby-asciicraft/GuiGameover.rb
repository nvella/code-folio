class GuiGameover < Gui
    def initialize(ac)
        super(ac, "Game over!")
        addItem(GuiItem.new("r", "Respawn"))
        addItem(GuiItem.new("q", "Save and Quit"))
    end
    
    def tick
        sup.tick
        if @ac.lastKey == "r" then 
            @ac.switchGui(GuiHUD.new(@ac)) 
            @ac.theWorld.thePlayer.respawn
        end
        if @ac.lastKey == "q" then 
            @ac.save
            @ac.switchWorld(nil)
            @ac.switchGui(GuiMainmenu.new(@ac))
        end
    end
end
