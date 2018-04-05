module RMCCLib
  class SmartSocket < TCPSocket
    include JavaStreamIO
  
    attr_reader :encrypted
  
    alias :orig_write :write
    alias :orig_read :read
    
    def initialize address, port
      super address, port
      disable_encryption
    end
    
    def enable_encryption secret
      @encrypt_cipher = OpenSSL::Cipher::Cipher.new('AES-128-CFB8').encrypt
      @decrypt_cipher = OpenSSL::Cipher::Cipher.new('AES-128-CFB8').decrypt
      
      @encrypt_cipher.key = @encrypt_cipher.iv = secret
      @decrypt_cipher.key = @decrypt_cipher.iv = secret
      
      @encrypted = true
    end
    
    def disable_encryption
      @encrypted = false
      
      @encrypt_cipher = nil
      @decrypt_cipher = nil
    end
    
    def write str
      if @encrypted then
        if not str.empty? then
          orig_write @encrypt_cipher.update str
        end
      else
        orig_write str
      end
    end
    
    def read length
      if @encrypted then
        if length < 1 then
          ""
        else
          @decrypt_cipher.update orig_read length
        end
      else
        orig_read length
      end
    end
  end
end