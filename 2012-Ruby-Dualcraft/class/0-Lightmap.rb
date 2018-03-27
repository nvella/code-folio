module Dualcraft
  class Lightmap
    attr_accessor :map
    def initialize
      @map = []
      256.times do |x|
        @map[x] = []
        64.times do |y|
          @map[x][y] = 0
        end
      end
    end
  end
end
