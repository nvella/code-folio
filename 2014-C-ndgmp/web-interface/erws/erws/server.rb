module ERWS
  class Server
    attr_accessor :paths
  
    def initialize port = 8080
      @port = 8080
      @paths = {}
    end
    
    def run
      puts "#{NAME} version #{VERSION}"
      begin
        @tcp = TCPServer.new @port
        while true do
          client = @tcp.accept
          puts "New connection from: #{client.peeraddr[3]}"
          Thread.new do
            begin
              connection = Connection.new self, client
              connection.run
              client.close
            rescue
              puts "Error in thread: #{$!}@#{$@}"
            end
          end
        end
      rescue Interrupt
        puts "Closing server..."
        if @tcp != nil then @tcp.close end
      end
    end
    
    def add_path path, responder
      @paths[path] = responder
    end
    
    def add_physical_path filepath
      puts "Adding physical path #{filepath} to /#{filepath}"
      @paths["/#{filepath}"] = PathPhysical.new(self, filepath)
    end
  end
end
