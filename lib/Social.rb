

module SocialCommands


      def send_friend_request(target)
            raise "you must be logged in to send a friend request" if @loggedin == false

            steamid = verify_profileid_or_trade_link_or_steamid(target)

            @session.post('https://steamcommunity.com/actions/AddFriendAjax', {
                              "accept_invite" => 0,
                              "sessionID" =>  handler.sessionid_cookie,
                              "steamid" => steamid
                        })

      end

      def accept_friend_request(target)
            raise "you must be logged in to accept a friend request" if @loggedin == false

            steamid = verify_profileid_or_trade_link_or_steamid(target)

            @session.post('https://steamcommunity.com/actions/AddFriendAjax', {
                              "accept_invite" => 1,
                              "sessionID" =>  handler.sessionid_cookie,
                              "steamid" => steamid
                        })

      end

      def remove_friend(target)
            raise "you must be logged in to remove a friend" if @loggedin == false

            steamid = verify_profileid_or_trade_link_or_steamid(target)

           @session.post('https://steamcommunity.com/actions/RemoveFriendAjax', {
                              "sessionID" =>  handler.sessionid_cookie,
                              "steamid" => steamid
                        })

      end

      def send_message(id, message)
            raise "you must be logged in to send a message" if @loggedin == false
            chat_start() if @chat_session.nil?

            steamid = verify_profileid_or_trade_link_or_steamid(id)

            @chat_session.post('https://api.steampowered.com/ISteamWebUserPresenceOAuth/Message/v1', {

                  "access_token" => @oauth_token,
                  "steamid_dst" => steamid,
                  "text" => message,
                  "type" => "saytext",
                  "umqid" => @umqid
                  })
      end


      def poll_messages()
            raise "you must be logged in to pool messages" if @loggedin == false
            chat_start() if @chat_session.nil?
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


      private
      def chat_start()
                  mobile_login()
                  get_umqid()
      end


      def mobile_login()
            @chat_session = Mechanize.new { |agent| # the session which will hold your cookies to communicate with steam
                  agent.follow_meta_refresh = true
                  agent.log = Logger.new('read.log')
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


            response = @chat_session.post('https://steamcommunity.com/login/getrsakey/', {'username' => @username}, mobileheaders).content


            data = pass_stamp(response)
            encrypted_password = data["password"]
            timestamp = data["timestamp"]
            repeater = 0
            until repeater == true
                  if @secret != nil
                        guardcode = fa(@secret,@time_difference)
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
                        'remember_login' => 'false',
                        'rsatimestamp' => timestamp,
                        'twofactorcode' =>guardcode,
                        'username' => @username,
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
                        raise "Login (mobile) failed username: #{@username}, password: #{@password}, shared_scret: #{@secret} tried 3 times"
                 else

                       sleep(2)
                       repeater = repeater + 1
                 end


            end

            oauth_hash = JSON.parse(response["oauth"]) # steam returns a hash as a string
            @oauth_token = oauth_hash["oauth_token"]


      end

      def get_umqid()
            response = @chat_session.post('https://api.steampowered.com/ISteamWebUserPresenceOAuth/Logon/v1', {
                                    'ui_mode' => 'web',
                                    'access_token' => @oauth_token
                                    }).content
            hash = JSON.parse(response)
            @umqid = hash["umqid"]
            @message_id = hash["message"]

            ## starting polling
            response = @chat_session.post('https://api.steampowered.com/ISteamWebUserPresenceOAuth/Poll/v1', {
                  "umqid": @umqid,
                  "message": @message_id,
                  "pollid": 1,
                  "sectimeout": 20,
                  "secidletime": 0,
                  "use_accountids": 0,
                  "access_token": @oauth_token
                  })

      end
end
