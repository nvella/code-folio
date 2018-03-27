class GuiCrashBluescreen
	def initialize(ac, crashData, crashLocation)
		@ac = ac
		@crashData = crashData
		@crashLocation = crashLocation
	end

	def draw
		errorString = "Error details: #{@crashData}"
		titleX = (@ac.screen.width / 2) - ("ASCIICRAFT".length / 2)
		commandX = (@ac.screen.width / 2) - ("Press any key to continue".length / 2)

		@ac.screen.width.times do |x|
			@ac.screen.height.times do |y|
				@ac.screen.setPixel(x, y, Pixel.new(" ", 4, 4))
			end
		end
		@ac.screen.drawText(titleX, (@ac.screen.height / 2) - 6, "ASCIICRAFT", 247, 4)
		@ac.screen.drawText(5, (@ac.screen.height / 2) - 4, "An error has occurred. To continue:", 4, 15)
		@ac.screen.drawText(5, (@ac.screen.height / 2) - 2, "Press any key to return to a prompt, or", 4, 15)
		@ac.screen.drawText(5, (@ac.screen.height / 2), "Press any key to return to a prompt. If you do this,", 4, 15)
		@ac.screen.drawText(5, (@ac.screen.height / 2) + 1, "you will lose any unsaved progress in the currently opened world.", 4, 15)
		@ac.screen.drawText(5, (@ac.screen.height / 2) + 3, errorString, 4, 15)
		@ac.screen.drawText(commandX, (@ac.screen.height / 2) + 5, "Press any key to continue", 4, 15)
		
	end
end
