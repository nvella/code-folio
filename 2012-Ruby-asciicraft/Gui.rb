class Gui
    def initialize(ac, guiName)
        @ac = ac
        @guiName = guiName
        @items = []
        @items[0] = 0
    end
    
    def addItem(item)
        @items[@items.length] = item
    end
    
    def getDrawWidth
        m = @guiName.length
        @items.each do |item|
            t = item.key + " | " + item.name
            if t.length > m then m = t.length end
        end
    end
    
    def render
        @ac.screen.drawText(1,0,@guiName,0,4)
        @ac.screen.drawText(1,1,"-------------",0,4)
        i = 2
        @items.each do |item|
            if item != 0 then
                @ac.screen.drawText(1,i,item.key + " | " + item.name,0,4)
                i += 1
            end
        end
    end
    
    def getDrawHeight
        return 1 + @items.length
    end
    
    def tick
        render
    end
end
