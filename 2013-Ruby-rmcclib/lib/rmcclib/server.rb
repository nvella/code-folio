module RMCCLib
  class Server
    attr_accessor :connection, :worlds, :player, :online_server, :max_players, :difficulty, :view_distance, :running, :pos_look_worker, :event_manager

    def initialize address, port, username, password = nil, view_distance = 0, log = true
      @worlds = {0 => World.new(0, 'default'), -1 => World.new(-1, 'default'), 1 => World.new(1, 'default')}
      @player = nil
      @connection = Connection.new self, address, port, username, password
      @online_server = false
      @max_players = 0
      @difficulty = 0
      @view_distance = view_distance
      RMCCLib::LOGGER.enabled = log
      @event_manager = Events::EventManager.new
      @event_manager.handlers.push Events::MainEventHandler.new self
      @running = false
    end

    def run
      RMCCLib::LOGGER.info "RMCCLib version #{VERSION}"
      RMCCLib::LOGGER.info "     minecraft: #{MC_VERSION}"
      RMCCLib::LOGGER.info "      protocol: #{PROTOCOL_VERSION}"
      @connection.connect # This will auth with minecraft.net, connect with minecraft server, handshake and establish encryption.
                          # After this, we can go into the normal loop of listening, responding, etc...
      
      @running = true
                          
      @pos_look_worker = PosLookWorker.new self, @connection, @player
      #@pos_look_worker.start
      
      RMCCLib::LOGGER.info "RMCCLib connection thread started."
      
      Thread.new do
        begin
          while @running do
            start_time = Time.now
            packet = @connection.receive_packet    
            @event_manager.handle_packet packet
            
            total_time = Time.now - start_time
            
            #if total_time > 0.5 then
            #  RMCCLib::LOGGER.warn "processing took too long, may have blocked?"
            #  RMCCLib::LOGGER.warn " packet id: #{packet.id.to_s(16).ljust(2, "0").upcase}"
            #  RMCCLib::LOGGER.warn "total time: #{total_time}"
            #  @event_manager.handle_event 'warn_packet_overtime', packet.id
            #end 
          end
        rescue
          RMCCLib::LOGGER.critical 'RMCCLib has crashed!'
          RMCCLib::LOGGER.critical 'Error:'
          RMCCLib::LOGGER.critical "  #{$!}"
          RMCCLib::LOGGER.critical "at"
          RMCCLib::LOGGER.critical "  #{$@}"
          
          File.open("packet_id_history-crash.log", "w") {|file| @connection.last_packets.length.times {|i| file.puts "[#{i}]: #{@connection.last_packets[i].id.to_s(16).upcase.rjust(2, '0')}" } }
          
          @event_manager.handle_event 'error_thread_crash', $!, $@
        end
        
        @running = false
        RMCCLib::LOGGER.info "RMCCLib connection thread stopped."
      end
    end
  end
end
