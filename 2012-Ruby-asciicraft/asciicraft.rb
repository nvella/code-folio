require 'zlib'

require_relative 'TerminalMessages'

require_relative 'BlockList'

require_relative 'Screen'
require_relative 'Que'
require_relative 'RenderQue'
require_relative 'TickQue'
require_relative 'Gui'
require_relative 'GuiMainmenu'
require_relative 'GuiItem'
require_relative 'World'
require_relative 'Block'
require_relative 'BlockAir'
require_relative 'Pixel'
require_relative 'ConfigFile'
require_relative 'WorldSaveNexus'
require_relative 'Entity'
require_relative 'EntityPlayer'
require_relative 'BlockMissingblo'
require_relative 'GuiGameover'
require_relative 'LandscapeGenFlat'
require_relative 'BlockStone'
require_relative 'GuiIngame'
require_relative 'BlockGrass'
require_relative 'GuiCreateWorldSize'
require_relative 'GuiCreateWorldGenerator'
require_relative 'BlockDirt'
require_relative 'LandscapeGenSpanningMountains'
require_relative 'Logger'
require_relative 'BlockBedrock'
require_relative 'GuiNicky'
require_relative 'EntityPig'
require_relative 'GuiHUD'
require_relative 'GuiCrash'
require_relative 'BlockLog'
require_relative 'BlockLeaves'
require_relative 'LandscapeGenPieceTree'
require_relative 'BlockWater'
require_relative 'GuiCheatBlock'
require_relative 'LandscapeGenPieceCave'
require_relative 'BlockSapling'
require_relative 'GuiCrashBluescreen'
require_relative 'GuiCrashBootmanager'
require_relative 'GuiCrashLinuxPanic'
require_relative 'GuiCreateWorldSeed'
require_relative 'StringToInteger'
require_relative 'BlockSpacetimeSnapshot'

class ASCIICraft
    attr_reader :tickQue, :renderQue, :screen, :guiList, :lastKey, :theWorld, :worldPaused, :log, :versionString

	def initialize(tickSpeed)
		@screen = Screen.new(80,24)
        @renderQue = RenderQue.new
        @tickQue = TickQue.new
        @currentGui = GuiNicky.new(self)
        @theWorld = nil#World.new(self, 256, 16)
        @tickSpeed = 0.01 * tickSpeed #75 #Tick speed in milliseconds	
		@running = true
        @worldPaused = false
		@log = Logger.new("asciicraft.log")
		@versionString = "asciicraft 0.4"
		@crashed = false
        @wasteTimes = []
        @avg = 0
	end
   
	def run	
		while @running do
			startTime = Time.now           
			begin
		        @lastKey = STDIN.read_nonblock(1)
		    rescue Errno::EAGAIN
		    end
            tick 
			if @lastKey == "/" then @screen.debug end
			@screen.render		
            @lastKey = nil
            @screen.drawText(0, 22, "avg tick: #{@avg}", 0, 15)
            if @wasteTimes.length > 99 then 
                @avg = @wasteTimes.avg
                @wasteTimes = []
            end
			endTime = Time.now
			wastedTime = endTime - startTime
            @wasteTimes.push(wastedTime)
			makeup = @tickSpeed - wastedTime
			if wastedTime <= @tickSpeed then		
				sleep(makeup)
			end
		end

		@screen.exit
	end
    
    def switchWorld(world)
        @theWorld = world
    end

	def switchGui(gui)
		if gui != 0 then		
			@currentGui = gui
		else
			@currentGui = nil
		end
	end
    
    def tick
		begin
		    if @theWorld != nil and not @worldPaused and not @crashed then 
				@theWorld.tick 
				if @theWorld.thePlayer.health <= 0 then
					switchGui(GuiGameover.new(self))		
					@theWorld.thePlayer.setHealth(500)		
				end
			end
		    if @currentGui != nil then @currentGui.tick end
		rescue
			@crashed = true
			@currentGui = GuiCrash.new(self, $!, $@)
		end
		
    end
    
    def pause
        @worldPaused = true
    end
    
    def unpause
        @worldPaused = false
    end
    
    def save
        WorldSaveNexus.new(self, "world.gz").saveFile(@theWorld)
    end
    
    def stop
        @running = false
    end
end

# Here starts the section of code that does what Java does that Ruby doesn't

class SuperProxy
  	def initialize(obj)
  		@obj = obj
  	end

  	def method_missing(meth, *args, &blk)
   		@obj.class.superclass.instance_method(meth).bind(@obj).call(*args, &blk)
  	end
end

class Object
	private
	def sup
		SuperProxy.new(self)
	end
end

# and here ends

class Array
    def avg
        if self.length < 1 then return 0 end
        out = 0
        self.each {|value| out += value}
        return out / self.length
    end
end

if ARGV.length < 1 then
	ASCIICraft.new(5).run
else 
	ASCIICraft.new(ARGV[0].to_i).run
end
