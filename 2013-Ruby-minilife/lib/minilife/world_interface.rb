module Minilife
  CELL_DRAW_SIZE = 128

  class WorldInterface
    include Tickable
    
    attr_reader :x, :y, :scale
    
    def initialize window, world
      @window = window
      @world = world
      
      @x = 0.0 # camera co-ords are floats so we can do some smooth camera stuff
      @y = 0.0
      
      @last_drag_x = nil
      @last_drag_y = nil
      
      @current_state = :nothing
      @zoom_original = 0
      
      @scroll_speed = 0.125
      @scale = 1
    end
    
    def draw_counter x, y, n
      number = n.to_s.rjust 6, '0'
      number.length.times do |i|
        @window.textures["number_#{number[i]}.png"].draw x + (i * 58), y, 0
      end
    end
    
    def button_down id
      case id
      when Gosu::MsLeft # Toggle cell
        @last_drag_x = mouse_cell_x
        @last_drag_y = mouse_cell_y
        
        toggle_cell
      when Gosu::MsWheelDown, Gosu::KbDown
        if @scale > 0.01 then
          @current_state = :zoom_out
          @zoom_original = @scale
        end
      when Gosu::MsWheelUp, Gosu::KbUp
        if @scale < 1 then
          @current_state = :zoom_in
          @zoom_original = @scale
        end
      end
    end
    
    def toggle_cell
      @window.sounds['click.ogg'].play @scale
    
      cell = [(@x + (@window.mouse_x / tile_width)).floor, (@y + (@window.mouse_y / tile_height)).floor]
        
      if @world.cells.include? cell then 
        @world.cells.delete cell
      else
        @world.cells.add cell
      end    
    end
    
    def mouse_cell_x
      (@x + (@window.mouse_x / tile_width)).floor
    end
    
    def mouse_cell_y
      (@y + (@window.mouse_y / tile_height)).floor
    end
    
    def tile_width
      (CELL_DRAW_SIZE * @scale).floor
    end
    
    def tile_height
      tile_width
    end
    
    def update
      if @window.button_down? Gosu::MsLeft and (@last_drag_x != mouse_cell_x or @last_drag_y != mouse_cell_y) then
        toggle_cell
        
        @last_drag_x = mouse_cell_x
        @last_drag_y = mouse_cell_y
      end
    
      if    @window.mouse_x <= 0 or @window.mouse_x >= @window.width - 1 then
        if @window.mouse_y >= @window.height / 2 then
          @y += ((1.0 / @window.height) * (@window.mouse_y - (@window.height / 2))) * (@scroll_speed * ((2 - @scale) * 3))
        else
          @y -= ((1.0 / @window.height) * ((@window.height / 2) - @window.mouse_y)) * (@scroll_speed * ((2 - @scale) * 3))
        end
        
        if @window.mouse_x <= 0 then
          @x -= @scroll_speed * ((2 - @scale) * 3)
        else
          @x += @scroll_speed * ((2 - @scale) * 3)
        end
      elsif @window.mouse_y <= 0 or @window.mouse_y >= @window.height - 1 then
        if @window.mouse_x >= @window.width / 2 then
          @x += ((1.0 / @window.width) * (@window.mouse_x - (@window.width / 2))) * (@scroll_speed * ((2 - @scale) * 3))
        else
          @x -= ((1.0 / @window.width) * ((@window.width / 2) - @window.mouse_x)) * (@scroll_speed * ((2 - @scale) * 3))
        end
        
        if @window.mouse_y <= 0 then
          @y -= @scroll_speed * ((2 - @scale) * 3)
        else
          @y += @scroll_speed * ((2 - @scale) * 3)
        end
      end
      
      case @current_state
      when :zoom_out
        @scale -= 0.02 * @scale
        
        if @scale < @zoom_original / 1.25 then
          @current_state = :nothing
        end
      when :zoom_in
        @scale += 0.02 * @scale
        
        if @scale > 1 then @scale = 1 end
        
        if @scale > @zoom_original * 1.25 then
          @current_state = :nothing
        end
      end
    end
    
    def tiles_wide
      (@window.width / tile_width) + 2 # + 1 so we can do some smooth camera stuff
    end
    
    def tiles_high
      (@window.height / tile_height) + 2 # + 1 so we can do some smooth camera stuff
    end
    
    def draw
      @window.draw_quad 0, 0, 0xff161616,
            @window.width, 0, 0xff161616,
           0, @window.height, 0xff161616,
       @window.width, @window.height, 0xff161616
    
      view_end_x = @x.floor + tiles_wide
      view_end_y = @y.floor + tiles_high

      if @scale > 0.1 then
        tiles_wide.times do |tile_x|
          tiles_high.times do |tile_y|
            @window.textures['cell_off.png'].draw (tile_x - (@x % 1)) * tile_width, (tile_y - (@y % 1)) * tile_height, 0, @scale, @scale
          end
        end
      end
      
      @world.cells.each do |cell|
        if cell[0] >= @x.floor and cell[0] <= view_end_x and cell[1] >= @y.floor and cell[1] <= view_end_y then
          draw_cell (cell[0] - @x) * tile_width, (cell[1] - @y) * tile_height, @scale
        end
      end
      
      @window.textures['icon_generations.png'].draw 4, 4, 0
      draw_counter 71, 4, @world.generations
      @window.textures['icon_population.png'].draw @window.width - (6 * 58) - 63, 4, 0
      draw_counter @window.width - (6 * 58) + 4, 4, @world.cells.length
    end
    
    def draw_cell x, y, scale
      c = 0xffeeeeee
      @window.draw_quad x, y, c, x + CELL_DRAW_SIZE * scale, y, c, x, y + CELL_DRAW_SIZE * scale, c, x + CELL_DRAW_SIZE * scale, y + CELL_DRAW_SIZE * scale, c
    end
  end
end
