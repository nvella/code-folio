module Dualcraft
  PKT_LOGIN = 0 # username
  PKT_LOGOUT = 1 # key
  PKT_GETCNK = 2 # key, x

  class ServerHandler
    include Tickable
    attr_accessor :ip, :port
    
    def initialize(dc, ip, port, username)
      @dc = dc
      @ip = ip
      @port = port
      @key = nil
      @socket = nil
      @username = username
      @pl = PacketListener.new(self)
    end
    
    def connect
      puts("Attempting to connect to #{ip}:#{port}...")
      begin
        @socket = TCPSocket.new(@ip, @port)
                   
        puts("Attempting to collect key...")
        @socket.puts("#{0.chr}#{@username}")
        data = @socket.gets
        if data.length == 64 then
          @key = key.chomp
        else
          throw("Invalid key returned")
        end
        puts("Key: #{@key}")
        @pl.run
      rescue
        puts("Connection failed! Error: #{$!}")
        disconnect
        return false
      end
      return true
    end
    
    def disconnect
      begin
        @socket.puts("#{PKT_LOGOUT}#{@key}")
        @pl.stop
        @socket.close
      rescue
        puts("Connection failed but disconnected. Error: #{$!}")
      end
      @socket = nil
      @key = nil
    end
    
    def sendmsg(pid, data)
      begin
        puts("#{pid}#{data}")
      rescue
        puts("Connection failed! Error: #{$!}")
        disconnect
        return false
      end
      return true
    end
    
    def getmsg
      begin
        return gets.chomp
      rescue
        puts("Connection failed! Error: #{$!}")
        disconnect
        return false
      end
    end
    
    def nMsg(pid, data)
      @dc.update_queue.each {|obj| obj.nMsg(pid, data) }
    end
  end
end
