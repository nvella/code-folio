class StringToInteger
	def self.encode(string)
		out = "9"
		out += string.length.to_s.rjust(8, "0")
		string = string.split("")
		string.each do |s|
			out += s.ord.to_s.rjust(3, "0")
		end
		return out.to_i
	end

	def self.decode(integer)
		integer = integer.to_s
		integer[0] = ""
		dataLength = integer[0 .. 7].to_i
		integer[0 .. 7] = ""
		out = []
		dataLength.times do
			out.push integer[0 .. 2].to_i.chr
			integer[0 .. 2] = ""
		end
		return out.join
	end
end
