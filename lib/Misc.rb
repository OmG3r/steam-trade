
module MiscCommands





      ########################################################################################
      def set_steamid(steamid)
            @steamid = steamid
      end



      def copy_session
            return @session
      end
########################################################################################
      def overwrite_session(new_session)
            if new_session.class == Mechanize
                  @session = new_session
            end
      end
########################################################################################
      def sessionid_cookie()
            value = nil
            begin
                  value = @session.cookie_jar.jar["steamcommunity.com"]["/"]["sessionid"].value
            rescue
                  value = nil
            end
            if value == nil
                  begin
                        @session.cookie_jar.jar["store.steampowered.com"]["/"]["sessionid"].value
                  rescue
                        value = nil
                  end
            end

            if value == nil
                  @session.cookies.each { |c|
                        if c.name == "sessionid"
                               value = c.value
                         end
                  }
            end
            return value
      end







      private
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
            puts "#{time} :: #{message}"
      end



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
