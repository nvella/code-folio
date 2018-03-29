module RNM
  class Application
    attr_accessor :pool, :workers, :pool
  
    def initialize workers_amt = 4, server = nil, port = nil
      @server = server
      @port = port
      
      @pool = RemotePool.new self, @server, @port
      @workers = []
      @worker_threads = []
      workers_amt.times do |i|
        @workers.push Worker.new(self, i)
      end
      
      @log_mutex = Mutex.new
    end
    
    def run
      Thread.abort_on_exception = true
    
      puts "#{NAME} version #{VERSION}"
      puts "Using pool at #{@server}:#{@port}."
      puts 'Setting up pool...'
      @pool.setup
      puts "Starting workers..."
      @workers.each do |worker|
        @worker_threads.push(Thread.new do
          worker.run
        end)
      end
      while true do sleep 1 end
    end
    
    def log text
      @log_mutex.synchronize {puts text}
    end
  end
end
