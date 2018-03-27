class GuiCrash < Gui
    def initialize(ac, crashData, crashLocation)
        super(ac, "")
		@crashData = crashData
		@crashLocation = crashLocation
		@ac.log.log("asciicraft crashed! - Error details: " + "#{@crashData}")
		@ac.log.log("asciicraft crashed! - Error location: " + "#{@crashLocation}")
    	@crashGuis = []
		@crashGuis.push(GuiCrashBluescreen)
		@crashGuis.push(GuiCrashBootmanager)
		@crashGuis.push(GuiCrashLinuxPanic)
		@crashGui = @crashGuis[Random.new.rand(@crashGuis.length)].new(@ac, @crashData, @crashLocation)
	end
    
    def tick
		@crashGui.draw

		if @ac.lastKey.to_i != 0 then
			if @crashGuis[@ac.lastKey.to_i - 1] != nil then @crashGui = @crashGuis[@ac.lastKey.to_i - 1].new(@ac, @crashData, @crashLocation) end	
		elsif @ac.lastKey != nil then
			@ac.stop
		end
    end
end
