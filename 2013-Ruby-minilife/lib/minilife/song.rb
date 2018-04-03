module Minilife
  class Song < Gosu::Song
    include Tickable
  
    def initialize window, filename
      super window, filename
      @current_state = :unknown
      @per_tick = 0.01
    end
    
    def fade volume_per_tick = 0.01 # a positive value for fade in, negative for fade out
      @per_tick = per_tick
      @current_state = :fade
    end
    
    def update
      case @current_state
      when :fade
        if volume >= 1.0 or volume <= 0.0 then
          @current_state = :unknown
        else
          volume += @per_tick
        end
      end
    end
  end
end