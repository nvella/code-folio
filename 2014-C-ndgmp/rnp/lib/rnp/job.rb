module RNP
  class Job
    attr_reader :width, :height
    attr_accessor :cells, :state, :final_data, :started, :finished, :miner, :id, :generations
    
    def initialize width, height
      @width = width
      @height = height
      @cells = Set.new

      @started = nil
      @finished = nil
      @miner = nil
      @id = -1
            
      @state = :stopped
      @generations = 0
      @final_data = {}
    end
    
    def add_cell x, y
      @cells.add [x, y]
    end
    
    def delete_cell x, y
      @cells.delete [x, y]
    end
    
    def grid_bin_data
      data = 0x00.chr * (@width * @height)
      @cells.each do |pos|
        data[pos[0] + (pos[1] * @width)] = 0x01.chr
      end
      return data
    end
    
    # Centers to 0, 0
    def centered
      lowest_x = @cells.to_a[0][0]
      lowest_y = @cells.to_a[0][1]
      @cells.each do |pos|
        if pos[0] < lowest_x then lowest_x = pos[0] end
        if pos[1] < lowest_y then lowest_y = pos[1] end
      end
      
      new_cells = @cells.deep_clone
      new_cells.each do |pos|
        pos[0] -= lowest_x
        pos[1] -= lowest_y
      end
      
      centered_job = Job.new @width, @height
      centered_job.cells = new_cells
      return centered_job
    end
    
    def save_to_disk
      type_dir = case @state
                 when :unfinished
                   'unf'
                 when :oscillates
                   'osc'
                 when :still_life
                   'stl'
                 when :spaceship
                   'spa' 
                 else
                   'zzz'
                 end
      file_id = Dir.entries("#{LOCAL_DIR}/output/#{type_dir}").length - 2
      filepath = "#{LOCAL_DIR}/output/#{type_dir}/#{type_dir}-#{@width}x#{@height}-#{file_id}.rle"
      File.open filepath, 'w' do |file|
        file.puts "#C NDGMP-Mined Pattern"
        file.puts "#O Mined by #{@miner} on #{@finished}"
        file.puts "#C Width: #{@width} Height: #{@height}"
        file.puts "#C Pool: #{NAME} version #{VERSION}"
        file.puts "#C State: #{@state}"
        file.puts "#C Started: #{@started} Finished: #{@finished}"
        file.puts "#C Time spent: #{@final_data[:time]} microseconds"
        file.puts "#C Generations ran on simulation: #{@generations}"
        if @final_data[:ed_1] != nil then
          file.puts "#C Loop: #{@final_data[:ed_1]}->#{@final_data[:ed_2]}"
        end
        file.puts "x = 0, y = 0, rule = B3/S23"
        grid = centered.grid_bin_data.bytes.each_slice(@width).to_a
        data = ""
        grid.each do |line|
          index = 0
          while index < line.length do
            sub = index
            while line[sub] == line[index] do
              sub += 1
            end
            if ((sub - 1) - index) > 0 then
              data += "#{(sub) - index}"
            end
            if line[index].ord == 0 then data += 'b' else data += 'o' end
            index = sub
          end
          data += "$"
        end
        data += "!"
        data.chars.each_slice(70).to_a.each do |line|
          file.puts line.join('')
        end
      end
    end
  end
end
