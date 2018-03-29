module RNM
  class RemotePool
    attr_reader :max_generations
  
    def initialize app, server, port, username = nil, password = nil
      @app = app
      @server = server
      @port = port
      @username = username
      @password = password
      
      @max_generations = 0
      @mutex = Mutex.new
    end
    
    def setup
      @tcp = TCPSocket.new @server, @port
      @tcp.write "#{0x00.chr}#{[PROTOCOL].pack 'S'}#{@username or 'anon'}#{0x00.chr}#{@password or 'password'}#{0x00.chr}"
      packet = @tcp.read 1
      if packet.ord != 0x04 then raise 'login failed. server rejected.' end
      @max_generations = @tcp.read(4).unpack('L')[0]
    end
    
    def request_job
      @mutex.synchronize do
        @tcp.write "#{0x02.chr}"
        packet = @tcp.read 1
        if packet.ord != 0x03 then raise "expected packet 0x03, got 0x#{packet.ord.to_s(16).upcase.rjust(2, '0')}" end
        id = @tcp.read(4).unpack('L')[0]
        grid_width = @tcp.read(8).unpack('Q')[0]
        grid_height = @tcp.read(8).unpack('Q')[0]
        data_length = @tcp.read(4).unpack('L')[0]
        data = @tcp.read data_length

        job = Job.from_bin_data(grid_width, grid_height, id, data)
        return job
      end
    end
    
    def commit world, id, state, extra_data
      @mutex.synchronize do
        size = world.size
        d = "#{0x06.chr}#{[id].pack('L')}#{state.chr}#{[world.ticks].pack('L')}#{[size[0]].pack('Q')}#{[size[1]].pack('Q')}"
        extra_data.each do |value|
          d += "#{[value].pack('L')}"
        end
        @tcp.write d
      end
    end
  end
end
