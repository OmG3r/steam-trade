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

            me = clean_items(mine)


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
            output "trade offer sent ID:: " + response["tradeofferid"] + " to #{persona}"
            if response["needs_mobile_confirmation"] == true
                  if @identity_secret != nil && @steamid != nil
                        sleep(0.6)
                        responsehash = response.merge(send_trade_allow_request(response["tradeofferid"]))
                        output "offer confirmed " + response["tradeofferid"]
                        return responsehash
                  else
                        output "cannot confirm trade automatically, no shared secret given"
                        output "Manual confirmation is needed"
                        return nil
                  end
            end

      end



      def get_trade_offers()
            params = {'key'=> @api_key,
                              'get_sent_offers'=> 1,
                              'get_received_offers'=> 1,
                              'get_descriptions'=> 1,
                              'language'=> 'english',
                              'active_only'=> 1,
                              'historical_only'=> 0,
                              'time_historical_cutoff'=> ''}
                              response = api_call('GET', 'IEconService', 'GetTradeOffers', 'v1', params).json()
      end




      def sell_items(items, price)
        raise "no account logged in, #{self} " if @loggedin == false
        raise "Must be given an array" if items.class != Array


        headers = {
              'Origin' => 'https://steamcommunity.com',
              'Referer' => 'https://steamcommunity.com/id/SimplifiedPact/inventory/',
              'User-Agent' => 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/67.0.3396.87 Safari/537.36 OPR/54.0.2952.54',
        }
        i = 0
        items.each { |asset|

          asset['sessionid'] = sessionid_cookie()
          asset['price'] = price
          verd = {'sucess' => false}
          tries = 0

          until verd['success'] == true || tries == 2
                puts "attempting to sell"
                resp = @session.post('https://steamcommunity.com/market/sellitem/', asset, headers)
                verd = JSON.parse(resp.content)

                if verd['success'] == false
                      break if verd['message'].include?('You already have a listing for this') || verd['message'].include?('We were unable to contact')
                      tries += 1
                      sleep(10)
                else
                  puts verd
                  i += 1
                  puts "#{i} / #{items.length} sold"
                  sleep(1)
                end

          end
        }
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
