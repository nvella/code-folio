module RMCCLib
  class Block
    attr_accessor :id, :metadata, :block_light, :sky_light
  
    def initialize id = 0, metadata = 0, block_light = 0, sky_light = 0
      @id = id
      @metadata = metadata
      @block_light = block_light
      @sky_light = sky_light
    end
  end
end
