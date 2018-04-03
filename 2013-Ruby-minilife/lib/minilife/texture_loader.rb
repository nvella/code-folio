module Minilife
  include Tickable
  
  class TextureLoader
    attr_reader :done
  
    def initialize window
      @window = window
    
      @textures = Dir.entries("texture")
      @textures.delete "."
      @textures.delete ".."
      @done = false
    end
    
    def update
      texture = @textures.pop
      
      if texture == nil then 
        @done = true 
        return
      end
      
      if texture.split(".")[-1] == "png" then
        puts "Loading texture #{texture}..."
        @window.textures[texture] = Gosu::Image.new(@window, "texture/#{texture}")
      end
    end
  end
end