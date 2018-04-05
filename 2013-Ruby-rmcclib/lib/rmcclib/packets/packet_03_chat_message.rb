module RMCCLib::Packets
  class Packet03ChatMessage < Packet
    attr_reader :chat_data
  
    def initialize chat_data = {}
      super 0x03
      @chat_data = chat_data
    end
    
    def read socket
      @chat_data = JSON.parse socket.read_string
    end
    
    def write socket
      socket.write_ubyte @id
      socket.write_string @chat_data.to_s # Client to server is a raw string
    end
  end
end
