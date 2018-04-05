module RMCCLib
  class EncryptedSocket < UnencryptedSocket
    def initialize socket, secret
      @socket = socket
      @encrypt_cipher = OpenSSL::Cipher::Cipher.new('AES-128-CFB8').encrypt
      @decrypt_cipher = OpenSSL::Cipher::Cipher.new('AES-128-CFB8').decrypt
      
      @encrypt_cipher.key = @encrypt_cipher.iv = secret
      @decrypt_cipher.key = @decrypt_cipher.iv = secret
    end
    
    def write str
      if not str.empty? then
        @socket.write @encrypt_cipher.update str
      end
    end
    
    def read length
      if length < 1 then
        ""
      else
        @decrypt_cipher.update @socket.read length
      end
    end
    
    def from_unencrypted_socket
    
    end
  end
end
