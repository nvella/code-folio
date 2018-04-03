module Minilife
  class MainScreen
    include Tickable
  
    def initialize window
      @window = window
    
      new_game
      
      @ticks = 0
    end
    
    def new_game
      @world = World.new
      @world_interface = WorldInterface.new @window, @world
      @running = false
      
      @current_state = :start
      @overlay_color = Gosu::Color.new 0xff000000 
    end
    
    def simulate_world
      if @world.cells.length == 0 then
        @window.sounds['error.ogg'].play
        @running = false
        return
      end
    
      @world.update
      
      @world.born_in_generation.each do |cell|
        if cell[0] >= @world_interface.x.floor and cell[1] >= @world_interface.y.floor and cell[0] <= @world_interface.x.floor + @world_interface.tiles_wide and cell[1] <= @world_interface.y + @world_interface.tiles_high then
          @window.sounds['yes.ogg'].play @world_interface.scale
          break
        end
      end
      
      @world.died_in_generation.each do |cell|
        if cell[0] >= @world_interface.x.floor and cell[1] >= @world_interface.y.floor and cell[0] <= @world_interface.x.floor + @world_interface.tiles_wide and cell[1] <= @world_interface.y + @world_interface.tiles_high then
          @window.sounds['no.ogg'].play @world_interface.scale
          break
        end
      end      
    end
    
    def button_down id
      @world_interface.button_down id
      
      case id
      when Gosu::KbReturn
        @running = !@running
      when Gosu::KbN
        new_game
      when Gosu::KbSpace
        simulate_world
      end
    end
    
    def update
      if @running then simulate_world end
      @world_interface.update
    
      case @current_state
      when :start
        @window.sounds["new-game.ogg"].play
        @window.background_color = 0xff00ff00
        @current_state = :fade_in
      when :fade_in
        @overlay_color.alpha -= 2
      
        if @overlay_color.alpha >= 255 then @current_state = :nothing end
      end
          
      @ticks += 1
    end
    
    def draw
      @world_interface.draw
      
      c = 0xa0000000
      @window.textures['vignette.png'].draw_as_quad 0, 0, c, @window.width, 0, c, 0, @window.height, c, @window.width, @window.height, c, 0

      @window.draw_quad 0, 0, @overlay_color,
            @window.width, 0, @overlay_color,
           0, @window.height, @overlay_color,
       @window.width, @window.height, @overlay_color
    end  
  end
end
