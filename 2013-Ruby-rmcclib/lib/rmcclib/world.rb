module RMCCLib
  class World
    attr_reader :dimension_id
    attr_accessor :level_type, :chunk_columns, :entities
  
    def initialize dimension_id = 0, level_type = "default"
      @dimension_id = dimension_id
      @level_type = level_type
      @chunk_columns = {}
      @entities = {}
    end
    
    def get_block x, y, z
      col_x = x / 16
      col_z = z / 16
      x = x % 16
      z = z % 16
      
      if @chunk_columns[[col_x, col_z]] == nil then
        nil
      else
        @chunk_columns[[col_x, col_z]].get_block x, y, z
      end
    end
    
    def set_block x, y, z, b
      col_x = x / 16
      col_z = z / 16
      x = x % 16
      z = z % 16
      
      if @chunk_columns[[col_x, col_z]] == nil then
        nil
      else
        @chunk_columns[[col_x, col_z]].set_block x, y, z, b
      end      
    end
    
    def merge_into world
      @chunk_columns.each {|pos, column| world.chunk_columns[pos] = column}
      @entities.each {|entity_id, entity| world.entities[entity_id] = entity}
    end
  end
end
