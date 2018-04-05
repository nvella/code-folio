module RMCCLib
  class ObjectData
    include JavaStreamIO
    attr_accessor :int_field, :speed_x, :speed_y, :speed_z
    
    def initialize int_field = 0, speed_x = nil, speed_y = nil, speed_z = nil
      @int_field = int_field
      @speed_x = speed_x
      @speed_y = speed_y
      @speed_z = speed_z
    end
    
    def read stream
      @int_field = stream.read_int
      
      if @int_field != 0 then
        @speed_x = stream.read_short
        @speed_y = stream.read_short
        @speed_z = stream.read_short
      end
    end
    
    def write stream
      stream.write_int @int_field
      
      if @int_field != 0 then
        stream.write_int @speed_x
        stream.write_int @speed_y
        stream.write_int @speed_z
      end
    end
  end
end