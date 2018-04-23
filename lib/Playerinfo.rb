module PlayerCommands

      def get_player_summaries(*steamids)
            if steamids.length == 0
                  raise "no steamids supplied"
                  return {'success' => false}
            end
            if @api_key == nil
                  output "no api_key loaded"
                  return {'success' => false}
            end
            write = steamids.join(',')
            html = @session.get("http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=#{@api_key}&steamids=#{write}").content
            return JSON.parse(html)["response"]["players"]
      end

      def get_friends(steamid)
            if @api_key == nil
                  output "no api_key loaded"
                  return {'success' => false}
            end
            html = @session.get("http://api.steampowered.com/ISteamUser/GetFriendList/v0001/?key=#{@api_key}&steamid=#{@steamid}&relationship=friend").content
            return JSON.parse(html)["friendslist"]["friends"]
      end



end
