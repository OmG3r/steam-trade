module LoginCommands

########################################################################################
     private
      def login()
            response = @session.post('https://steamcommunity.com/login/getrsakey/', {'username' => @username}).content
            data = pass_stamp(response,@password)
            encrypted_password = data["password"]
            timestamp = data["timestamp"]
            repeater = 0


            send = {
                  'password' => encrypted_password,
                  'username' => @username,
                  'twofactorcode' =>'', #update
                  'emailauth' => '',
                  'loginfriendlyname' => '',
                  'captchagid' => '-1',
                  'captcha_text' => '',
                  'emailsteamid' => '',
                  'rsatimestamp' => timestamp,
                  'remember_login' => @remember
            }
            login = @session.post('https://steamcommunity.com/login/dologin', send).content
            firstreq = JSON.parse(login)

            raise "Incorrect username or password" if firstreq["message"] == "The account name or password that you have entered is incorrect."


            until firstreq["success"] == true
                  sleep(0.3)
                  gid = '-1'
                  cap = ''
                  if firstreq['captcha_needed'] == true
                        gid = firstreq['captcha_needed']
                        File.delete("./#{username}_captcha.png") if File.exist?("./#{username}_captcha.png")
                        @session.get("https://steamcommunity.com/login/rendercaptcha?gid=#{gid}").save "./#{@username}_captcha.png"
                        puts "you need to write a captcha to continue"
                        puts "there is an image named #{@username}_captcha in the script directory"
                        puts "open it and write the captha here"
                        cap = gets.chomp
                  end
                  emailauth = ''
                  facode = ''
                  emailsteamid = ''
                  if firstreq['requires_twofactor'] == true
                        if @secret.nil?
                              puts "write 2FA code"
                              facode = gets.chomp
                        else
                              facode = fa(@secret,@time_difference)
                        end
                  elsif firstreq['emailauth_needed'] == true
                        emailsteamid = firstreq['emailsteamid']
                        puts "Guard code was sent to your email"
                        puts "write the code"
                        emailauth = gets.chomp
                  end

                  send = {
                        'password' => encrypted_password,
                        'username' => @username,
                        'twofactorcode' => facode, #update
                        'emailauth' => emailauth,
                        'loginfriendlyname' => '',
                        'captchagid' => gid,
                        'captcha_text' => cap,
                        'emailsteamid' => emailsteamid,
                        'rsatimestamp' => timestamp,
                        'remember_login' => @remember
                  }
                  output "attempting to login"
                  login = @session.post('https://steamcommunity.com/login/dologin', send ).content
                  firstreq = JSON.parse(login)

            end
            response = firstreq





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
            @loggedin = true
            begin
                  text = Nokogiri::HTML(@session.get("https://steamcommunity.com/dev/apikey").content).css('#bodyContents_ex').css('p').first.text.split(' ')
                  if text.include?('Registering for a Steam Web API Key will enable you to access many Steam features from your own website') == false
                        @api_key = text[1]
                  end
            rescue
                  output "Could not retrieve api_key"
            end

            if !@api_key.nil?
                  data = get_player_summaries(@steamid) if !@api_key.nil?
                  data.each { |element|
                        if element["steamid"].to_s == @steamid.to_s
                              @persona = element["personaname"]
                        end
                  }
            end
            output "logged in as #{@persona}"
            output "your steamid is #{@steamid}"
            output "loaded API_KEY : #{@api_key}" if !@api_key.nil?
      end
########################################################################################


########################################################################################
      def pass_stamp(give,password)

            data = JSON::parse(give)
            mod = data["publickey_mod"].hex
            exp = data["publickey_exp"].hex
            timestamp = data["timestamp"]

            key   = OpenSSL::PKey::RSA.new
            if RUBY_VERSION.to_f <= 2.3
                  key.e = OpenSSL::BN.new(exp)
                  key.n = OpenSSL::BN.new(mod)
            elsif RUBY_VERSION.to_f >= 2.4
                  #key.set_key(n, e, d)
                  key.set_key(OpenSSL::BN.new(mod), OpenSSL::BN.new(exp),nil)
            end
            ep = Base64.encode64(key.public_encrypt(password.force_encoding("utf-8"))).gsub("\n", '')
            return {'password' => ep, 'timestamp' => timestamp }
      end
########################################################################################


end
