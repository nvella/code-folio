module RNP
  class ConfigFile
    def initialize filepath
      @filepath = filepath
      @data = {}
      read
    end
    
    def read
      File.open @filepath, 'r' do |f|
        f.read.split("\n").each do |line|
          if line[0] == '#' then next end
          entry = line.split("=")
          @data[entry[0].chomp(' ')] = entry[1 .. entry.length - 1].join('=')
        end
      end
    end
    
    def to_a
      return @data
    end
  end
end
