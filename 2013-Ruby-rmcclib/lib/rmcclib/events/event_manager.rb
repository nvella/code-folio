module RMCCLib::Events
  class EventManager
    attr_accessor :handlers
  
    def initialize
      @handlers = []
    end
    
    def handle_packet packet # Translate packets into events, these events will only be used by *very* low level event handlers and will be translated into higher level events for clients/bots to use.
      handle_event "got_packet", packet
    end
    
    def handle_event event_method, *event_args # Send an event to all handlers
      @handlers.each {|obj| obj.send event_method, *event_args}
    end
  end
end