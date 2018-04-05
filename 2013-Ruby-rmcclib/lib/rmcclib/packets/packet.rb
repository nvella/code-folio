# #read in superclass start after the first byte
# while #write has to write the packet id.

module RMCCLib::Packets
  class Packet
    attr_reader :id
  
    def initialize id
      @id = id
    end
    
    def write socket
      socket.write_ubyte @id
    end
    
    def read; end
    
    def self.read socket
      id = socket.read(1).ord.to_s(16).rjust(2, "0").upcase
      RMCCLib::Packets.constants.each do |symbol|
        if symbol.to_s[6 .. 7] == id then
          packet = RMCCLib::Packets.const_get(symbol).new
          packet.read socket       
          return packet
        end
      end

      raise "unknown packet #{id}"
    end
  end
end
