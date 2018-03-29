module RNM
  class Job
    attr_reader :width, :height
    attr_accessor :cells, :id
  
    def initialize width, height, id
      @width = width
      @height = height
      @id = id
      @cells = Set.new
    end
    
    def self.from_bin_data width, height, id, data
      job = Job.new width, height, id
      data.bytes.each_with_index do |byte, index|
        if byte != 0x0 then
          x = index % width
          y = index / height
          job.cells.add [x, y]
        end
      end
      return job
    end
  end
end
