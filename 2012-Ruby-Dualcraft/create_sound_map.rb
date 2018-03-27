soundmap = {}

Dir.entries("music").each do |song|
  if song.length > 2 then
    print("Track #{song}: Minimum Height: ")
    min = gets.to_i
    print("Track #{song}: Maximum Height: ")
    max = gets.to_i
    soundmap[song] = []
    soundmap[song][0] = min
    soundmap[song][1] = max
  end
end

puts("Writing sound map...")
require("json")
File.open("soundmap.json", "w") do |file|
  file.write(JSON.pretty_generate(soundmap))
end
