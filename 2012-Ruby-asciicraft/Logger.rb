class Logger
	def initialize(file)
		@fileName = file
		File.open(@fileName, "a") do |file|
			file.write(Time.now.to_s + " > " + "Logger initialized." + 10.chr)
		end
	end

	def log(str)
		File.open(@fileName, "a") do |file|
			file.write(Time.now.to_s + " > " + str + 10.chr)
		end
	end
end
