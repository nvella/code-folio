class WorldSaveNexus #< ConfigFile
	attr_reader :worldWidth, :worldHeight, :worldTable, :worldSeed   


    def initialize(filePath)
        @filePath = filePath
		#super(filePath)
    end
    
    def readFile
		gz = Zlib::GzipReader.open(@filePath)
		file = gz.readlines
		gz.close

        @worldWidth = file[0].chomp.to_i
        @worldHeight = file[1].chomp.to_i

		line = 2

        @worldTable = []
        @worldWidth.times do |x|
            @worldTable[x] = []
            @worldHeight.times do |y|
                t = file[line].chomp
                t = t.split(";")
				@worldTable[x][y] = t[0].to_i
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
		
		8.times do |n|	
			line += 2
		end

		line += 1
		
		totalEntities = file[line].chomp.to_i
		line += 1
		totalEntities.times do
			line += 1
			16.times do |a|
				line += 1
			end
		end

		@worldSeed = file[line].chomp

	end

end
