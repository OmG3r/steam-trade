module TradeCommands


      def send_offer(mine, they, link, message = '')
            raise "no account logged in, #{self} " if @loggedin == false



            partner_steamid,token = verify_profileid_or_trade_link_or_steamid(link)
            if token == nil
                  verdict = verify_friendship(partner_steamid)
                  persona = verdict["accountname"]
                  if verdict["success"] == false
                        raise "#{partner_steamid} (#{persona}) is not in your friendlist, a trade link is required to send an offer to this account"
                  end
            end



            theirs = clean_items(they)
            print theirs
            puts ""
            me = clean_items(mine)
            print mine
            puts ""

            sessionid = sessionid_cookie()

            params = {
                  'sessionid' => sessionid,
                  'serverid' => 1,
                  'partner' => partner_steamid,
                  'tradeoffermessage' => message,
                  'json_tradeoffer' => {
                        "newversion" => true,
                       "version" => 4,
                       "me" => {
                            "assets" => me, #create this array
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
                  #'trade_offer_create_params' => {'trade_offer_access_token' => token}.to_json ## ADDED TO JSON FIX
            }
            if token != nil
                  params[ 'trade_offer_create_params'] = {'trade_offer_access_token' => token}.to_json
            else # there is no token cause steamid given
                  params[ 'trade_offer_create_params'] = {}.to_json
            end


            send = @session.post(
                  'https://steamcommunity.com/tradeoffer/new/send',
                  params,
                  {'Referer' =>  'https://steamcommunity.com/tradeoffer/new', 'Origin' => 'https://steamcommunity.com'}
            )
            response = JSON.parse(send.body)
            puts "trade offer sent ID:: " + response["tradeofferid"] + " to #{persona}"
            if response["needs_mobile_confirmation"] == true
                  if @identity_secret != nil && @steamid != nil
                        responsehash = response.merge(send_trade_allow_request(response["tradeofferid"]))
                        output "offer confirmed " + response["tradeofferid"]
                  else
                        output "cannot confirm trade automatically, informations missing"
                        output "Manual confirmation is needed"
                  end
            end

      end
      private

      def verify_friendship(steamid)
            find = get_player_summaries(steamid)
            targetname = ''
            find.each { |id|
                  if id["steamid"].to_s == steamid.to_s
                        targetname = id["personaname"]
                  end
            }

            friends = get_friends(steamid)
            friends.each { |f|
                  if f["steamid"].to_s == steamid.to_s
                        return {'success' => true, "accountname" =>targetname}
                  end
            }
            return {'success' => false, 'accountname' => targetname}

      end

      def clean_items(items)
            if items.class == Array
                  items.each { |t|
                        t["amount"] = t["amount"].to_i
                        t.delete_if {|k,v|   k != 'appid' && k != 'contextid' && k != 'assetid' && k != "amount"}
                        if !(t.keys.include?('appid') && t.keys.include?('contextid') && t.keys.include?('assetid') && t.keys.include?('amount'))
                              z = "Invalid asset data detected #{t}" + "normal should include keys: appid, contextid, assetid, amount"
                              raise "#{z}"
                        end
                  }

            elsif items.class == Hash

                  items["amount"] = items["amount"].to_i
                  items.delete_if {|k,v|   k != 'appid' && k != 'contextid' && k != 'assetid' && k != "amount"}
                  if !(items.keys.include?('appid') && items.keys.include?('contextid') && items.keys.include?('assetid') && items.keys.include?('amount'))
                        z = "Invalid asset data detected #{items}" + "normal should include keys: appid, contextid, assetid, amount"
                        raise "#{z}"
                  end
                  items = [items] ## steam only accepts arrays
            else
                  raise "invalid items type received :: #{items.class}"
            end


            return items
      end




end
