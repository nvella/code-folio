module RMCCLib::Packets
  class PacketFCEncryptionResponse < Packet
    attr_reader :shared_secret, :verify_token_response
  
    def initialize shared_secret = "", verify_token_response = ""
      super 0xFC
      @shared_secret = shared_secret
      @verify_token_response = verify_token_response
    end
    
    def read socket
      @shared_secret = socket.read_byte_array
      @verify_token_response = socket.read_byte_array
    end
    
    def write socket
      socket.write_ubyte @id
      socket.write_byte_array @shared_secret
      socket.write_byte_array @verify_token_response
    end
  end
end
