module ERWS
  class Connection
    def initialize server, connection
      @server = server
      @connection = connection
    end
    
    def run
      str = @connection.gets
      request_type = str.split(' ')[0]
      path = str.split(' ')[1]
      version = str.split(' ')[2]
      
      filepath = path.split('?')[0]
      arguments = (path.split('?')[0] or '').split('&')

      puts "  Requests #{filepath}..."
      
      if @server.paths[filepath] == nil then
        @connection.puts "HTTP/1.1 404 Not Found\nConnection: close\n\n<html><body><h1>404 - Not Found</h1></body></html>\n"
        return
      end
      
      @connection.puts "HTTP/1.1 200 OK\nConnection: close\n\n#{@server.paths[filepath].run(arguments)}\n"
    end
  end
end
