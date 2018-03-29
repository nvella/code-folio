module ERWS
  class PathBase
    def initialize server
      @server = server
    end
    
    def run arguments = []
      return "<html><body>Empty path</body></html>"
    end
  end
end
