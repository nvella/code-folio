module RMCCLib::Packets
  class PacketFAPluginMessage < Packet
    attr_reader :channel, :data
  
    def initialize channel = "", data = ""
      super 0xFA
      @channel = channel
      @data = data
    end
    
    def read socket
      @channel = socket.read_string
      @data = socket.read_byte_array
    end
    
    def write socket
      socket.write_ubyte @id
      socket.write_string @channel
      socket.write_byte_array @data
    end
  end
end