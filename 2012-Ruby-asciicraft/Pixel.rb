class Pixel
    attr_reader :char, :bg, :fg, :intense

    def initialize(char, bg, fg, intense=false)
        @char = char
        @bg = bg
        @fg = fg
		@intense = intense
    end
    
    def stringRep
        return "\033[48;5;#{@bg.to_s}m\033[38;5;#{@fg.to_s}m#{@char}\033[0m"
    end
end
