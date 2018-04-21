module LoginCommands

########################################################################################
      def login
            data = pass_stamp()
            encrypted_password = data["password"]
            timestamp = data["timestamp"]
            repeater = 0
            until repeater == true
                  if @secret != nil
                        guardcode = fa()
                  else
                        puts "please write your 2FA code"
                        guardcode = gets.chomp
                  end


                  send = {
                        'password' => encrypted_password,
                        'username' => @username,
                        'twofactorcode' =>guardcode, #update
                        'emailauth' => '',
                        'loginfriendlyname' => '',
                        'captchagid' => '-1',
                        'captcha_text' => '',
                        'emailsteamid' => '',
                        'rsatimestamp' => timestamp,
                        'remember_login' => 'false'
                  }

                  login = @session.post('https://store.steampowered.com/login/dologin', send )
                  response = JSON::parse(login.body)

                  if response["success"] == true
                        repeater = true
                  elsif repeater == 3
                        puts "Could not login"
                        puts "exiting"
                       exit
                 else
                       puts "re-trying to login"
                       puts "sleeping for 6 seconds"
                       sleep(6)
                       repeater = repeater + 1
                 end


            end
            if @steamid != nil && @steamid != response["transfer_parameters"]["steamid"]
                  puts "the steamid you provided does not belong to the account you entered"
                  puts "steamid will be overwritten"
                  @steamid = response["transfer_parameters"]["steamid"]

            else
                  @steamid = response["transfer_parameters"]["steamid"]
            end


            response["transfer_urls"].each { |url|
                  @session.post(url, response["transfer_parameters"])
            }



            steampowered_sessionid = ''
            @session.cookies.each { |c|
                  if c.name == "sessionid"
                         steampowered_sessionid = c.value
                   end
            }

            cookie = Mechanize::Cookie.new :domain => 'steamcommunity.com', :name =>'sessionid', :value =>steampowered_sessionid, :path => '/'
            @session.cookie_jar << cookie
            puts "logged-in with steamid: #{@steamid}"
      end
########################################################################################


########################################################################################
      private
      def pass_stamp()
            response = @session.post('https://store.steampowered.com/login/getrsakey/', {'username' => @username})

            data = JSON::parse(response.body)
            mod = data["publickey_mod"].hex
            exp = data["publickey_exp"].hex
            timestamp = data["timestamp"]

            key   = OpenSSL::PKey::RSA.new
            key.e = OpenSSL::BN.new(exp)
            key.n = OpenSSL::BN.new(mod)
            ep = Base64.encode64(key.public_encrypt(@password.force_encoding("utf-8"))).gsub("\n", '')
            return {'password' => ep, 'timestamp' => timestamp }
      end
########################################################################################


end
