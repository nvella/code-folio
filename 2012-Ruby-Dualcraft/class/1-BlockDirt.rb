module Dualcraft
  class BlockDirt < Block
    def initialize(world)
      super(world, 3, 0, "block-dirt")
    end
  end
end

$dualcraft_blocks[3] = Dualcraft::BlockDirt
