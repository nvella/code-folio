class WorldSaveNexus #< ConfigFile
    include BlockList
    
    def initialize(ac, filePath)
        @ac = ac
        @filePath = filePath
		#super(filePath)
    end
    
    def readFile
		gz = Zlib::GzipReader.open(@filePath)
		file = gz.readlines
		gz.close

        worldWidth = file[0].chomp.to_i
        worldHeight = file[1].chomp.to_i
		world = World.new(@ac, worldWidth, worldHeight)  

		line = 2

        worldTable = []
        worldWidth.times do |x|
            worldTable[x] = []
            worldHeight.times do |y|
                t = file[line].chomp
                t = t.split(";")
                b = getBlockForID(t[0].to_i).new(world, x, y)
                b.setMetadata(t[1].to_i)
                world.setBlock(x,y,b)
				line += 1
            end            
        end
        
        playerDirection = file[line].chomp.to_i
        playerPosX = file[line+1].chomp.to_i
        playerPosY = file[line+2].chomp.to_i
        playerHealth = file[line+3].chomp.to_i
		spawnX = file[line+4].chomp.to_i
		spawnY = file[line+5].chomp.to_i
		line += 6        

        player = EntityPlayer.new(world)
        player.setPosition(playerPosX, playerPosY)
        player.setHealth(playerHealth)
        player.setDirection(playerDirection)
		
		8.times do |n|
			if file[line].chomp.to_i != 0 then 
				player.setInventorySlot(n,getBlockForID(file[line].chomp.to_i), file[line+1].chomp.to_i) 
			end			
			line += 2
		end

		world.time = file[line].chomp.to_i
		line += 1
		
		totalEntities = file[line].chomp.to_i
		line += 1
		totalEntities.times do
			entity = getEntityForId(file[line].chomp.to_i)
			line += 1
			16.times do |a|
				entity.setData(a, file[line].chomp.to_i)
				line += 1
			end
			world.spawnEntity(entity)
		end

		world.seed = file[line].chomp.to_i
		line += 1
		file[line].chomp.to_i.times do |i|
			line += 1
			world.dataStore[i] = Marshal.load(Zlib::Inflate.inflate(StringToInteger.decode(file[line].chomp.to_i)))
		end

		line += 1
		world.blockLog = Marshal.load(Zlib::Inflate.inflate(file[line .. file.length].join))	

		world.setSpawn(spawnX, spawnY)        

        world.thePlayer = player

		if player.health == 500 then
			@ac.switchGui(GuiGameover.new(@ac))
		end

		@ac.switchWorld(world)

        #return world
    end
    
    def saveFile(world)
		Zlib::GzipWriter.open(@filePath) do |file|

		    file.write(world.width.to_s + 10.chr)
		    file.write(world.height.to_s + 10.chr)
		    
		    world.width.times do |x|
		        world.height.times do |y|
		            file.write(world.getBlock(x,y).id.to_s + ";" + world.getBlock(x,y).metadata.to_s + 10.chr)            
				end
		    end
		    
		    file.write(world.thePlayer.direction.to_s + 10.chr)
		    file.write(world.thePlayer.x.to_s + 10.chr)
		    file.write(world.thePlayer.y.to_s + 10.chr)
		    file.write(world.thePlayer.health.to_s + 10.chr)
			file.write(world.spawnX.to_s + 10.chr)
			file.write(world.spawnY.to_s + 10.chr)

			8.times do |n|
				if @ac.theWorld.thePlayer.getInventorySlot(n)[0] == nil then
					file.write("0" + 10.chr)
					file.write("0" + 10.chr)
				else
					file.write(@ac.theWorld.thePlayer.getInventorySlot(n)[0].new(world, 0, 0).id.to_s + 10.chr)
					file.write(@ac.theWorld.thePlayer.getInventorySlot(n)[1].to_s + 10.chr)
				end
			end

			file.write(world.time.to_s + 10.chr)		
			
			file.write(world.entityList.length.to_s + 10.chr)
			
			world.entityList.each do |entity|
				file.write(entity.id.to_s + 10.chr)
				16.times do |a|
					file.write(entity.fileData[a].to_s + 10.chr)
				end
			end

			file.write(world.seed.to_s + 10.chr)
			file.write(world.dataStore.length.to_s + 10.chr)
			world.dataStore.each do |obj|
				file.write(StringToInteger.encode(Zlib::Deflate.deflate(Marshal.dump(obj))).to_s + 10.chr)
			end
			file.write(Zlib::Deflate.deflate(Marshal.dump(world.blockLog)))
		end   
	 end
end
