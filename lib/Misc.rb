
module MiscCommands





      ########################################################################################
      def set_steamid(steamid)
            if @loggedin == false
                  @steamid,token = verify_profileid_or_trade_link_or_steamid(steamid)
                  output "steamID set to #{@steamid}"
            else
                  raise "editing steamID while logged in will cause malfunctions"
            end
      end



      def copy_session()
            return @session
      end
########################################################################################
      def use_session()
            @session
      end
########################################################################################

      def use_chat_session()
            @chat_session
      end






      def partner_id_to_steam_id(account_id)
            unknown_constant = 17825793 # or 0x1100001 idk wtf is this but ....
            first_bytes = [account_id.to_i].pack('i>')
            last_bytes = [unknown_constant].pack('i>')
            collect = last_bytes + first_bytes
            return collect.unpack('Q>')[0].to_s
      end


      def output(message)
            time = Time.new
            add = time.strftime("%d-%m-%Y %H:%M:%S")
            puts "#{add} :: #{@username.to_s} :: #{message}" if message != ''
      end

      def verify_profileid_or_trade_link_or_steamid(steamid)
            if steamid.to_i == 0 && steamid.include?("?partner=") ##supplied trade link
                partner_raw = steamid.split('partner=',2)[1].split('&',2)[0]
                token = steamid.split('token=', 2)[1]
                steamid = partner_id_to_steam_id(partner_raw)
                return [steamid,token]
            elsif steamid.to_i == 0
                  parser = Nokogiri::XML(@session.get("https://steamcommunity.com/id/#{steamid}?xml=1").content)
                  if parser.xpath('//error').text == ('The specified profile could not be found.')
                        raise "No profile with #{steamid} as profileid"
                  end
                  steamid = parser.xpath('//steamID64').text
                  return steamid
            elsif steamid.to_s.length == 17
                  return steamid
            else
                  raise "invalid steamid : #{steamid}, length of received :: #{steamid.to_s.length}, normal is 17" if steamid.to_s.length != 17
            end
      end

      def sessionid_cookie()
            value = nil
            begin
                  value = @session.cookie_jar.jar["steamcommunity.com"]["/"]["sessionid"].value
            rescue
                  @session.get('http://steamcommunity.com')
                  value = @session.cookie_jar.jar["steamcommunity.com"]["/"]["sessionid"].value
            end
            return value
      end

      def store_cookie()
            begin
                  value = @session.cookie_jar.jar["store.steampowered.com"]["/"]["sessionid"].value
            rescue
                  @session.get('http://store.steampowered.com')
                  value = @session.cookie_jar.jar["store.steampowered.com"]["/"]["sessionid"].value
            end
            return value
      end

      def api_call(request_methode, interface, api_methode ,version,params = nil)
            url = ["https://api.steampowered.com","#{interface}", "#{api_methode}", "#{version}"].join('/')
            if request_methode.downcase == "get"
                  response = @session.get(url, params)
            elsif request_methode.downcase == "post"
                  response = @session.get(url,params)
            else
                  raise "invalid request methode : #{request_methode}"
            end
            if response.content.include?("Access is denied")
                  raise "invalid API_key"
            end
            return response.content
      end




      def self.included(base)
           base.extend(Misc_ClassMethods)
      end

      module Misc_ClassMethods
            def partner_id_to_steam_id(account_id)
                  unknown_constant = 17825793 # or 0x1100001 idk wtf is this but ....
                  first_bytes = [account_id.to_i].pack('i>')
                  last_bytes = [unknown_constant].pack('i>')
                  collect = last_bytes + first_bytes
                  return collect.unpack('Q>')[0].to_s
            end

            private
            def output(message)
                  time = Time.new
                  add = time.strftime("%d-%m-%Y %H:%M:%S")
                  puts "#{add} :: #{message}"
            end

            def verify_profileid_or_trade_link_or_steamid(steamid)
                  if steamid.to_i == 0 && steamid.include?("?partner=") ##supplied trade link
                      partner_raw = steamid.split('partner=',2)[1].split('&',2)[0]
                      token = steamid.split('token=', 2)[1]
                      steamid = partner_id_to_steam_id(partner_raw)
                      return [steamid,token]
                  elsif steamid.to_i == 0
                        session = Mechanize.new
                        parser = Nokogiri::XML(session.get("https://steamcommunity.com/id/#{steamid}?xml=1").content)
                        if parser.xpath('//error').text == ('The specified profile could not be found.')
                              raise "No profile with #{steamid} as profileid"
                        end
                        steamid = parser.xpath('//steamID64').text
                        return steamid
                  elsif steamid.to_s.length == 17
                        return steamid
                  else
                        raise "invalid steamid : #{steamid}, length of received :: #{steamid.to_s.length}, normal is 17" if steamid.to_s.length != 17
                  end
            end

      end ## end module


end

module Util
      def self.gem_libdir
            require_relative 'meta/version.rb'
            gem_name = 'steam-trade'
            version = '0.0.5'
           t = ["#{File.dirname(File.expand_path($0))}/#{Meta::GEM_NAME}.rb",
                "#{Gem.dir}/gems/#{Meta::GEM_NAME}-#{Meta::VERSION}/lib/#{Meta::GEM_NAME}.rb"]
               t.each {|i|
                      return i.gsub("#{Meta::GEM_NAME}.rb", '') if File.readable?(i)
                }
               raise "both paths are invalid: #{t}, while getting gemlib directory"
         end
end
