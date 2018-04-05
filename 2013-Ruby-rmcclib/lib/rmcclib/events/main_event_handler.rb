module RMCCLib::Events
  class MainEventHandler < BaseEventHandler
    def initialize server
      super server
    end
    
    def got_packet packet # We will use this event handler to translate and abstract the protocol for clients/bots that use this lib.
      case packet
      when RMCCLib::Packets::Packet00KeepAlive # relay the packet back to the server
        @server.connection.send_packet packet 
      when RMCCLib::Packets::Packet0DPlayerPositionLook # notify about update and start poslookworker if not started
        RMCCLib::LOGGER.info "Player position updated."
        RMCCLib::LOGGER.info "x: #{packet.x}, y: #{packet.y}, z: #{packet.z}"
        @server.player.position = [packet.x, packet.y, packet.z]
        @server.player.stance = packet.stance
        @server.player.yaw = packet.yaw
        @server.player.pitch = packet.pitch
        @server.player.on_ground = packet.on_ground
        
        if @server.pos_look_worker.thread == nil then
          @server.pos_look_worker.start
        end
        
        @server.event_manager.handle_event 'player_position_look_update'
      when RMCCLib::Packets::Packet18SpawnMob # Add mob to current dimension's entity hash
        @server.player.world.entities[packet.entity_id] = RMCCLib::Entities::Entity.new @server.player.world, packet.entity_id, packet.x, packet.y, packet.z, packet.yaw, packet.pitch, packet.head_pitch, packet.metadata
        @server.event_manager.handle_event 'spawn_mob', @server.player.world.entities[packet.entity_id]
      when RMCCLib::Packets::Packet1DDestroyEntity # Remove entity from current dimension's entity hash
        entities = packet.entity_ids.each.collect {|id| @server.player.world.entities[id]} 
        packet.entity_ids.each {|entity| @server.player.world.entities.delete entity}
        @server.event_manager.handle_event 'destroy_entities', entities
      when RMCCLib::Packets::Packet1FEntityRelativeMove # Update entity position
        if @server.player.world.entities[packet.entity_id] == nil then
          #RMCCLib::LOGGER.warn "tried to move entity #{packet.entity_id} but entity does not exist."
          return
        end
        
        @server.player.world.entities[packet.entity_id].position[0] += packet.x
        @server.player.world.entities[packet.entity_id].position[1] += packet.y
        @server.player.world.entities[packet.entity_id].position[2] += packet.z
        @server.event_manager.handle_event 'move_entity', @server.player.world.entities[packet.entity_id]
      when RMCCLib::Packets::Packet14SpawnNamedEntity # Spawn a named entity (like a player)
        @server.player.world.entities[packet.entity_id] = RMCCLib::Entities::OtherPlayer.new @server.player.world, packet.entity_id, packet.x, packet.y, packet.z, packet.yaw, packet.pitch, 0, packet.metadata, packet.entity_name, packet.current_item
        @server.event_manager.handle_event 'spawn_player', @server.player.world.entities[packet.entity_id]
      when RMCCLib::Packets::Packet1CEntityVelocity # Change an entity's velocity.
        if @server.player.world.entities[packet.entity_id] == nil then
          #RMCCLib::LOGGER.warn "Attempted to change velocity of entity #{packet.entity_id} but entity does not exist!"
          return
        end
        
        @server.player.world.entities[packet.entity_id].velocity[0] = packet.vel_x
        @server.player.world.entities[packet.entity_id].velocity[1] = packet.vel_y
        @server.player.world.entities[packet.entity_id].velocity[2] = packet.vel_z
        @server.event_manager.handle_event 'change_entity_velocity', @server.player.world.entities[packet.entity_id]
      when RMCCLib::Packets::Packet38MapChunkBulk # Start a thread, decode map chunk data and call the 'load_map_chunk_column' event for each decoded chunk column with the args chunk_x, chunk_y.
        Thread.new do
          begin
            # RMCCLib::LOGGER.info 'Loading chunks...'
            packet.chunk_column_count.times do |i|
              chunk_col = RMCCLib::ChunkColumn.new packet.metadata[i]['chunk_x'], packet.metadata[i]['chunk_z']
              chunk_col.read true, packet.metadata[i]['primary_bitmap'], packet.metadata[i]['add_bitmap'], packet.raw_data
              @server.player.world.chunk_columns[[packet.metadata[i]['chunk_x'], packet.metadata[i]['chunk_z']]] = chunk_col
            end
            # RMCCLib::LOGGER.info 'Finished loading chunks...'
            packet.chunk_column_count.times do |i|
              @server.event_manager.handle_event 'load_map_chunk_column', packet.metadata[i]['chunk_x'], packet.metadata[i]['chunk_z']
            end
          rescue
            RMCCLib::LOGGER.critical "A map chunk loading thread crashed."
            RMCCLib::LOGGER.critical "Error: "
            RMCCLib::LOGGER.critical "  #{$!}"
            RMCCLib::LOGGER.critical "at"
            RMCCLib::LOGGER.critical "  #{$@}"          
          end
        end
      when RMCCLib::Packets::Packet33ChunkData
        RMCCLib::LOGGER.info "Received a chunk column at #{packet.chunk_x}, #{packet.chunk_z}"
        chunk_col = RMCCLib::ChunkColumn.new packet.chunk_x, packet.chunk_z
        chunk_col.read packet.ground_up_continuous, packet.primary_bitmap, packet.add_bitmap, RMCCLib::SmartStringIO.new(packet.data)
        @server.player.world.chunk_columns[[packet.chunk_x, packet.chunk_z]] = chunk_col
      when RMCCLib::Packets::Packet35BlockChange
        @server.player.world.set_block packet.x, packet.y, packet.z, RMCCLib::Block.new(packet.id, packet.metadata)
      when RMCCLib::Packets::Packet03ChatMessage
        @server.event_manager.handle_event 'chat_message', packet.chat_data
      when RMCCLib::Packets::PacketFFDisconnect
        @server.connection.kick packet.reason
      when RMCCLib::Packets::Packet08UpdateHealth
        RMCCLib::LOGGER.info "Health Update: H: #{packet.health}, F: #{packet.food}, FS: #{packet.food_saturation}"
        @server.player.health = packet.health
        @server.player.food = packet.food
        @server.player.food_saturation = packet.food_saturation
      when RMCCLib::Packets::Packet2BSetExperience
        RMCCLib::LOGGER.info "Experience Update: Bar: #{packet.experience_bar * 100}%, L: #{packet.levels}, EXP: #{packet.experience}"
        @server.player.experience = packet.experience
        @server.player.levels = packet.levels
      when RMCCLib::Packets::Packet09Respawn
        RMCCLib::LOGGER.info "Respawn"
        @server.player.world = @server.worlds[packet.dimension]
        @server.difficulty = packet.difficulty
        @server.player.game_mode = packet.game_mode
        @server.player.world.level_type = packet.level_type
      end
    end
    
    def spawn_mob entity
      RMCCLib::LOGGER.info "Entity spawn: #{entity.entity_id}"
    end
    
    def spawn_player entity
      RMCCLib::LOGGER.info "Player spawn: #{entity.entity_id} | Name: #{entity.name}"
    end
  end
end
