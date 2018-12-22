module OfferState
     Invalid = 1
    Active = 2
    Accepted = 3
    Countered = 4
    Expired = 5
    Canceled = 6
    Declined = 7
    InvalidItems = 8
    ConfirmationNeed = 9
    CanceledBySecondaryFactor = 10
    StateInEscrow = 11
end

module OfferConfirm
      Invalid = 1
      Email = 2
      MobileApp = 3
end

module TradeAPI
      def get_trade_offers(time = "")
            raise "have no API_key, cannot get trade offers" if @api_key == nil
            params = {'key'=> @api_key,
                              'get_sent_offers'=> 1,
                              'get_received_offers'=> 1,
                              'get_descriptions'=> 1,
                              'language'=> 'english',
                              'active_only'=> 1,
                              'historical_only'=> 0,
                              'time_historical_cutoff'=> time.to_i}
                              data = JSON.parse(api_call('GET', 'IEconService', 'GetTradeOffers', 'v1', params))["response"]
                              return data
      end

      def accept_trade_offer(trade_offer_id)
            raise "You are not logged in " if @loggedin == false
            trade = get_trade_offer(trade_offer_id)
            trade_offer_state = trade["offer"]['trade_offer_state']
            raise "Cannot accept trade #{trade_offer_id}" if trade_offer_state != OfferState::Active


            partner = trade["offer"]['accountid_other']
            session_id = sessionid_cookie()
            accept_url = "https://steamcommunity.com" + '/tradeoffer/' + trade_offer_id + '/accept'
            params = {'sessionid'=> session_id,
                                    'tradeofferid'=> trade_offer_id,
                                    'serverid'=> '1',
                                    'partner'=> partner,
                                    'captcha'=> ''}
            headers = {'Referer'=> "https://steamcommunity.com/tradeoffer/#{trade_offer_id}"}
            response = JSON.parse(@session.post(accept_url, params, headers).content)
            output "trade offer confirmed"
            if response.key?('needs_mobile_confirmation') == true
                  re = send_trade_allow_request(trade_offer_id)
                  output "trade offer confirmed"
                  return re
            end
            return response
      end

      def get_trade_offer(trade_offer_id)
            raise "have no API_key, cannot get the trade offer" if @api_key == nil
            params = {'key' => @api_key,
                           'tradeofferid'=>trade_offer_id,
                           'language'=> 'english'}
            response = JSON.parse(api_call('GET', 'IEconService', 'GetTradeOffer', 'v1', params))
            return response["response"]
     end

     def decline_trade_offer(trade_offer_id)
            raise "have no API_key, cannot decline the trade offer" if @api_key == nil
           params = {'key'=> @api_key,
                                    'tradeofferid'=> trade_offer_id}
            return JSON.parse(api_call('POST', 'IEconService', 'DeclineTradeOffer', 'v1', params))
      end

     def cancel_trade_offer(trade_offer_id)
            raise "have no API_key, cannot cancel the trade offer" if @api_key == nil
             params = {'key'=> @api_key,
                        'tradeofferid'=> trade_offer_id}
            return JSON.parse(api_call('POST', 'IEconService', 'CancelTradeOffer', 'v1', params))

      end






end
