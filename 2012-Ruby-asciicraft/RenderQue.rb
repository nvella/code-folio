class RenderQue < Que
    def render
        cList = @list	
        cList.length.times do |i|
            if i != 0 then cList[i].render end
        end
        
        purge
    end
end
