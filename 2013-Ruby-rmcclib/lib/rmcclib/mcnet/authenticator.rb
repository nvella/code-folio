module RMCCLib::MCNet
  class Authenticator
    attr_reader :username, :session_id
  
    def initialize username, password
      @username = username
      @password = password
      
      @session_id = ""
    end
    
    def password_provided?
      @password != nil
    end
    
    def authenticate
      login_server = Net::HTTP.new 'login.minecraft.net', 443
      login_server.use_ssl = true
      login_server.verify_mode = OpenSSL::SSL::VERIFY_NONE
      post_data = "user=#{@username}&password=#{@password}&version=999"
      
      response, data = login_server.post '/', post_data, 'Content-Type' => 'application/x-www-form-urlencoded'
      
      if not Net::HTTPOK === response then
        raise "couldn't connect to minecraft.net. error: #{response.inspect}"
      end
      
      _, _, @username, @session_id = response.body.split(":")
    end
    
    def ask_to_join_server server_id
      session_server = Net::HTTP.new 'session.minecraft.net'
      response, data = session_server.get "/game/joinserver.jsp?user=#{@username}&sessionId=#{@session_id}&serverId=#{server_id}"
      
      if not Net::HTTPOK === response then
        raise "failed to join server. error: #{response.inspect}"
      end
    end
  end
end
