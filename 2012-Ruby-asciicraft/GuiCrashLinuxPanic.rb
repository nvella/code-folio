class GuiCrashLinuxPanic
	def initialize(ac, crashData, crashLocation)
		@ac = ac
		@crashData = crashData
		@crashLocation = crashLocation
		@lines = []
		@actualLines = []
		18.times do
			@actualLines.push(@lines[Random.new.rand(@lines.length)])
		end
		@actualLines.push("panic: #{@crashData}")
	end

	def draw
		@ac.screen.width.times do |x|
			@ac.screen.height.times do |y|
				@ac.screen.setPixel(x, y, Pixel.new(" ", 0, 0))
			end
		end
		i = 0
		@actualLines.each do |line|
			@ac.screen.drawText(0, i, line, 0, 8)
			i += 1
		end

	end
end
