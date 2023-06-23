module ConfirmationCommands





      def send_trade_allow_request(trade_id) ###FIRST
            # {     "type"=>2, "type_name"=>"Trade Offer", "id"=>"13813608014",
            #       "creator_id"=>"6154146793", "nonce"=>"12026724049760759094",
            #       "creation_time"=>1687514850, "cancel"=>"Cancel",
            #       "accept"=>"Send Offer",
            #       "multi"=>false, "headline"=>"Nicardo",
            #       "warn"=>nil
            # }
            # {
            #       "type"=>3, "type_name"=>"Market Listing", "id"=>"13809682251",
            #       "creator_id"=>"4295919183828680123", "nonce"=>"9979474839352938391",
            #       "creation_time"=>1687449333, "cancel"=>"Cancel",
            #       "accept"=>"Create Listing",
            #       "multi"=>true,
            #       "headline"=>"Selling for 75₴",
            #       "summary"=>["Revolution Case"], "warn"=>nil
            # }
            confirmations = get_confirmations() ###second
            confirmationhash = select_trade_offer_confirmation(trade_id, confirmations) #seventh
            send_confirmation(confirmationhash) #tenth
      end

      def confirm_all()
        send_array_confirmation(get_confirmations())
      end
      private
      def get_confirmations() ##SECOND
            confirmations = []
            confirmations_page = fetch_confirmations_page()

            JSON.parse(confirmations_page, symbolize_names: true)[:conf].each { |trade|
                  add = {
                        'id' => trade[:creator_id],
                        'data_confid' => trade[:id],
                        'data_key' => trade[:nonce]
                  }
                  confirmations <<  add
            }
            return confirmations
      end

      def create_confirmation_params(tag_string) #FOURTH FINISHED
            timestamp = Time.new.to_i
            confirmation_key = generate_confirmation_key(tag_string,timestamp) # FIFTH other  FILE FINISHED
            android_id = generate_device_id() # SIXTH other  FILE FINISHED
            res = {
                  'p' => android_id,
                  'a' => @steamid,
                  'k' => confirmation_key,
                  't' => timestamp,
                  'm' => 'android',
                  'tag' => tag_string
            }
            return res
      end

      def fetch_confirmations_page() ## THIRD FINISHED
            tag = 'conf'
            params =   create_confirmation_params(tag) ## FOURTH FIISHED
            headers = {'X-Requested-With' => 'com.valvesoftware.android.steam.community'}

            no = nil

            response = @session.get('https://steamcommunity.com/mobileconf/getlist', create_confirmation_params(tag), no, headers)
            html = response.content
            if html.include?('Steam Guard Mobile Authenticator is providing incorrect Steam Guard codes.')
                  raise("identity secret: #{@identity_secret} is incorrect")
            end
            return html
      end




      def select_trade_offer_confirmation(trade_id, confirmations) ## seventh

            confirmations.each { |confirmhash|
                  if confirmhash['id'] == trade_id
                        return confirmhash
                  end
            }
            raise("Could not find the offer to confirm")
      end

      def fetch_confirmation_details_page(hash) ##eigth
            var = hash['id']
            tag = 'details' + var
            params = create_confirmation_params(tag) ## EXISTS
            response = @session.get("https://steamcommunity.com/mobileconf/details/#{var}", params)
            return JSON.parse(response.content)["html"]
      end

      def get_confirmation_trade_offer_id(html) ## nineth
            full_offer_id = Nokogiri::HTML(html).css('.tradeoffer')[0]['id']
            return full_offer_id.split('_', 2)[1]
      end

      def send_confirmation(confirmationhash) ## tenth
            tag = 'allow'
            params = create_confirmation_params('conf') ## EXISTS
            params['op'] = tag
            params['cid'] = confirmationhash["data_confid"]
            params['ck'] = confirmationhash["data_key"]
            headers = {'X-Requested-With' => 'XMLHttpRequest'}
            no = nil
            page = @session.get('https://steamcommunity.com/mobileconf/ajaxop', params,no ,headers)
            return JSON.parse(page.content)
      end



      def send_array_confirmation(conf_array)
        i = 0
        conf_array.each { |confirmationhash|
          begin
            tag = 'allow'
            params = create_confirmation_params('conf') ## EXISTS
            params['op'] = tag
            params['cid'] = confirmationhash["data_confid"]
            params['ck'] = confirmationhash["data_key"]
            headers = {'X-Requested-With' => 'XMLHttpRequest'}
            #@session.pre_connect_hooks << lambda do |agent, request|
            #     request['X-Requested-With'] = 'XMLHttpRequest'
            #end
            no = nil
            page = @session.get('https://steamcommunity.com/mobileconf/ajaxop', params,no ,headers)
            i = i + 1
            puts "confirmed #{i} / #{cof_array.length}"
          rescue
            sleep(2)
          end
        }

      end

end
