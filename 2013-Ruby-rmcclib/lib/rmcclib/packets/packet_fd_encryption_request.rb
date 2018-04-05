module RMCCLib::Packets
  class PacketFDEncryptionRequest < Packet
    attr_reader :server_id, :public_key, :verify_token
  
    def initialize server_id = "", public_key = "", verify_token = ""
      super 0xFD
      @server_id = server_id
      @public_key = public_key
      @verify_token = verify_token
    end
    
    def read socket
      @server_id = socket.read_string 
      @public_key = socket.read_byte_array
      @verify_token = socket.read_byte_array
    end
    
    def write socket
      socket.write_ubyte @id
      socket.write_string @server_id
      socket.write_byte_array @public_key
      socket.write_byte_array @verify_key
    end
  end
end
