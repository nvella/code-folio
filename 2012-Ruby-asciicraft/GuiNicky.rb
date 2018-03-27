class GuiNicky < Gui
    def initialize(ac)
        super(ac, "")
		@ticks = 0
		@asciiArt = """
      ___                       ___           ___                 
     /__/\        ___          /  /\         /__/|    
     \  \:\      /  /\        /  /:/        |  |:|      
      \  \:\    /  /:/       /  /:/         |  |:|      
  _____\__\:\  /__/::\      /  /:/  ___   __|  |:|       
 /__/::::::::\ \__\/\:\__  /__/:/  /  /\ /__/\_|:|____   
 \  \:\~~\~~\/    \  \:\/\ \  \:\ /  /:/ \  \:\/:::::/  
  \  \:\  ~~~      \__\::/  \  \:\  /:/   \  \::/~~~~   
   \  \:\          /__/:/    \  \:\/:/     \  \:\         
    \  \:\         \__\/      \  \::/       \  \:\         
     \__\/                     \__\/         \__\/                				

		"""
    end
    
    def tick
        sup.tick
		@ac.screen.drawText(1,0,"Made by Nick", 0, 7)
		@ac.screen.drawText(1,2,"Uses Zlib for gzip compression of worlds", 0, 7)
		@ac.screen.drawText(1,3,"Thanks to roflbalt for inspiration", 0, 7)        

		@ticks += 1
		if @ac.lastKey != nil or @ticks >= 40 then
			@ac.switchGui(GuiMainmenu.new(@ac))
		end
    end
end
