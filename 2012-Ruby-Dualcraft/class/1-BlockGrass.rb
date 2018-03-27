module Dualcraft
  class BlockGrass < Block
    def initialize(world)
      super(world, 2, 0, "block-grass")
    end
  end
end

$dualcraft_blocks[2] = Dualcraft::BlockGrass
