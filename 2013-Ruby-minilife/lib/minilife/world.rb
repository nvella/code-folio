module Minilife
  CELL_NEIGHBOURHOOD = [ [-1, 1],   [0, 1], [1, 1],
                         [-1, 0],           [1, 0],
                        [-1, -1],  [0, -1], [1, -1]]

  CELL_LIVE_CONDITIONS = [false, false, true, true, false, false, false, false]
  CELL_BORN_CONDITIONS = [false, false, false, true, false, false, false, false]

  class World
    include Tickable
    
    attr_accessor :running, :cells
    attr_reader :born_in_generation, :died_in_generation, :generations
    
    def initialize
      @cells = Set.new
      @generations = 0
      @born_in_generation = []
      @died_in_generation = []
    end
    
    def update
      @born_in_generation = []
      @died_in_generation = []
        
      new_cells = @cells.dup
      
      @cells.each do |cell|
        if not CELL_LIVE_CONDITIONS[cells_near(cell).length] then 
          @died_in_generation.push cell
          new_cells.delete cell 
        end
        
        CELL_NEIGHBOURHOOD.each do |state|
          ns = [cell[0] + state[0], cell[1] + state[1]]
          if CELL_BORN_CONDITIONS[cells_near(ns).length] and not new_cells.include? ns then
            @born_in_generation.push cell
            new_cells.add ns
          end
        end
      end
      
      @cells = new_cells
      @generations += 1
    end
    
    # Returns table of cells near square
    def cells_near cell
      near_cells = []
      CELL_NEIGHBOURHOOD.each do |state|
        c = [cell[0] + state[0], cell[1] + state[1]]
        if @cells.include? c then
          near_cells.push c
        end
      end
      return near_cells
    end
  end
end
