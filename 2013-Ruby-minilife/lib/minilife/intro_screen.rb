module Minilife
  class IntroScreen
    include Tickable
  
    def initialize window
      @window = window
      @block_slide = BlockSlide::BlockSlideManager.new(@window, [
        "##### #        ",
        "#   #   ### # #",
        "#   # # #   ## ",
        "#   # # ### # #"],
      -1024, (@window.width / 2) - 300 , (@window.height / 2).floor - 80, 0xff0096ff)
      @sliding_thing_width = 768
      @sliding_thing_x = -@sliding_thing_width
    end
    
    def logo_stage_finished?
      (@block_slide.blocks[0].end_x - @block_slide.blocks[0].x) <= 11
    end
    
    def update
      @block_slide.update
      if logo_stage_finished? then
        @sliding_thing_x += 32
        if @sliding_thing_x > @window.width then
          @sliding_thing_x = -@sliding_thing_width
        end
      end
    end
    
    def draw
      @block_slide.draw
      sliding_thing_color = 0xff0096ff
      @window.draw_quad(@sliding_thing_x, @window.height - 10, sliding_thing_color,
                        @sliding_thing_x + @sliding_thing_width, @window.height - 10, sliding_thing_color,
                        @sliding_thing_x, @window.height, sliding_thing_color,
                        @sliding_thing_x + @sliding_thing_width, @window.height, sliding_thing_color)
    end
  end
end
