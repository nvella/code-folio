require 'socket'      # minecraft servers
require 'zlib'        # compression
require 'stringio'    # io ops on strings
require 'openssl'     # required for connecting to minecraft servers. the server will not accept a connection if it isn't encrypted.
require 'json'        # 1.6> chat messages

require 'net/http'    # minecraft.net auth servers
require 'net/https'   # minecraft.net auth servers

module RMCCLib
  VERSION          = '0.0.1'
  MC_VERSION       = '1.6.4'
  PROTOCOL_VERSION = 78
  
  module Packets
  end
  
  module MCNet
  end
  
  module JavaStreamIO
  end
  
  module Events
  end
  
  module Entities
  end
end

require_relative 'rmcclib/java_stream_io'       # For java-like reads and writes to streams.

##############################
# EVENT SYSTEM
#

require_relative 'rmcclib/events/event_manager'
require_relative 'rmcclib/events/base_event_handler'
require_relative 'rmcclib/events/main_event_handler'

##############################
# MINECRAFT.NET CLASSES
#

require_relative 'rmcclib/mcnet/authenticator'  # For authenticating with minecraft.net and receiving a session key and username
require_relative 'rmcclib/mcnet/ping_thread'    # Called by mcnet/authenticator for pinging minecraft.net and keeping the session id alive.

#############################
# PACKET CLASSES
#

require_relative 'rmcclib/packets/packet'                                 # Packet class base.
require_relative 'rmcclib/packets/packet_00_keep_alive'                   # Keep alive packet.
require_relative 'rmcclib/packets/packet_02_handshake'                    # Handshake packet.
require_relative 'rmcclib/packets/packet_fd_encryption_request'           # Encryption request packet.
require_relative 'rmcclib/packets/packet_fc_encryption_response'          # Encryption response packet.
require_relative 'rmcclib/packets/packet_cd_client_statuses'              # Client status packet.
require_relative 'rmcclib/packets/packet_01_login_request'                # Login request packet.
require_relative 'rmcclib/packets/packet_cc_client_settings'              # Client settings packet.
require_relative 'rmcclib/packets/packet_ff_disconnect'                   # Disconnect/Kick packet.
require_relative 'rmcclib/packets/packet_06_spawn_position'               # Set spawn position packet.
require_relative 'rmcclib/packets/packet_ca_player_abilities'             # Player abilities (flying, creative, etc) packet.
require_relative 'rmcclib/packets/packet_10_held_item_change'             # Held item change packet.
require_relative 'rmcclib/packets/packet_0d_player_position_look'         # Player position and look packet.
require_relative 'rmcclib/packets/packet_04_time_update'                  # Time update packet.
require_relative 'rmcclib/packets/packet_c9_player_list_item'             # Player list item update packet.
require_relative 'rmcclib/packets/packet_68_set_window_items'             # Set window items packet.
require_relative 'rmcclib/packets/packet_46_change_game_state'            # Change game state packet.
require_relative 'rmcclib/packets/packet_67_set_slot'                     # Set slot packet.
require_relative 'rmcclib/packets/packet_38_map_chunk_bulk'               # Map chunks in bulk packet.
require_relative 'rmcclib/packets/packet_18_spawn_mob'                    # Mob spawn packet.
require_relative 'rmcclib/packets/packet_28_entity_metadata'              # Entity metadata packet.
require_relative 'rmcclib/packets/packet_05_entity_equipment'             # Entity equipment packet.
require_relative 'rmcclib/packets/packet_1f_entity_relative_move'         # Entity relative move packet.
require_relative 'rmcclib/packets/packet_3e_named_sound_effect'           # Named sound effect packet.
require_relative 'rmcclib/packets/packet_1c_entity_velocity'              # Entity velocity packet.
require_relative 'rmcclib/packets/packet_20_entity_look'                  # Entity look packet.
require_relative 'rmcclib/packets/packet_21_entity_look_relative_move'    # Entity look and relative move packet.
require_relative 'rmcclib/packets/packet_23_entity_head_look'             # Entity head look packet.
require_relative 'rmcclib/packets/packet_17_spawn_object_vehicle'         # Spawn object/vehicle packet.
require_relative 'rmcclib/packets/packet_84_update_tile_entity'           # Update tile entity packet.
require_relative 'rmcclib/packets/packet_2c_entity_properties'            # Entity properties packet.
require_relative 'rmcclib/packets/packet_03_chat_message'                 # Chat message packet.
require_relative 'rmcclib/packets/packet_35_block_change'                 # Block change packet.
require_relative 'rmcclib/packets/packet_22_entity_teleport'              # Entity teleport packet.
require_relative 'rmcclib/packets/packet_1d_destroy_entity'               # Destroy entity packet.
require_relative 'rmcclib/packets/packet_3d_sound_particle_effect'        # Sound or particle effect packet.
require_relative 'rmcclib/packets/packet_26_entity_status'                # Entity status packet.
require_relative 'rmcclib/packets/packet_14_spawn_named_entity'           # Spawn named entity packet.
require_relative 'rmcclib/packets/packet_12_animation'                    # Animation packet.
require_relative 'rmcclib/packets/packet_34_multi_block_change'           # Multiblock change packet.
require_relative 'rmcclib/packets/packet_27_attach_entity'                # Attach entity packet.
require_relative 'rmcclib/packets/packet_c8_increment_statistic'          # Increment statistic packet.
require_relative 'rmcclib/packets/packet_1a_spawn_experience_orb'         # Spawn experience orb packet.
require_relative 'rmcclib/packets/packet_fa_plugin_message'               # Plugin message packet.
require_relative 'rmcclib/packets/packet_37_block_break_animation'        # Block break animation packet.
require_relative 'rmcclib/packets/packet_16_collect_item'                 # Item collection packet.
require_relative 'rmcclib/packets/packet_36_block_action'                 # Block action packet.
require_relative 'rmcclib/packets/packet_08_update_health'                # Health update packet.
require_relative 'rmcclib/packets/packet_2b_set_experience'               # Set experience packet.
require_relative 'rmcclib/packets/packet_33_chunk_data'                   # Single chunk column packet.
require_relative 'rmcclib/packets/packet_09_respawn'                      # Respawn packet.
require_relative 'rmcclib/packets/packet_0a_player'                       # Player on_ground packet.
require_relative 'rmcclib/packets/packet_0e_player_digging'               # Player digging packet.

