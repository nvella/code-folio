module RNP
  class Connection
    STATES = {2=>:unfinished, 3=>:oscillates, 4=>:still_life, 5=>:spaceship}
    SAVE_STATES = [3, 4, 5]
    EXTRA_DATA = [3, 5]
    
    def initialize server, tcp
      @server = server
      @tcp = tcp

      @jobs = []
    end
    
    def run
      # Expect auth packet
      packet = @tcp.read 1
      if packet.ord != 0x00 then raise 'expected login packet.' end
      if @tcp.read(2).unpack('S')[0] != PROTOCOL then raise "expected protocol version #{PROTOCOL}." end
      puts "  reading credentials..."
      username = @tcp.read_string
      password = @tcp.read_string
      if username.length != 0 then
        # attempt authentication and kick if wrong auth
      end
      puts "  authenticated"
      rulebytes = ""
      @server.config['rulestring'].split('/').each do |r|
        byte = 0
        r.chars.each do |i|
          if i.to_i != 0 then
            byte += 1 << (i.to_i - 1)
          end
        end
        rulebytes += byte.chr
      end
      if rulebytes.length != 2 then raise 'something went wrong' end
      @tcp.write "#{0x04.chr}#{[@server.config['gen_max']].pack('L')}#{rulebytes}" # LOGIN OK, send params
            
      while true do
        packet_id = @tcp.read(1).ord
        case packet_id
        when 0x01
          # TODO do propper disconnect stuff
          @tcp.close
          return
        when 0x02 # request job
          request_job
        when 0x06 # job done
          jobs_in_packet = @tcp.read(2).unpack('S')[0]
          @server.completed += jobs_in_packet
          jobs_in_packet.times do
            id = @tcp.read(8).unpack('Q')[0]
            job = @jobs[id]
            state = @tcp.read(1).ord
            job.generations = @tcp.read(4).unpack('L')[0]
            job.final_data[:time] = @tcp.read(4).unpack('L')[0]
            
            job.finished = Time.now          
            job.state = STATES[state]

            if EXTRA_DATA.include? state then
              job.final_data[:ed_1] = @tcp.read(4).unpack('L')[0]
              job.final_data[:ed_2] = @tcp.read(4).unpack('L')[0]
            end
          
            if SAVE_STATES.include? state then 
  #            puts "New: #{job.state}"
              @server.types[state] += 1
              job.save_to_disk 
            end
          end
        when 0x08 # Get info
          data = "#{0x07.chr}"
        end
      end
    end
    
    def request_job
      # give it a job
      jobs = @server.new_job_batch # ask the server for a new job batch, this will mutex and lock and shit. returns a job class
      data = "#{0x03.chr}#{[jobs.length].pack('S')}"
      jobs.each do |job|
        job.id = @jobs.length
        @jobs.push job
        grid = job.grid_bin_data
        job.started = Time.now
        job.miner = @tcp.peeraddr[3]
        data = "#{data}#{[job.id].pack('Q')}#{[job.width].pack('Q')}#{[job.height].pack('Q')}#{[grid.length].pack('L')}#{grid}"        
      end
      @tcp.write data
    end
    
    def cells_a_second
      
    end
  end
end
