module Dualcraft
  class MusicPlayer
    include Tickable

    def initialize(dc, world)
      @dc = dc
      @world = world
      @songs = {}
      puts("Loading songs...")
      Dir.entries("music").each do |song|
        if song.split(".")[1] == "ogg" then
          puts("  ./music/#{song}")
          @songs[song] = Gosu::Song.new(@dc, "music/#{song}")
          @songs[song].volume = 0.25
        end
      end
      puts("Reading soundmap...")
      File.open("soundmap.json", "r") do |f|
        @soundmap = JSON.parse(f.read)
      end
      @timer = 1200
      @last_song = nil
    end

    def songs_playing?
      @songs.each do |name, song|
        if song.playing? then return true end
      end
      return false
    end

    def play
      if songs_playing? then return end
      if not @dc.music_enabled then return end
      player = @world.current_player
      possible_songs = []
      @soundmap.each do |song, data|
        if player.data["posY"] >= data[0] and player.data["posY"] <= data[1] then
          possible_songs.push(song)
        end
      end
      if @last_song != nil then possible_songs.delete(@last_song) end
      if possible_songs.length > 0 then
        @last_song = possible_songs[rand(possible_songs.length)]
        @songs[@last_song].play
      end
    end

    def update
      @timer -= 1
      if @timer < 1 then
        refresh_timer
        play
      end
    end

    def refresh_timer
      @timer = 7200 + rand(1200)
    end
  end
end
