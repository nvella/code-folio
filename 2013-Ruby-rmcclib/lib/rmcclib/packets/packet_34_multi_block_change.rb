module RMCCLib::Packets
  MULTIBLOCKCHANGE_VALUES = {'metadata' => 4, 'id' => 12, 'y' => 8, 'z' => 4, 'x' => 4}

  class Packet34MultiBlockChange < Packet
    attr_reader :chunk_x, :chunk_z, :blocks_affected
  
    def initialize chunk_x = 0, chunk_z = 0, blocks_affected = []
      super 0x34
      @chunk_x = chunk_x
      @chunk_z = chunk_z
      @blocks_affected = blocks_affected
    end
    
    def read socket
      @chunk_x = socket.read_int
      @chunk_z = socket.read_int
      records = socket.read_short
      socket.read_int # all records are the same size, do we need this int?
      records.times do
        values = socket.read_uint
        data = {}
        bit = 0
        MULTIBLOCKCHANGE_VALUES.each do |key, size|
          value = 0
          size.times do |offset|
            if values[bit + offset] == 1 then
              value += 2 ** offset
            end
          end
          data[key] = value
          bit += size
        end
        blocks_affected.push data
      end
    end
    
    # TODO: writing
  end
end