module RMCCLib::Packets
  class Packet02Handshake < Packet
    def initialize protocol_version = 0, username = "", server_host = "", server_port = 0
      super 0x02
      @protocol_version = protocol_version
      @username = username
      @server_host = server_host
      @server_port = server_port
    end
    
    def write socket
      socket.write_ubyte @id.chr
      socket.write_byte @protocol_version
      socket.write_string @username
      socket.write_string @server_host
      socket.write_int @server_port
    end
    
    def read socket
      @protocol_version = socket.read_byte
      @username = socket.read_string
      @server_host = socket.read_string
      @server_port = socket.read_int
    end
  end
end
