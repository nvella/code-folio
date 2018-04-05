module RMCCLib::Events
  class BaseEventHandler
    def initialize server
      @server = server
    end
    
    def got_packet packet; end
    
    def chat_message chat_data; end # Called when there is server chat. Args: the raw json chat data.
    
    def connection_status_mcnet_login; end # Called when Connection is authenticating with minecraft.net
    def connection_status_server; end # Called when Connection is attempting to establish a socket with the server.
    def connection_status_handshake; end # Called when Connection is handshaking.
    def connection_status_crypt_request; end # Called when Connection is waiting for an encryption request.
    def connection_status_mcnet_request; end # Called when Connection is asking to connect to the server on minecraft.net
    def connection_status_crypt_response; end # Called when Connection is sending the encryption response.
    def connection_status_crypt_wait_response; end # Called when Connection is waiting for an encryption response.
    def connection_status_crypt_enable; end # Called when Connection is enabling the encryption.
    def connection_status_client_status; end # Called when Connection is sending the client status.
    def connection_status_login_request; end # Called when Connection is waiting for a login request.
    def connection_status_client_setting; end # Called when Connection is sending the client settings.
    def connection_status_done; end # Called when Connection has finished connecting.
    
    def warn_packet_overtime packet_id; end # Called when a packet took too long to process.
    
    def error_thread_crash error, error_location; end # Called when the RMCCLib connection thread crashes.
    def error_poslook_crash error, error_location; end # Called when the PosLookWorker thread crashes.
      
    def player_position_look_update; end # Called when the player's position is updated by the server.
    def spawn_mob entity; end # Called when the client is notified of a mob spawn by the server. Args: the entity that was spawned.
    def destroy_entities entities; end # Called when the client is notified of entities despawning (being 'destroyed'). Args: an array of entities that were destroyed.
    def move_entity entity; end # Called when the client is notified of an entity moving. Args: the entity that moved.
    def spawn_player player; end # Called when a player comes into view of the client. Args: the player.
    def change_entity_velocity entity; end # Called when the client is notified of an entity's velocity changing. Args: the entity.
    def load_map_chunk_column column_x, column_z; end # Callend when a map chunk column is transmitted to the client. Args: the x co-ord of the chunk-column (multiply by 16 to get actual x), the z co-ord of the chunk-column (multiply by 16 to get actual z)
    
    def on_update; end # Called 20 times a second
  end
end
