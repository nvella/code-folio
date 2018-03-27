module Dualcraft
  class PlayerController
    include Tickable
    attr_writer :player

    def initialize(dc, world, player)
      @dc = dc
      @world = world
      @player = player
      @blocks_fit_width = @dc.width / 32 # Blocks that can fit on screen
      @blocks_fit_height = @dc.height / 32 # 
      @buttons_down = Hash["w", false, "a", false, "s", false, "d", false]
    end

    def tick
      if @buttons_down["w"] then
        @player.data["posY"] += 0.2
      elsif @buttons_down["a"] then
        @player.data["posX"] -= 0.2    
      elsif @buttons_down["s"] then
        @player.data["posX"] -= 0.2
      elsif @buttons_down["d"] then
        @player.data["posX"] += 0.2
      end
    end

    def button_down(id)
      puts(id)
      if id == 65536 then
        if @player == nil then return end
        
        # CLICKED:
        #   Origin of co-ords is in bottom left
        
        clicked_x = @dc.mouse_x
        clicked_y = @dc.height - @dc.mouse_y
        
        x = (@player.data["posX"] - ((@dc.width / 32) / 2)) + clicked_x
        y = (@player.data["posY"] + ((@dc.width / 32) / 2)) + clicked_y
        
        puts("#{x}:#{y}")
        @world.set_block(x.floor, y.floor, 0, nil)
      end

      if id == 65537 then
        @player.data["velX"] += 0.01
        @player.data["velY"] += 8
      end

      if id == 65538 then
        @player.data["velX"] -= 0.01
        @player.data["velY"] += 8
      end

      if id == 116 then
        @world.time += (DAY_LENGTH.to_f / 20).floor
        if @world.time > DAY_LENGTH then
          @world.time = 0
        end
        puts(@world.skylight)
      end
      
      @buttons_down.each {|k, v| @buttons_down[k] = false}
      case id
      when Gosu::Window.char_to_button_id("w")
        @buttons_down["w"] = true
      when Gosu::Window.char_to_button_id("s")
        @buttons_down["s"] = true
      when Gosu::Window.char_to_button_id("a")
        @buttons_down["a"] = true
      when Gosu::Window.char_to_button_id("d")
        @buttons_down["d"] = true
      end
    end
  end
end
