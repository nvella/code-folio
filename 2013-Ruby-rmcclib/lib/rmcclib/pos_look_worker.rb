module RMCCLib
  class PosLookWorker # Rename to something more general
    attr_accessor :thread
  
    def initialize server, connection, player
      @server = server
      @connection = connection
      @player = player
      @ticks = 0
      @thread = nil
    end
    
    def start
      @thread = Thread.start {run}
    end
    
    def update
      old_position = @player.position.dup
      old_on_ground = @player.on_ground
      
      @player.update
      @server.event_manager.handle_event 'on_update'
      
      if old_position != @player.position or old_on_ground != @player.on_ground then
        send_position
      else
        @connection.send_packet Packets::Packet0APlayer.new(@player.on_ground)
      end
    end
    
    def send_position
      # RMCCLib::LOGGER.info "Sending position..."
      @connection.send_packet Packets::Packet0DPlayerPositionLook.new(@player.x, @player.y, @player.z, @player.stance, @player.yaw, @player.pitch, @player.on_ground)
    end
    
    def run
      @ticks = 0
      RMCCLib::LOGGER.info "PosLookWorker started."
      begin
        while @server.running do
          update
          sleep 0.05
          @ticks += 1
        end
      rescue
        RMCCLib::LOGGER.critical "PosLookWorker crashed."
        RMCCLib::LOGGER.critical "Error: "
        RMCCLib::LOGGER.critical "  #{$!}"
        RMCCLib::LOGGER.critical "at"
        RMCCLib::LOGGER.critical "  #{$@}"
        @server.event_manager.handle_event 'error_poslook_crash', $!, $@
      end
      RMCCLib::LOGGER.info "PosLookWorker stopped."
    end
  end
end
