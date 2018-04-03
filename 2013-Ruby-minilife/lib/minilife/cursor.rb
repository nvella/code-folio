module Minilife
  class Cursor
    include Tickable
    
    def initialize window
      @window = window
      @window.mouse_x = (@window.width / 2) - 8
      @window.mouse_y = (@window.height / 2) - 8
    end
    
    def draw
      @window.textures['cursor.png'].draw @window.mouse_x - 8, @window.mouse_y - 8, 0
    end
  end
end