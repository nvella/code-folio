class ExData
	def self.encode(array)
		data = "9"
		array.each do |string|
			string = string.to_s
			data += string.length.to_s.rjust(8, "0")
			
			string.length.times do |i|
				 data += string[i].ord.to_s.rjust(4, "0")
			end
		end		
		return data.to_i
	end

	def self.decode(number)
		number = number.to_s
		number[0] = ""
		out = []
		decoding = true

		while decoding do
			if number[0] == "" or number[0] == nil then break end
			dataLength = number[0 .. 7].to_i
			i = 0
			x = 0
			while i < (dataLength * 4) do
				if i > 4 then
					out += number[0 .. 3].join.to_i.chr
					number[0 .. 3] = ""
					x = 0
				end
				
				i += 1
				x += 1
			end
		end

		return out
	end
end

puts ExData.decode(ExData.encode([1234, "hi", false]))
