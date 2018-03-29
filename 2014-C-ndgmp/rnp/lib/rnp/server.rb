module RNP
  class Server
    attr_reader :config, :port
    attr_accessor :times, :last_time, :completed, :types
  
    def initialize port
      @port = port
      @connections = []
      @connection_threads = []
      
      @config = {'gen_max' => 24, 'min_cells' => 3, 'batch_size' => 32, 'rulestring' => '23/3'}
      @grid_size = 1
      @iteration = 1
      @completed = 1
      
      @job_mutex = Mutex.new
      @last_time = nil
      @times = []
      
      @last_status_line = ""
      @types = {3=>0,4=>0,5=>0}      
      @dispatched_grids = Set.new
      
      load_config
    end
    
    def run
      Thread.abort_on_exception = true
    
      puts "#{NAME} version #{VERSION}"
      puts "accepting miners on #{@port}..."
      @tcp = TCPServer.new @port
      
      Thread.new do
        while true do
          print ("\b" * @last_status_line.length)
          
          minimized = @completed - (2 ** ((@grid_size - 1) ** 2))
          minimized_fetched = @iteration - (2 ** ((@grid_size - 1) ** 2))
          max = (2 ** (@grid_size ** 2)) - (2 ** ((@grid_size - 1) ** 2))
          percent = (((1.0 / max).to_f) * minimized) * 100
          
          @last_status_line = "block complete: #{percent.to_s.split('.')[0]}.#{percent.to_s.split('.')[1][0 .. 2]}% (#{minimized}/#{max} grids) fetched grids: #{minimized_fetched}/#{max} miners: #{@connections.length} grid_size: #{@grid_size} still-lifes: #{@types[4]} oscillators: #{@types[3]} spaceships: #{@types[5]}        "
          print "#{@last_status_line}"
          sleep 0.1
        end
      end
      
      while true do
        client = @tcp.accept
        @connection_threads.push(Thread.new do
          puts "new connection from #{client.peeraddr[3]}"
          connection = Connection.new self, client
          @connections.push connection
          begin
            connection.run
          rescue Exception
            puts "Error: #{$!} @ #{$@}"
          end
          @connections.delete connection
          puts "connection from #{client.peeraddr[3]} closed."
        end)
      end
    end
    
    def new_job_raw
#      @job_mutex.synchronize do
      attempt = nil
      while true do
        if @iteration >= 2 ** (@grid_size * @grid_size) then
#            puts "bumping gridsize from #{@grid_size} to #{@grid_size + 1}."
          @grid_size += 1
        end
        attempt = Job.new @grid_size, @grid_size
  
        (@grid_size * @grid_size).times do |i|
          x = i % @grid_size
          y = i / @grid_size
          if @iteration[i] == 1 then attempt.add_cell x, y end
        end
        attempt = attempt.centered
        
        @iteration += 1          
        if attempt.cells.length >= @config['min_cells'] and not @dispatched_grids.include? attempt.cells then break end
      end

      @dispatched_grids.add attempt.cells
      attempt.id = @iteration - 1
      return attempt
    end
    
    def new_job_batch
      batch = []
      @job_mutex.synchronize do
        @config['batch_size'].times do 
          batch.push new_job_raw
        end
      end    
      return batch
    end
    
    def load_config
      configfile = ConfigFile.new("#{LOCAL_DIR}/rnp.cfg").to_a
      @config['gen_max'] = configfile['gen_max'].to_i
      @config['min_cells'] = configfile['min_cells'].to_i
      @config['batch_size'] = configfile['batch_size'].to_i
      @config['rulestring'] = configfile['rulestring']
    end
  end
end
