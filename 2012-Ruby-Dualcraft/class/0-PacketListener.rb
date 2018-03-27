module Dualcraft
  class PacketListener
    def initialize(sh)
      @sh = sh
    end
    
    def run
      @thread = Thread.new do
        puts("Packet Listener started.")
        while true do
          begin
            data = @thread.gets.chomp
            id = data[0]
            data[0] = ""
            @sh.nMsg(id, data)
          rescue
            @sh.disconnect
            @thread.stop
          end
        end
        puts("Packet Listener stopped.")
      end
      @thread.run
    end
    
    def stop
      if not @thread == nil then @thread.stop end
      puts("Packet Listener stopped.")
    end
  end
end
