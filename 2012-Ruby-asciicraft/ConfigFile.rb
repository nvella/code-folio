class ConfigFile
    def initialize(filePath)
        @filePath = filePath
    end
    
    def readKey(keyName)
        IO.foreach(@filePath) do |x|
            x=x.chomp
            keyCur = ""
            
            while true do
                if x[0] == "=" or x[0] == "" then 
                    x[0] = ""
                    break
                else
                    keyCur += x[0]
                    x[0] = ""
                end
            end
            
            if keyCur == keyName then return x end
        end 
    end
    
    def writeKey(keyName, keyValue)
	keyMap = []
        keyMap[0] = ""
        
        IO.foreach(@filePath) do |x|
            x=x.chomp
            keyCur = ""
            
            while true do
                if x[0] == "=" or x[0] == "" then 
                    x[0] = ""
                    break
                else
                    keyCur += x[0]
                    x[0] = ""
                end
            end
            
            keyMap[keyMap.length] = []
            keyMap[keyMap.length - 1][0] = keyCur
            keyMap[keyMap.length - 1][1] = x
        end

        done = false
        
        keyMap.each do |keyPair|
            if keyPair[0] == keyName then
                done = true
                keyPair[1] = keyValue
            end
        end
        
        if not done then
            keyMap[keyMap.length] = []
            keyMap[keyMap.length - 1][0] = keyName
            keyMap[keyMap.length - 1][1] = keyValue
        end
        
        File.open(@filePath, "w") do |file|
            keyMap.each do |keyPair|
                if keyPair.length >= 2 then file.write(keyPair[0] + "=" + keyPair[1] + 10.chr) end
            end
        end
    end
end
