module RNM
  class Worker
    def initialize app, id
      @app = app
      @id = id
    end
    
    def run
      @app.log "Worker #{@id} started."
      while true do
#        @app.log "Worker #{@id}: Requesting job..."
        job = @app.pool.request_job
#        @app.log "Worker #{@id}: Got job. id: #{job.id} w: #{job.width} h: #{job.height}"
        
        gol_world = GOLWorld.new
        gol_world.cells = job.cells
        
        state = 1
        first = gol_world.cells.deep_clone
        extra_data = []
        
        @app.pool.max_generations.times do |i|
          gol_world.tick
          if gol_world.cells.length <= 2 then # 2 or under cells in any config means death
            break
          end
          
          if i == 0 and first == gol_world.cells then 
            state = 4
            break
          end # still life
          
          if first == gol_world.cells then
            state = 3 # #3 : Oscillator
            extra_data[0] = 0 # Oscillator start
            extra_data[1] = i # Oscillator end
            break
          end
          
          if gol_world.centered.cells == first then
            state = 5 # space ship
            extra_data[0] = 0 # Spaceship loop start
            extra_data[1] = i # Spaceship look end
            break
          end
        end
        
#        @app.log "Worker #{@id}: Commiting job #{job.id} | State: #{state}"
        @app.pool.commit gol_world, job.id, state, extra_data
      end
    end
  end
end
