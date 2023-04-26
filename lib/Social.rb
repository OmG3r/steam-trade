

module SocialCommands


      def send_friend_request(target)
            raise "you must be logged in to send a friend request" if @loggedin == false

            steamid,token = verify_profileid_or_trade_link_or_steamid(target)
            @session.post('https://steamcommunity.com/actions/AddFriendAjax', {
                              "accept_invite" => 0,
                              "sessionID" =>  sessionid_cookie(),
                              "steamid" => steamid
                        })

      end

      def accept_friend_request(target)
            raise "you must be logged in to accept a friend request" if @loggedin == false

            steamid,token = verify_profileid_or_trade_link_or_steamid(target)

            @session.post('https://steamcommunity.com/actions/AddFriendAjax', {
                              "accept_invite" => 1,
                              "sessionID" => sessionid_cookie(),
                              "steamid" => steamid
                        })

      end

      def remove_friend(target)
            raise "you must be logged in to remove a friend" if @loggedin == false

            steamid,token = verify_profileid_or_trade_link_or_steamid(target)

           @session.post('https://steamcommunity.com/actions/RemoveFriendAjax', {
                              "sessionID" =>  sessionid_cookie(),
                              "steamid" => steamid
                        })

      end

      def send_message(id, message)
            raise "no account details given cannot poll messages" if @chat_session.nil? && @username.nil? && @password.nil?
            mobile_login() if @chat_session.nil?

            steamid,token = verify_profileid_or_trade_link_or_steamid(id)

            @chat_session.post('https://api.steampowered.com/ISteamWebUserPresenceOAuth/Message/v1', {

                  "access_token" => @oauth_token,
                  "steamid_dst" => steamid,
                  "text" => message,
                  "type" => "saytext",
                  "umqid" => @umqid
                  })
      end


      def poll_messages()
            raise "no account details given cannot poll messages" if @chat_session.nil? && @username.nil? && @password.nil?
            mobile_login() if @chat_session.nil?
            response = @chat_session.post('https://api.steampowered.com/ISteamWebUserPresenceOAuth/Poll/v1', {
                  "umqid": @umqid,
                  "message": @message_id,
                  "pollid": 1,
                  "sectimeout": 20,
                  "secidletime": 0,
                  "use_accountids": 0,
                  "access_token": @oauth_token
                  })

            data = JSON.parse(response.content)
            @message_id = data["messagelast"]
            return data["messages"]
      end






      def mobile_login(username = @username, password = @password, secret = nil)
            secret = @secret if username == @username
            raise "username is required to do a chat login" if username.nil?
            raise "password is required to do a chat login" if password.nil?

            @chat_session = Mechanize.new { |a| # the session which will hold your cookies to communicate with steam
                  a.follow_meta_refresh = true
               #   a.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
            }

            mobileheaders = {
                  "X-Requested-With"=> "com.valvesoftware.android.steam.community",
                  "Referer"=> "https://steamcommunity.com/mobilelogin?oauth_client_id=DE45CD61&oauth_scope=read_profile%20write_profile%20read_client%20write_client",
                  "User-Agent"=>"Mozilla/5.0 (Linux; U; Android 4.1.1; en-us; Google Nexus 4 - 4.1.1 - API 16 - 768x1280 Build/JRO03S) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30",
                  "Accept"=>"text/javascript, text/html, application/xml, text/xml, */*"
            }
            cookie = Mechanize::Cookie.new :domain => 'steamcommunity.com', :name =>'mobileClientVersion', :value =>'0 (2.1.3)', :path => '/'
            @chat_session.cookie_jar << cookie
            cookie = Mechanize::Cookie.new :domain => 'steamcommunity.com', :name =>'mobileClient', :value =>'android', :path => '/'
            @chat_session.cookie_jar << cookie


            cookie = Mechanize::Cookie.new :domain => 'store.steampowered.com', :name =>'mobileClientVersion', :value =>'0 (2.1.3)', :path => '/'
            @chat_session.cookie_jar << cookie
            cookie = Mechanize::Cookie.new :domain => 'store.steampowered.com', :name =>'mobileClient', :value =>'android', :path => '/'
            @chat_session.cookie_jar << cookie


            response = @chat_session.post('https://steamcommunity.com/login/getrsakey/', {'username' => username}, mobileheaders).content


            data = pass_stamp(response,password)
            encrypted_password = data["password"]
            timestamp = data["timestamp"]
            repeater = 0
            until repeater == true
                  if secret != nil
                        guardcode = fa(secret,0)
                  else
                        puts "please write your 2FA code (mobile login to send messages)"
                        guardcode = gets.chomp
                  end


                  send = {
                        'captchagid' => '-1',
                        'captcha_text' => '',
                        'emailauth' => '',
                        'emailsteamid' => '',
                        'password' => encrypted_password,
                        'remember_login' => 'true',
                        'rsatimestamp' => timestamp,
                        'twofactorcode' =>guardcode,
                        'username' => username,
                        'loginfriendlyname' => '#login_emailauth_friendlyname_mobile',
                        'oauth_scope' => "read_profile write_profile read_client write_client",
                        'oauth_client_id' => "DE45CD61"
                  }

                  login = @chat_session.post('https://steamcommunity.com/login/dologin/', send , mobileheaders )
                  response = JSON::parse(login.body)
                  output "logging-in"
                  if response["success"] == true
                        repeater = true
                  elsif repeater == 3
                        raise "Login (mobile) failed username: #{username}, password: #{password}, shared_scret: #{secret} tried 3 times"
                 else

                       sleep(2)
                       repeater = repeater + 1
                 end


            end

            oauth_hash = JSON.parse(response["oauth"]) # steam returns a hash as a string
            @oauth_token = oauth_hash["oauth_token"]
            machinevalue = steammachine_cookie(oauth_hash["steamid"])
            get_umqid()
            return {"oauth_token" => @oauth_token, "machine" => machinevalue}
      end



      def oauth_login(oauth_token,machinevalue)

        @chat_session = Mechanize.new { |a| # the session which will hold your cookies to communicate with steam
              a.follow_meta_refresh = true
             # a.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        }


        @oauth_token = oauth_token
        response = @chat_session.post('https://api.steampowered.com/IMobileAuthService/GetWGToken/v1/', {"access_token" => oauth_token}).content
        data = JSON.parse(response)
        data = data["response"]

        raise "error. cannot login" if data["token"].nil? || data["token_secure"].nil?


        steamid = get_umqid(true) ##umqid got

        ## loading cookies
        container = []
        container << (Mechanize::Cookie.new :domain => 'store.steampowered.com', :name =>'steamLogin', :value =>data["token"], :path => '/')
        container << (Mechanize::Cookie.new :domain => 'steamcommunity.com', :name =>'steamLogin', :value =>data["token"], :path => '/')
        container << (Mechanize::Cookie.new :domain => 'help.steampowered.com', :name =>'steamLogin', :value =>data["token"], :path => '/')

        container << (Mechanize::Cookie.new :domain => 'store.steampowered.com', :name =>'steamLoginSecure', :value =>data["token_secure"], :path => '/')
        container << (Mechanize::Cookie.new :domain => 'steamcommunity.com', :name =>'steamLoginSecure', :value =>data["token_secure"], :path => '/')
        container << (Mechanize::Cookie.new :domain => 'help.steampowered.com', :name =>'steamLoginSecure', :value =>data["token_secure"], :path => '/')

        container << (Mechanize::Cookie.new :domain => 'store.steampowered.com', :name => "steamMachineAuth#{steamid}" , :value => machinevalue, :path => '/')
        container << (Mechanize::Cookie.new :domain => 'steamcommunity.com', :name => "steamMachineAuth#{steamid}" , :value => machinevalue, :path => '/')
        container << (Mechanize::Cookie.new :domain => 'help.steampowered.com', :name => "steamMachineAuth#{steamid}" , :value => machinevalue, :path => '/')

        container.each { |cookie|
            @chat_session.cookie_jar << cookie
        }


      end

      private
      def get_umqid(re = false)
            response = @chat_session.post('https://api.steampowered.com/ISteamWebUserPresenceOAuth/Logon/v1', {
                                    'ui_mode' => 'web',
                                    'access_token' => @oauth_token
                                    }).content
            hash = JSON.parse(response)
            @umqid = hash["umqid"]
            @message_id = hash["message"]

          (return hash["steamid"]) if re == true
      end


      def steammachine_cookie(steamid)
            value = nil
            begin
                  value = @chat_session.cookie_jar.jar["steamcommunity.com"]["/"]["steamMachineAuth#{steamid}"].value
            rescue
                  value = nil
            end
            if value == nil
                  begin
                        value = @chat_session.cookie_jar.jar["store.steampowered.com"]["/"]["steamMachineAuth#{steamid}"].value
                  rescue
                        value = nil
                  end
            end

            if value == nil
                  @chat_session.cookies.each { |c|
                        if c.name == "steamMachineAuth#{steamid}"
                               value = c.value
                         end
                  }
            end
            return value
      end
end