##############################
# ENTITY CLASSES
#

require_relative 'rmcclib/entities/entity'               # For storing an entity. Meant to be inherited by other entity classes.
require_relative 'rmcclib/entities/player'               # For storing a player. Will contain inventory, etc.
require_relative 'rmcclib/entities/other_player'         # For storing information about players other than the one controlled by the library.

##############################
# GENRAL CLASSES
#

require_relative 'rmcclib/server'               # For managing remote servers, contains world, player lists, etc... This class will listen for packets from the server.
require_relative 'rmcclib/connection'           # For the tcp socket and keeping encryption state. This doesn't actively run anything. Will have functions for writing packets, etc.
require_relative 'rmcclib/smart_socket'         # For communicating with the minecraft server, supports transitioning from unencrypted to encrypted and back again.
require_relative 'rmcclib/smart_string_io'      # Used in Packet38MapChunkBulk
require_relative 'rmcclib/chat'                 # Manages chat.
require_relative 'rmcclib/world'                # For storing a local copy of the world so it can be used for different applications that use rmcclib.
require_relative 'rmcclib/chunk'                # For storing a chunk
require_relative 'rmcclib/chunk_column'         # For storing a chunk column
#require_relative 'rmcclib/section'             # For storing a section (a group of 16*16*16 blocks)
require_relative 'rmcclib/block'                # For storing a block. Meant to be inherited by other block classes.
require_relative 'rmcclib/logger'               # For optionally outputting messages to the console for debugging purposes.
require_relative 'rmcclib/pos_look_worker'      # For sending the position and look information to the server every 0.5 seconds.
require_relative 'rmcclib/slot'                 # For storing information about items.
require_relative 'rmcclib/entity_metadata'      # For storing entity metadata.
require_relative 'rmcclib/object_data'          # For storing object data (see packet 0x17)
require_relative 'rmcclib/nbt'                  # For storing NBT data
require_relative 'rmcclib/smart_gzip_reader'    # For java stream IO on gzip reader.


module RMCCLib
  LOGGER = Logger.new
  LOGGER_MUTEX = Mutex.new
end
