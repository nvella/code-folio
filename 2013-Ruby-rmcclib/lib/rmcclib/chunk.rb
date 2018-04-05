module RMCCLib
  class Chunk
    def initialize
      @data = []
      16.times do |x|
        @data[x] = []
        16.times do |y|
          @data[x][y] = []
          16.times do |z|
            @data[x][y][z] = Block.new
          end
        end
      end
    end

    def [] x
      @data[x]
    end
  end
end