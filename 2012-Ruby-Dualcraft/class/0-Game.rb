module Dualcraft
  class Game < Gosu::Window
    attr_accessor :render_queue, :update_queue, :username, :textures, :music_enabled
    def initialize(username)
      super(800, 600, false)
      #super(1430, 820, false)
      #super(1440, 900, true)
      self.caption = "#{NAME} version #{VERSION}"
      @render_queue = []
      @update_queue = []
      @frames = 0
      @username = username
      @textures = {}
      @music_enabled = true
      
      puts("Loading textures...")
      Dir.entries("image").each do |image|
        if image.split(".")[1] == "png" then
          puts("  ./image/#{image}")
          name = image.split(".")[0]
          @textures[name] = Gosu::Image.new(self, "image/#{image}", true)
        end
      end
      
      if not Dir.exists?("worlds") then
        Dir.mkdir("worlds")
      end

      @info_mon = Gosu::Font.new(self, "arial", 24)
      
      @world = World.new
      @music_player = MusicPlayer.new(self, @world)
      @world.load_world
      @world_renderer = WorldRenderer.new(self, @world)
      @player_controller = PlayerController.new(self, @world, @world.current_player)
      @update_queue.push(@world, @world_renderer, @player_controller, @music_player)
      @render_queue.push(@world_renderer)
    end
    
    def update
      @frames += 1
      @update_queue.each {|obj| obj.update}
    end
    
    def draw
      @frames -= 1
      @render_queue.each {|obj| obj.draw}
      @info_mon.draw("#{@world.current_player.data["posX"]} #{@world.current_player.data["posY"]} f: #{@frames}", 0, 0, 0)
    end
    
    def button_down(id)
      if id == 65307 then close end
      @update_queue.each {|obj| obj.button_down(id)}
    end
    
    def needs_cursor?
      return true
    end
  end
end
