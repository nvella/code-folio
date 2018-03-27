class Screen
	attr_reader :width, :height
    def initialize(w,h)
		@width = w
		@height = h
		createBlankTable(w,h)
		%x{stty -icanon -echo}
        @modified = false
		printf "\033[0m" # reset
    	printf "\033[2J" # clear screen
    	printf "\x1B[?25l" # disable cursor
	end

	def debug
		File.open("screendebug.dump", "w") do |file|
			@height.times do |y|
				@width.times do |x|
					file.write(@screenTable[x][y].stringRep)
		            file.write("\033[0m")
				end
		        file.write("\n")
			end
		end
	end

	def exit
    	printf "\033[0m" # reset colours
    	printf "\x1B[?25h" # re-enable cursor
    	printf "\n"
		%x{reset}
  	end

	def createBlankTable(w,h)
		@screenTable = []
		w.times do |x|
			@screenTable[x] = []
			h.times do |y|
				@screenTable[x][y] = Pixel.new(" ", 0, 0)
			end
		end
	end

	def render
        if not @modified then return false end
		printf "\e[H"		

		@height.times do |y|
			@width.times do |x|
				printf @screenTable[x][y].stringRep
			end
            puts ""
		end
        @modified = false
		createBlankTable(@width, @height)
        return true
	end

	def setPixel(x,y,pixel)#x,y,c,bg,fg)
		if x >= @width or y >= @height then return false end
		if x < 0 or y < 0 then return false end
        @modified = true
        @screenTable[x][y + 1] = pixel
	end
    
    def drawText(x,y,s,bg,fg)
		if x >= @width or y >= @height then return false end
		if x < 0 or y < 0 then return false end
		if bg == 256 then bg = @screenTable[x][y].bg end
        a = s.split("")
        i = 0
        a.each do |b|
            setPixel(x + i, y, Pixel.new(b, bg, fg))
            i += 1
        end
    end
end
