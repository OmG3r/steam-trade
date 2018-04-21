module TradeCommands


      def clean_items(items)
            items.each { |t|
                  t["amount"] = t["amount"].to_i
                  t.delete_if {|k,v|   k != 'appid' && k != 'contextid' && k != 'assetid' && k != "amount"}
            }
            return items
      end


      def send_offer(mine, they, link, message = '')
            partner_raw = link.split('partner=',2)[1].split('&',2)[0]
            puts "partner_raw : #{partner_raw}"

            token = link.split('token=', 2)[1]
            puts "token : #{token}"

            theirs = clean_items(they)
            print theirs
            puts ""

            me = clean_items(mine)
            print me
            puts ""
            partner_steamid = partner_id_to_steam_id(partner_raw)
            puts "partner_steamid : #{partner_steamid}"

            sessionid = sessionid_cookie()
            puts "sessionid : #{sessionid}"
            params = {
                  'sessionid' => sessionid,
                  'serverid' => 1,
                  'partner' => partner_steamid,
                  'tradeoffermessage' => message,
                  'json_tradeoffer' => {
                        "newversion" => true,
                       "version" => 4,
                       "me" => {
                            "assets" => mine, #create this array
                            "currency" => [],
                            "ready" => false
                       },
                       "them" => {
                            "assets" => theirs, #create this array
                            "currency" => [],
                            "ready" => false
                        }
                  }.to_json, ###ADDED TO JSON FIX
                  'captcha' => '',
                  'trade_offer_create_params' => {'trade_offer_access_token' => token}.to_json ## ADDED TO JSON FIX
            }

            send = @session.post(
                  'https://steamcommunity.com/tradeoffer/new/send',
                  params,
                  {'Referer' =>  'https://steamcommunity.com/tradeoffer/new', 'Origin' => 'https://steamcommunity.com'}
            )
            response = JSON.parse(send.body)
            if response["needs_mobile_confirmation"] == true
                  if @identity_secret != nil && @steamid != nil
                        #@confirmator = ConfirmationExecutor.new(@identity_secret, @steamid, @session)
                        responsehash = response.merge(send_trade_allow_request(response["tradeofferid"]))
                        puts responsehash
                  else
                        puts "cannot confirm trade automatically, informations missing"
                        puts "Please confirm the trade offer manually #{response["tradeofferid"]} "
                  end
            end

      end


end
