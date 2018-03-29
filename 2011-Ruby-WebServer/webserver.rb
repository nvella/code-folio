# quick nick-approved webserver

require 'socket'

class Script
  def initialize(file, data, post=nil)
    @file = file
    @params = []
    if data != nil then
      data.split("&").each do |string|
        @params.push(string)
      end
    end
  end

  def run
    puts("Running script...")
    $GET = {}
    $OUT = ""
    @params.each do |a|
      $GET[a.split("=")[0]] = a.split("=")[1]
    end
    load("./" + @file)
    return $OUT
  end

  def self.isScript?(path)
    if path.split(".")[path.split(".").length-1] == "nwr" then return true end
    return false
  end
end

class Request
  def initialize(serv, path, data, pdata = nil)
    puts pdata
    @server = serv
    @path = path
    @data = data
    @postData = pdata
    if @data != nil then @data = @data.gsub("%2F", "/").gsub("+", " ").gsub("%2B", "+") end
    @status = "200 OK"  
    if @path[@path.length-1] == "/" then @path += @server.index_file end
    sanitize
  end

  def sanitize
    @path = @path.gsub("..", "")
  end

  def process
    if not File.exists?("files" + @path) then 
      @status = "404 Not Found" 
      content = "<html><body><h1>Not Found</h1></body></html>"
    else
      if Script.isScript?("files" + @path) then content = Script.new("files" + @path, @data, @postData).run
      else content = IO.binread("files" + @path) end
    end
    return @status + "\nConnection: close\n\n" + content
  end
end

class Connection
  def initialize(serv, client)
    @server = serv
    @client = client
    data = client.gets
    print(data)
    if data.split(" ").length > 2 then
      @type = data.split(" ")[0]
      @extra = data.split(" ")[1]
    end
  end

  def process
    response = @server.http_version + " "
    if @type == 'POST' then
      data = @client.gets
      puts data
      response += Request.new(@server, @extra.split("?")[0], @extra.split("?")[1], data).process
    elsif @type == 'GET' then
      response += Request.new(@server, @extra.split("?")[0], @extra.split("?")[1]).process
    end
    return response
  end
end

class WebServer
  attr_reader :http_version, :index_file
  def initialize(port)
    @port = port
    @http_version = "HTTP/1.1"
    @server = TCPServer.new(@port)
    @index_file = "index.nwr"
  end

  def run
    loop do
      Thread.start(@server.accept) do |client|
        begin
          client.puts Connection.new(self, client).process
          client.close
        rescue
          puts("bug: #{$!}@#{$@}")
        end
      end
    end
  end  
end

WebServer.new(8080).run
