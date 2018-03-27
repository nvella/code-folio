class GuiCrashBootmanager
	def initialize(ac, crashData, crashLocation)
		@ac = ac
		@crashData = crashData
		@crashLocation = crashLocation
	end

	def draw
		@ac.screen.width.times do |x|
			@ac.screen.height.times do |y|
				@ac.screen.setPixel(x, y, Pixel.new(" ", 124, 124))
			end
		end
		@ac.screen.drawText(0, 0, "ASCIICRAFT Error Error".center(@ac.screen.width), 247, 124)
		@ac.screen.drawText(0, @ac.screen.height - 2, " ANY KEY=Quit".ljust(@ac.screen.width), 247, 124)
		@ac.screen.drawText(0, 2, "ASCIICRAFT has experienced a problem.", 124, 247)
		@ac.screen.drawText(5, 6, "Status: ", 124, 247)
		@ac.screen.drawText(5, 10, "Info: ", 124, 247)
		@ac.screen.drawText(11, 10, @crashData.to_s, 124, 15)
		@ac.screen.drawText(0, 14, "You can try to recover ASCIICRAFT with a restart.", 124, 247)
		@ac.screen.drawText(0, 15, "(You might need to restart ASCIICRAFT manually.)", 124, 247)
	end
end
