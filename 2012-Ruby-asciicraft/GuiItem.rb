class GuiItem
    attr_reader :name, :key
    def initialize(key, name)
        @name = name
        @key = key
    end  
end
