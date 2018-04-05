module RMCCLib
  class Logger
    attr_accessor :enabled
  
    def initialize enabled = true
      @enabled = enabled
      @color_enabled = false
    end
  
    def status str
      LOGGER_MUTEX.synchronize do
        if not enabled then return end
        $stderr.puts "[#{Time.now.to_s}:>] #{str}"
      end
    end
    
    def info str
      LOGGER_MUTEX.synchronize do
        if not enabled then return end
        $stderr.puts "[#{Time.now.to_s}:#{c 6}i#{c 9}] #{str}"
      end
    end
    
    def warn str
      LOGGER_MUTEX.synchronize do
        if not enabled then return end
        $stderr.puts "[#{Time.now.to_s}:#{c 3}!#{c 9}] #{str}"
      end
    end
    
    def critical str
      LOGGER_MUTEX.synchronize do
        if not enabled then return end
        $stderr.puts "[#{Time.now.to_s}:#{c 1}x#{c 9}] #{str}"
      end
    end
    
    def c code
      "\e[3#{code}m" 
    end
  end
end
