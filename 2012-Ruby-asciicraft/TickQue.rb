class TickQue < Que
    def tick
        cList = @list	
        cList.length.times do |i|
            if i != 0 then cList[i].tick end
        end
        
        purge
    end
end
