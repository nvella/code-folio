module Minilife
  class SlideDownScreen
    include Tickable
    
    attr_reader :ticks
  
    def initialize window, color
      @window = window
      @ticks = 0
      @color = color
    end
    
    def update
      @ticks += 1
    end
    
    def draw
      y = @window.height - (@ticks * 80)
      @window.draw_quad(0, y, @color,
                  @window.width, y, @color,
                  0, @window.height, @color,
                  @window.width, @window.height, @color) 
                  
    end
  end
end