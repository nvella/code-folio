module Minilife
  module BlockSlide
    class BlockSlideUnit
      include Minilife::Tickable
    
      attr_accessor :color, :start_x, :start_y, :end_x, :end_y, :x, :y

      def initialize window, start_x, start_y, end_x, end_y, width = 40, height = 40, color = Gosu::Color.new(0xff000000)
        @window  = window
        @start_x = start_x
        @start_y = start_y
        @end_x   = end_x
        @end_y   = end_y
        @color   = color
        @x       = @start_x
        @y       = @start_y
        @width   = width
        @height  = height
      end

      def update
        if @x < @end_x then
          @x += ((@end_x - @x) / 12)
        elsif @x > @end_x then
          @x -= ((@end_x + @x) / 12)
        end

        if @y < @end_y then
          @y += ((@end_y - @y) / 12)
        elsif @y > @end_y then
          @y -= ((@end_y + @y) / 12)
        end
      end

      def draw
        @window.draw_quad(@x.floor, @y.floor             , color,
                 @x.floor + @width, @y.floor             , color,
                          @x.floor, @y.floor + @height   , color,
                 @x.floor + @width, @y.floor + @height   , color)  
      end
    end

    class BlockSlideManager
      include Minilife::Tickable
    
      attr_accessor :color, :bg_color, :blocks
      
      def initialize window, blocks, start_x, end_x, y, color
        @window = window
        @blocks = []
        @y = y
        blocks.length.times do |lY|
          blocks[0].length.times do |lX|
            if blocks[lY][lX] == "#" then
              @blocks.push BlockSlideUnit.new(window, (start_x + (lX * 50)) - (lY * 50), y + (lY * 40), end_x + (lX * 40), y + (lY * 40), 40, 40, Gosu::Color.new(color))
            end
          end
        end          
      end
      
      def update
        @blocks.each {|obj| obj.update}
      end

      def draw
        @blocks.each {|obj| obj.draw}
      end
    end
  end
end
