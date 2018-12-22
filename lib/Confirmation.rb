


module ConfirmationCommands





      def send_trade_allow_request(trade_id) ###FIRST
            confirmations = get_confirmations() ###second
            confirmationhash = select_trade_offer_confirmation(trade_id, confirmations) #seventh
            send_confirmation(confirmationhash) #tenth
      end

      private
      def get_confirmations() ##SECOND
            confirmations = []
            confirmations_page = fetch_confirmations_page()
            Nokogiri::HTML(confirmations_page).css('#mobileconf_list').css('.mobileconf_list_entry').each { |trade|
                  add = {
                        'id' => trade['id'].sub('conf', ''),
                        'data_confid' => trade['data-confid'],
                        'data_key' => trade['data-key']
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
            response = @session.get('https://steamcommunity.com/mobileconf/conf', params, no, headers)
            html = response.content
            if html.include?('Steam Guard Mobile Authenticator is providing incorrect Steam Guard codes.')
                  raise("identity secret: #{@identity_secret} is incorrect")
            end
            return html
      end




      def select_trade_offer_confirmation(trade_id, confirmations) ## seventh
            confirmations.each { |confirmhash|
                  confirmation_details_page = fetch_confirmation_details_page(confirmhash) ## eighteth
                  confirm_id = get_confirmation_trade_offer_id(confirmation_details_page) ## nineth
                  if confirm_id == trade_id
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
            params = create_confirmation_params(tag) ## EXISTS
            params['op'] = tag
            params['cid'] = confirmationhash["data_confid"]
            params['ck'] = confirmationhash["data_key"]
            headers = {'X-Requested-With' => 'XMLHttpRequest'}
            #@session.pre_connect_hooks << lambda do |agent, request|
            #     request['X-Requested-With'] = 'XMLHttpRequest'
            #end
            no = nil
            page = @session.get('https://steamcommunity.com/mobileconf/ajaxop', params,no ,headers)
            return JSON.parse(page.content)
      end

end
