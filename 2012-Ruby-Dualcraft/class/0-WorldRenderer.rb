module Dualcraft
  class WorldRenderer
    include Tickable
    attr_accessor :startX, :startY
    
    def initialize(dc, world)
      @dc = dc
      @world = world
      @startX = @startY = 0
      @blockWidth = (@dc.width / 32).floor + 2
      @blockHeight = (@dc.height / 32).floor + 2
      @top_color = @bottom_color = 0
    end
    
    def update
      @startX = @startY = 0
      player = @world.current_player
      if player == nil then return end
      @startX = player.data["posX"] - (@blockWidth / 2).floor
      @startY = player.data["posY"] + (@blockHeight / 2).floor
      split = (36000.0 / FOG_COLOR.length.to_f).floor
      color_pair = FOG_COLOR[(@world.time.to_f / split).floor]
      if color_pair != nil then
        @color = FOG_COLOR[1]
      end
    end
    
    def draw
      @dc.draw_quad(0, 0, @color, # Top
                @dc.width, 0, @color, # Top
                0, @dc.height, @color, #bottom
                @dc.width, @dc.height, @color) #bottom

      @dc.translate(0 - (((@startX % 1)) * 32), -32 + (((@startY % 1)) * 32)) do
        @blockWidth.times do |x|
          @blockHeight.times do |y|
            blk = @world.get_block(@startX.floor + x, @startY.floor - y, 0)
            if blk != nil then 
              hd = @world.skylight.to_s(16)
              #@dc.textures[blk.texture].draw((x * 32) - (@startX % 1), (y * 32) - (@startY % 1), 0) # i <3 mod
              @dc.textures[blk.texture].draw((x * 32), (y * 32), 0, 1, 1, "0xfff#{hd}f#{hd}f#{hd}".to_i(16)) #i <3 mod
            end
          end
        end
      end
    end
  end
end   
