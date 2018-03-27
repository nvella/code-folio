class Que
	attr_reader :list

    def initialize
        purge
    end
    
    def add(obj)
        @list[@list.length] = obj
    end
    
    def purge
        @list = []
        @list[0] = 0
    end
end
