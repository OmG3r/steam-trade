require 'mechanize'
require 'json'
require 'openssl'
require 'base64'
require 'open-uri'
require 'thread'


require_relative './LoginExecutor.rb'
require_relative './Misc.rb'
require_relative './Trade.rb'
require_relative './Confirmation.rb'
require_relative './Trade.rb'
require_relative './Inventory.rb'
require_relative './Badge.rb'
require_relative './Guard.rb'
require_relative './Playerinfo.rb'
require_relative './IEconService.rb'
require_relative './Social.rb'
require_relative './EventCards.rb'
class Handler
      include MiscCommands
      include LoginCommands
      include TradeCommands
      include ConfirmationCommands
      include GuardCommands
      include InventoryCommands
      include BadgeCommands
      include GuardCommands
      include PlayerCommands
      include TradeAPI
      include SocialCommands
      include EventCommands
      def initialize(username = nil ,password = nil,*params)
           raise "can only take 5 params, given #{params.length}" if params.length > 3

            @loggedin = false # will be set to true once we login

            @username = nil
            @password = nil
            @secret = nil
            @time_difference = 0
            @remember = false

            @session = Mechanize.new { |a| # the session which will hold your cookies to communicate with steam
                  a.user_agent_alias = 'Windows Mozilla'
                  a.follow_meta_refresh = true
                  a.history_added = Proc.new {sleep 1}
               #   a.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
            }

            @steamid = nil # will be initialized once you login and can be initialized with mobile_info
            @identity_secret = nil # can and should be initialized using mobile_info
            @api_key = nil # can be initalized through set_api_key or will be initialized once you login if possilbe
            @persona = nil # will be initialized once you login
            @android_id = nil


            @inventory_cache = false
            @libdir = Util.gem_libdir
            @messages = true


            @chat_session = nil ## will be initialized if neededs
            @oauth_token = nil #required to send messages
            @umqid = nil # required to send messages
            @message_id = nil #requires to send messages








            (@username.nil? || @username.class == Hash) ? (output "Handler started") : ( output "Handler started for #{@username}")

            if username.class == String && password.class == String
                  @username = username
                  @password = password


                  if params.length == 3
                        raise "shared_secret must be string, received #{params[0].class}" if params[0].class != String
                        raise "time difference must be a Numeric, received #{params[1].class}" if !params[1].is_a?(Numeric)
                        raise "remember_me must be a boolean, received #{params[2].class}" if !([TrueClass,FalseClass].include?(params[2].class))
                        @secret = params[0] if params[0].class == String
                        @time_difference = params[1] if params[1].is_a?(Numeric)
                        @remember = params[2] if [TrueClass,FalseClass].include?(params[2].class)
                  elsif params.length == 2
                        if params[0].class == String
                              raise "invalid fourth parameter type, received #{params[1].class}" if !([TrueClass,FalseClass].include?(params[1].class)) && !params[1].is_a?(Numeric)
                              @secret = params[0]
                              @time_difference = params[1] if params[1].is_a?(Numeric)
                              @remember = params[1] if [TrueClass,FalseClass].include?(params[1].class)
                        elsif params[0].is_a?(Numeric)
                             raise "remember_me must be a boolean, received #{params[1].class}" if !([TrueClass,FalseClass].include?(params[1].class))
                             @time_difference = params[0]
                             @remember = params[1]
                       else
                             raise "invalid third parameter type"
                       end
                 elsif params.length == 1
                        raise "invalid third parameter type, received #{params[0].class}" if !([TrueClass,FalseClass].include?(params[0].class)) && !params[0].is_a?(Numeric) && params[0].class != String
                       @secret = params[0] if params[0].class == String
                       @time_difference = params[0] if params[0].is_a?(Numeric)
                       @remember = params[0] if [TrueClass,FalseClass].include?(params[0].class)
                 end

                 login()
           elsif username.class == Hash
                 password.nil? ? (calcule = 1;) : (calcule = 2 + params.length)
                 raise "given #{calcule} parameters expected less or equal to params 4  " if calcule > 4
                 if calcule > 1
                       if params.length == 0


                             raise "invalid parameter type, received #{password.class}" if !(password.class == String || params[0].is_a?(Numeric) || [TrueClass,FalseClass].include?(password.class) )
                             @secret = password if  password.class == String
                             @time_difference =  password if  password.is_a?(Numeric)
                             @remember =  password if [TrueClass,FalseClass].include?(password.class)


                       elsif params.length == 1


                             if password.class == String
                                   @secret = password
                                   raise "invalid paramter type, received #{params[0].class}" if !([TrueClass,FalseClass].include?(params[0].class) || params[0].is_a?(Numeric) )
                                   @time_difference = params[0] if params[0].is_a?(Numeric)
                                   @remember = params[0] if [TrueClass,FalseClass].include?(params[0].class)
                             elsif password.is_a?(Numeric)
                                   @time_difference = password
                                   raise "invalid paramter type, received #{params[0].class}" if !([TrueClass,FalseClass].include?(params[0].class))
                                   @remember = params[0] if [TrueClass,FalseClass].include?(params[0].class)
                             else
                                   raise "invalid parameter type, received #{password.class}"
                             end


                       elsif params.length == 2
                             raise "shared_secret must be a string, recieved #{password.class}" if password.class != String
                             @secret = password if  password.class == String
                             raise "time difference must be a Numeric, received #{params[0].class}" if !params[0].is_a?(Numeric)
                             @time_difference = params[0] if params[0].is_a?(Numeric)
                             raise "remeber_me must be a boolean, recieved #{params[1].class}" if !([TrueClass,FalseClass].include?(params[1].class))
                             @remember = params[1] if [TrueClass,FalseClass].include?(params[1].class)

                       end

                 end

                 load_cookies(username)
                 
                 begin
                       text = Nokogiri::HTML(@session.get("https://steamcommunity.com/dev/apikey").content).css('#bodyContents_ex').css('p').first.text.sub('Key: ','')
                       if text.include?('Registering for a Steam Web API Key will enable you to access many Steam features from your own website') == false
                             @api_key = text
                       end
                 rescue
                       output "Could not retrieve api_key"
                 end
           end


      end


      def mobile_info(identity_secret, steamid = nil)
            @identity_secret = identity_secret
            @steamid = steamid if  @steamid == nil && steamid != nil
      end

      def set_inventory_cache(timer = 120)
            if timer.is_a?(Numeric)
                  @inventory_validity = timer.to_i
                  output "inventory validity set to #{timer}"
            end


            if @inventory_cache == false
                  @inventory_cache = true
                  output "inventory cache enabled"
            else
                  @inventory_cache == false
                  output "inventory cache disabled"
            end
      end

      def set_api_key(api_key)
            @api_key = api_key
      end

      def toggle_messages()
            @messages == true ?  (output "messages are now disabled"; @messages = false;) : (output "messages are now enabled";@messages = true;)
     end




      def get_auth_cookies()
            data = {}
            #data['sessionid'] = @session.cookie_jar.jar["steamcommunity.com"]["/"]["sessionid"].value

            begin
                  data['steamLogin'] = @session.cookie_jar.jar["store.steampowered.com"]["/"]["steamLogin"].value
                  if data['steamLogin'].nil?
                        data['steamLogin'] = @session.cookie_jar.jar["steamcommunity.com"]["/"]["steamLogin"].value
                  end
            rescue

            end


            data['steamLoginSecure'] = @session.cookie_jar.jar["store.steampowered.com"]["/"]["steamLoginSecure"].value
            if data['steamLoginSecure'].nil?
                   data['steamLoginSecure'] = @session.cookie_jar.jar["steamcommunity.com"]["/"]["steamLoginSecure"].value
            end

            if @steamid != nil

                        data["steamMachineAuth#{@steamid}"] = @session.cookie_jar.jar["store.steampowered.com"]["/"]["steamMachineAuth#{@steamid}"].value
                  if data["steamMachineAuth#{@steamid}"].nil?
                         data["steamMachineAuth#{@steamid}"] = @session.cookie_jar.jar["steamcommunity.com"]["/"]["steamMachineAuth#{@steamid}"].value
                  end

            else

                  @session.cookies.each { |c|
                        if c.downcase.include?('steammachine')
                              data[c] = c.value
                         end
                  }
            end

            data['store_sessionid'] = store_cookie()
            data['community_sessionid'] = sessionid_cookie()
            begin
                  data['steamRememberLogin'] =  @session.cookie_jar.jar["store.steampowered.com"]["/"]['steamRememberLogin'].value
            rescue
            end

            return data


      end


      def load_android_id(str)
            @android_id = str
      end

      private
      def load_cookies(data,session = @session)
            container = []
            data.each { |name, value|
                  if name.include?("steamMachineAuth")
                        container << (Mechanize::Cookie.new :domain => 'store.steampowered.com', :name => name , :value => value, :path => '/')
                        container << (Mechanize::Cookie.new :domain => 'steamcommunity.com', :name => name , :value =>value, :path => '/')
                        container << (Mechanize::Cookie.new :domain => 'help.steampowered.com', :name => name , :value => value, :path => '/')
                        @steamid = name.sub('steamMachineAuth', '')
                  elsif name == 'steamLogin'
                        container << (Mechanize::Cookie.new :domain => 'store.steampowered.com', :name => name , :value => value, :path => '/')
                        container << (Mechanize::Cookie.new :domain => 'steamcommunity.com', :name => name , :value =>value, :path => '/')
                        container << (Mechanize::Cookie.new :domain => 'help.steampowered.com', :name => name , :value => value, :path => '/')
                  elsif name == 'steamLoginSecure'
                        container << (Mechanize::Cookie.new :domain => 'store.steampowered.com', :name => name , :value => value, :path => '/')
                        container << (Mechanize::Cookie.new :domain => 'steamcommunity.com', :name => name , :value =>value, :path => '/')
                        container << (Mechanize::Cookie.new :domain => 'help.steampowered.com', :name => name , :value => value, :path => '/')
                  elsif name == 'store_sessionid'
                        container << (Mechanize::Cookie.new :domain => 'store.steampowered.com', :name => 'sessionid' , :value => value, :path => '/')
                  elsif name == 'community_sessionid'
                        container << (Mechanize::Cookie.new :domain => 'steamcommunity.com', :name => 'sessionid' , :value =>value, :path => '/')
                  elsif name == 'steamRememberLogin'
                        container << (Mechanize::Cookie.new :domain => 'store.steampowered.com', :name => name , :value => value, :path => '/')
                       container << (Mechanize::Cookie.new :domain => 'steamcommunity.com', :name => name , :value =>value, :path => '/')
                       container << (Mechanize::Cookie.new :domain => 'help.steampowered.com', :name => name , :value => value, :path => '/')
                  end
            }

            container.each { |cookie|
                session.cookie_jar << cookie
            }

            user = Nokogiri::HTML(session.get('https://steamcommunity.com/').content).css('#account_pulldown').text
            raise "Could not login using cookies" if user ==  ''
            if session == @session
                  @loggedin = true
                  @username = user
                  output "logged in as #{user}"
            end
      end





end
