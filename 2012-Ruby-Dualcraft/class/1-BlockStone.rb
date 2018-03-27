module Dualcraft
  class BlockStone < Block
    def initialize(world)
      super(world, 1, 0, "block-stone")
    end
  end
end

$dualcraft_blocks[1] = Dualcraft::BlockStone
