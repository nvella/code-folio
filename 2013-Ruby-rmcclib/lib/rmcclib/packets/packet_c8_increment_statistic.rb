module RMCCLib::Packets
  class PacketC8IncrementStatistic < Packet
    attr_reader :statistic_id, :amount
  
    def initialize statistic_id = 0, amount = 0
      super 0xC8
      @statistic_id = statistic_id
      @amount = amount
    end
    
    def read socket
      @statistic_id = socket.read_int
      @amount = socket.read_int
    end
    
    def write socket
      socket.write_ubyte @id
      socket.write_int @statistic_id
      socket.write_int @amount
    end
  end
end