module RNM
  class GOLWorld
    NEIGHBOURS = [[-1, -1], [0, -1], [1, -1], [-1, 0], [1, 0], [-1, 1], [0, 1], [1, 1]]

    attr_accessor :cells, :live, :born
    attr_reader :ticks
      
    def initialize live = [2, 3], born = 3
      @cells = Set.new
      @live = live
      @born = born
      @ticks = 0
    end
    
    def tick
      new_cells = @cells.dup
      @cells.each do |pos|
        if not @live.include? get_neighbours(pos[0], pos[1]) then
          new_cells.delete pos
        end
        NEIGHBOURS.each do |rel_pos|
          x = pos[0] + rel_pos[0]
          y = pos[1] + rel_pos[1]
          if get_neighbours(x, y) == @born then
            new_cells.add [x, y]
          end
        end 
      end
      @cells = new_cells
      @ticks += 1
    end
    
    def get_neighbours x, y
      neighbours = 0
      NEIGHBOURS.each do |rel_x, rel_y|
        if @cells.include? [x + rel_x, y + rel_y] then neighbours += 1 end
      end
      return neighbours
    end

    # Centers to 0, 0
    def centered
      new_cells = Set.new
      if @cells.length > 0 then
        lowest_x = @cells.to_a[0][0]
        lowest_y = @cells.to_a[0][1]
        @cells.each do |pos|
          if pos[0] < lowest_x then lowest_x = pos[0] end
          if pos[1] < lowest_y then lowest_y = pos[1] end
        end
      
        new_cells = @cells.deep_clone
        new_cells.each do |pos|
          pos[0] -= lowest_x
          pos[1] -= lowest_y
        end
      end
      
      centered_world = GOLWorld.new
      centered_world.cells = new_cells
      return centered_world
    end
    
    def size
      s = [0, 0]
      centered.cells.each do |pos|
        if pos[0] > s[0] then s[0] = pos[0] end
        if pos[1] > s[1] then s[1] = pos[1] end
      end
      return s
    end
  end
end
