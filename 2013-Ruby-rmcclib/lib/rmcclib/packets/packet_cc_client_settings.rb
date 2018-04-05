module RMCCLib::Packets
  class PacketCCClientSettings < Packet
    attr_reader :locale, :view_distance, :chat_flags, :client_difficulty, :show_cape
  
    def initialize locale = "en_US", view_distance = 0, chat_flags = 4, client_difficulty = 0, show_cape = true
      super 0xCC
      @locale = locale
      @view_distance = view_distance
      @chat_flags = chat_flags
      @client_difficulty = client_difficulty
      @show_cape = show_cape
    end
    
    def read socket
      @locale = socket.read_string
      @view_distance = socket.read_byte
      @chat_flags = socket.read_byte
      @client_difficulty = socket.read_byte
      @show_cape = socket.read_bool
    end
    
    def write socket
      socket.write_ubyte @id.chr
      socket.write_string @locale
      socket.write_byte @view_distance
      socket.write_byte @chat_flags
      socket.write_byte @client_difficulty
      socket.write_bool @show_cape
    end
  end
end
