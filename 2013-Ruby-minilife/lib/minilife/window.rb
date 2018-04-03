module Minilife
  class Window < Gosu::Window
    attr_accessor :update_queue, :draw_queue, :current_screen, :background_color, :sounds, :textures, :songs, :cursor
    alias :original_show :show
  
    def initialize
      super Gosu.screen_width, Gosu.screen_height, true # Create a new window, fullscreen, with the computer's resolution.
      
      @background_color = 0xffffffff
      @current_screen = IntroScreen.new self
      
      @sounds = {}
      @textures = {}
      @songs = [] # use array for songs because they are randomly picked.
      
      @cursor = Cursor.new self
      
      @update_queue = [@current_screen]
      @draw_queue = [@current_screen]
    end
    
    def button_down id
      if id == Gosu::KbEscape then close end
      
      @update_queue.each {|obj| obj.button_down id}
    end
    
    def show
      Thread.abort_on_exception = true
    
      Thread.new do 
        while not @current_screen.logo_stage_finished? do sleep 0.5 end
        
        load_resources
        
        @update_queue.delete @current_screen
        @draw_queue.delete @current_screen
        
        @current_screen = SlideDownScreen.new self, 0xff000000
        @update_queue.push @current_screen, @cursor
        @draw_queue.push @current_screen, @cursor
        
        
        while @current_screen.ticks < height / 80 do sleep 0.5 end
        
        @current_screen = MainScreen.new self
        
        @update_queue = [@current_screen, @cursor]
        @draw_queue   = [@current_screen, @cursor] # Blank the queues
      end
      
      original_show
    end
    
    def load_resources
      CLASSES.each do |file|
        require_relative file #relative to window.rb here
      end
    
      Dir.entries("sound").each do |sound|
        if sound.split(".")[-1] == "ogg" then
          puts "Loading sound #{sound}..."
          @sounds[sound] = Gosu::Sample.new(self, "sound/#{sound}")
        end
      end  
      
      texture_loader = TextureLoader.new self
      @update_queue.push texture_loader
      
      while not texture_loader.done do sleep 0.5 end
      
      @update_queue.delete texture_loader
    end
    
    def update
      begin
        @update_queue.each {|obj| obj.update}
      rescue
        raise "crash (in update): #{$!} @ #{$@}"
      end
    end

    def draw
      draw_quad 0, 0, @background_color,
            width, 0, @background_color,
           0, height, @background_color,
       width, height, @background_color
      
      begin
        @draw_queue.each {|obj| obj.draw}
      rescue
        raise "crash (in render): #{$!} @ #{$@}"
      end
    end
  end
end
