module BlockList
    def getBlockForID(id)
        if id == 0 then return BlockAir end #.new(world, 0,0,id,0) end
        if id == 1 then return BlockStone end #.new(world, 0,0,id,0) end
		if id == 2 then return BlockGrass end #.new(world, 0,0,id,0) end
        if id == 3 then return BlockDirt end #.new(world, 0,0,id,0) end
		if id == 4 then return BlockBedrock end #.new(world, 0,0,id,0) end
		if id == 5 then return BlockLog end #.new(world, 0,0,id,0) end
		if id == 6 then return BlockLeaves end #.new(world, 0,0,id,0) end
		if id == 7 then return BlockWater end #.new(world, 0,0,id,0) end
		if id == 8 then return BlockSapling end #.new(world, 0,0,id,0) end
   		if id == 9 then return BlockSpacetimeSnapshot end
	end
    
    def getEntityForId(id)
		if id == 1 then return EntityPig.new(@ac,id) end
    end
end
