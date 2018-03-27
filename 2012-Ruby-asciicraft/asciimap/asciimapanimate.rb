require 'RMagick'
require 'zlib'
require_relative 'WorldSaveNexus'

class ASCIIMap
	include Magick

	def initialize(input, output)
		@input = input
		@output = output
	end

	def run
		puts "ASCIIMap 0.1 - ASCIICRAFT map renderer\n> Reading world..."
		world = WorldSaveNexus.new(@input)
		world.readFile

		puts "> Drawing blocks..."

		image = Image.new(world.worldWidth, world.worldHeight)
		worldLayer = Draw.new

		world.worldWidth.times do |x|
			world.worldHeight.times do |y|
				if x == (world.worldWidth / 2) and y == (world.worldHeight / 2) then puts "> 50 % complete" end
				worldLayer.fill(getColourForId(world.worldTable[x][y]))
				#if y > (world.worldHeight - 24) and world.worldTable[x][y] == 0 then worldLayer.fill('black') end
				worldLayer.point(x,y)
			end			
		end

		worldLayer.fill('black')
		worldLayer.text(0,10,"Seed: #{world.worldSeed} | Width: #{world.worldWidth} | Height: #{world.worldHeight}")

		puts "> Rendering image..."
		worldLayer.draw(image)

		
		dirEntries = Dir.entries("asciimap/frames")

		image.write("asciimap/frames/#{dirEntries.length + 1}.png")

		puts "> Done\nNo errors\nYay\nNo errors\nYay\nNo errors\nYay\nNo errors\nYay\nNo errors\nYay\nNo errors\nYay\nNo errors\nYayv"
	end

	def getColourForId(id)
		if id == 0 then return 'aqua' end
		if id == 1 then return 'grey' end
		if id == 2 then return 'green' end
		if id == 3 then return 'brown' end
		if id == 5 then return 'brown' end
		if id == 6 then return 'green' end
		if id == 7 then return 'blue' end
		return 'black'
	end
end

ASCIIMap.new(ARGV[0], "world.png").run
