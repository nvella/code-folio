module RMCCLib
  class Connection
    attr_reader :server_id, :address, :port, :username, :last_packets
  
    def initialize server, address, port, username, password = nil
      @server = server
      @address = address
      @port = port
      @username = username 
      @authenticator = MCNet::Authenticator.new username, password
      
      @last_packets = []
      @encrypted = false
      @online_server = @password != nil
      
      @receive_mutex = Mutex.new
      @send_mutex = Mutex.new
    end
    
    def send_packet packet
      @send_mutex.synchronize do
        packet.write @socket
      end
      # RMCCLib::LOGGER.info "Sending packet: #{packet.inspect}"
    end
    
    def receive_packet
      packet = nil
      @receive_mutex.synchronize do
        packet = Packets::Packet.read @socket
      end
      @last_packets.push packet
      packet
    end
    
    def disconnect
      if @socket != nil then 
        send_packet Packets::PacketFFDisconnect.new
        @socket.close
        @socket = nil
      end
      
      @server.running = false
    end
    
    def connected?
      @socket != nil
    end
    
    def kick reason
      RMCCLib::LOGGER.critical "Kicked from the server! Reason: #{reason}"
      @socket.close
      @socket = nil
      raise "Kicked from the server! Reason: #{reason}"
    end
    
    def connect
      if @authenticator.password_provided? then
        RMCCLib::LOGGER.info 'Password provided, attempting to connect to login.minecraft.net...'
        @server.event_manager.handle_event 'connection_status_mcnet_login'
        @authenticator.authenticate
        @username = @authenticator.username
      end
      
      RMCCLib::LOGGER.info 'Attempting to connect to server.'
      @server.event_manager.handle_event 'connection_status_server'
      @socket = SmartSocket.new address, port
      
      RMCCLib::LOGGER.status 'Sending handshake...'
      @server.event_manager.handle_event 'connection_status_handshake'
      send_packet Packets::Packet02Handshake.new(PROTOCOL_VERSION, @username, @address, @port)
      
      # attempt to do encryption
      RMCCLib::LOGGER.status 'Waiting for encryption request...'
      @server.event_manager.handle_event 'connection_status_crypt_request'
      encryption_request_packet = receive_packet
      if encryption_request_packet.class != Packets::PacketFDEncryptionRequest then
        case encryption_request_packet.id
        when 0xff
          kick encryption_request_packet.reason
        else
          raise "unexpected packet from server. expected encryption request but got #{encryption_request_packet.inspect}."
        end
      end
      
      @server_id = encryption_request_packet.server_id
      secret = "\xAA\x44" * 8
      
      if @server_id != '-' then # server is online server
        @server.online_server = true
        
        if not @authenticator.password_provided? then
          raise 'you need to provide a password to log into an online server.'
        else
          sha1 = OpenSSL::Digest::SHA1.new
          sha1.update @server_id.to_s.force_encoding "ASCII" # might be a problem
          sha1.update secret
          sha1.update encryption_request_packet.public_key
          
          # ask to join server
          RMCCLib::LOGGER.status 'Asking to join server on session.minecraft.net...'
          @server.event_manager.handle_event 'connection_status_mcnet_request'
          @authenticator.ask_to_join_server java_sha1_hash(sha1)
          RMCCLib::LOGGER.info 'Server is an online server.'
        end
      else # server is offline
        RMCCLib::LOGGER.info 'Server is an offline server.'
        @server.online_server = false
      end
      
      public_key = OpenSSL::PKey::RSA.new encryption_request_packet.public_key
      encrypted_secret = public_key.public_encrypt secret
      encrypted_token = public_key.public_encrypt encryption_request_packet.verify_token
      
      RMCCLib::LOGGER.status 'Sending encryption response...'
      @server.event_manager.handle_event 'connection_status_crypt_response'
      send_packet Packets::PacketFCEncryptionResponse.new(encrypted_secret, encrypted_token)
      
      RMCCLib::LOGGER.status 'Waiting for encryption response...'
      @server.event_manager.handle_event 'connection_status_crypt_wait_response'
      encryption_response_packet = receive_packet
      
      if encryption_response_packet.class != Packets::PacketFCEncryptionResponse then
        raise "unexpected packet from server. expected encryption response but got #{encryption_response_packet.inspect}"
      end
      
      if encryption_response_packet.shared_secret != "" or encryption_response_packet.verify_token_response != "" then
        raise "expected empty encryption response but got #{encryption_response_packet.inspect}"
      end
      
      RMCCLib::LOGGER.status 'Enabling encryption...'
      # Enable encryption
      @server.event_manager.handle_event 'connection_status_crypt_enable'
      @socket.enable_encryption secret
      
      @server.event_manager.handle_event 'connection_status_client_status'
      RMCCLib::LOGGER.status 'Sending client status...'
      send_packet Packets::PacketCDClientStatuses.new Packets::CLIENT_STATUS_SPAWN
      
      @server.event_manager.handle_event 'connection_status_login_request'
      RMCCLib::LOGGER.status 'Waiting for login request...'
      login_request_packet = receive_packet
      
      if login_request_packet.class != Packets::Packet01LoginRequest then
        raise "unexpected packet from server. expected login request but got #{login_request_packet.inspect}"
      end
      
      @server.worlds[login_request_packet.dimension].level_type = login_request_packet.level_type
      @server.max_players = login_request_packet.max_players
      @server.difficulty = login_request_packet.difficulty
      @server.player = Entities::Player.new @server, @server.worlds[login_request_packet.dimension], login_request_packet.entity_id, 0.0, 0.0, 0.0, 0, 0, 0, 0, 0, 0, false, login_request_packet.game_mode, 0
      @server.worlds[login_request_packet.dimension].entities[login_request_packet.entity_id] = @server.player
      
      RMCCLib::LOGGER.status 'Sending client settings...'
      @server.event_manager.handle_event 'connection_status_client_setting'
      send_packet Packets::PacketCCClientSettings.new("en_us", @server.view_distance, 4, 0, true)
      
      RMCCLib::LOGGER.status 'Finnished connecting.'
      @server.event_manager.handle_event 'connection_status_done'
      # Finnished connecting
    end
    
    def java_sha1_hash(sha1)
      if (sha1.digest[0].ord & 0x80) == 0x80 then
        # This method from spockbot courtesy of barneygale
        d = sha1.hexdigest.to_i 16
        if d >> 39 * 4 & 0x8 then
          d = "-%x" % ((-d) & (2 ** (40 * 4) - 1))
        else
          d = "%x" % d
        end
        return d
      else
        return sha1.hexdigest.reverse.chomp('0').reverse
      end
    end
  end
end
