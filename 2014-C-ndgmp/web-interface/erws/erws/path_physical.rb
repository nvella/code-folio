module ERWS
  class PathPhysical < PathBase
    def initialize server, filepath
      super server
      @filepath = filepath
    end
    
    def run args
      return IO.binread(@filepath)
    end
  end
end
