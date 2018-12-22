module EventCommands

      def finish_queue()
            raise "you must be logged in to finish a queue" if @loggedin == false

            params = {
                  'sessionid' => store_cookie(),
                  'queuetype' => 0
            }

            headers = {
                  'Origin' => 'https://store.steampowered.com/',
                  'Referer' => 'https://store.steampowered.com/explore/'
            }


            resp = @session.post('https://store.steampowered.com/explore/generatenewdiscoveryqueue', params , headers).content


            data = JSON.parse(resp)
            queue = data['queue']
            first = queue[0]
            page = @session.get("https://store.steampowered.com/app/#{first}")
            next_game = page.form_with(:id => 'next_in_queue_form')
            next_page = nil
            i = 0
            until next_game.nil?
                  i += 1
                  print i.to_s + " "

                  success = false
                  until success
                        begin
                              next_page = next_game.submit
                              success = true
                        rescue StandardError => e
                              sleep(1)
                        end
                  end

                  next_game = next_page.form_with(:id => 'next_in_queue_form')
            end


           parser = Nokogiri::HTML(next_page.content).css('.discover_queue_empty').css('.discovery_queue_winter_sale_cards_header')

           h3 =  parser.css('h3').text
           subtext = parser.css('.subtext').text
           puts ""
           output(h3)
           output(subtext)

           total = @username + " :: " + h3
           done  = @username + " :: " + subtext

           return {'total' => total, 'done' => done}

      end

      def salien_card()
            raise "must be logged in to use the command" if @logged == false
            @saliened = [] if @saliened.nil?


            data = @session.get('https://steamcommunity.com/saliengame/gettoken')
            data = JSON.parse(data.content)
            game_token = data['token']


            headers = {
                  'origin' => 'https://steamcommunity.com',
                  'referer' => 'https://steamcommunity.com/saliengame/play/'
            }

            params = {
                  'access_token' => game_token
            }

            data = @session.post('https://community.steam-api.com/ITerritoryControlMinigameService/GetPlayerInfo/v0001/', params, headers)
            data = JSON.parse(data.content)['response']
            planet = data['active_planet']
            active_game = data["active_zone_game"]

            if planet.nil?
                  data = @session.get('https://community.steam-api.com/ITerritoryControlMinigameService/GetPlanets/v0001/?active_only=1&language=english')
                  data = JSON.parse(data.content)['response']
                  planet = data['planets'].first["id"]

                  headers = {
                        'origin' => 'https://steamcommunity.com',
                        'referer' => 'https://steamcommunity.com/saliengame/play/'
                  }

                  params = {
                        'id' => planet,
                        'access_token' => game_token
                  }


                  @session.post('https://community.steam-api.com/ITerritoryControlMinigameService/JoinPlanet/v0001/', params, headers )
            end


            if active_game != nil
                  headers = {
                        'origin' => 'https://steamcommunity.com',
                        'referer' => 'https://steamcommunity.com/saliengame/play/'
                  }

                  params = {
                      'gameid' => active_game,
                      'access_token' => game_token
                  }
                  @session.post('https://community.steam-api.com/IMiniGameService/LeaveGame/v0001/', params, headers)


            end



            data = @session.get("https://community.steam-api.com/ITerritoryControlMinigameService/GetPlanet/v0001/?id=#{planet}&language=english")
            data = JSON.parse(data.content)['response']

            to_play = nil
            left  = []
            data['planets'].first['zones'].each { |zone|
                  if zone['captured'] == false && (@saliened.include?(zone['zone_position']) == false)
                        left << zone['zone_position']

                  end
                  #position = zone['zone_position']
                  #captured = zone['captured']
            }
            to_play = left[rand(left.length - 1)]
            headers = {
                  'Origin' => 'https://steamcommunity.com',
                  'Referer' => 'https://steamcommunity.com/saliengame/play/',
                  'user-agent' => 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.170 Safari/537.36 OPR/53.0.2907.99'
            }

            params = {
                  'zone_position' => to_play,
                  'access_token' => game_token
            }


            @session.post('https://community.steam-api.com/ITerritoryControlMinigameService/JoinZone/v0001/', params, headers)
            sleep(0.3)
            @saliened << to_play
            output "collected 1 salien game card"



      end


      def cottage()
        raise "must be logged in to use the command" if @logged == false

        door_ids = []
        Nokogiri::HTML(@session.get('https://store.steampowered.com/promotion/cottage_2018/').content).css('#alldoors_container').css('.cottage_doorset').each { |door|
          next if door["class"].include?('cottage_door_open')
          door_ids << door['data-door-id']
        }

        if door_ids.empty?
          puts "There are no door to open for #{@username}"
          return
        end


        door_ids.each { |id|


          timestamp = Time.new.strftime("%Y-%m-%dT%H:%M:%S")

          post_params = {
            'sessionid' => store_cookie(),
            'door_index' => id,
            't' => timestamp,
            'open_door' => true
          }

          post_headers = {
            'Origin' => 'https://store.steampowered.com',
            'Referer' => 'https://store.steampowered.com/promotion/cottage_2018/',
            'User-Agent' => 'Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.102 Safari/537.36 OPR/57.0.3098.102',
            'X-Requested-With' => 'XMLHttpRequest'
          }

          @session.post('https://store.steampowered.com/promotion/opencottagedoorajax' , post_params, post_headers)

        }

      end

      def vote_2018()
        text = @session.get('https://store.steampowered.com/SteamAwards/2018/').content
        Nokogiri::HTML(text).css('.steamaward_categories_ctn')[0].css('.vote_category_bg').each { |container|
          container['']
          title = container.css(".category_title")[0].text.downcase
          voteid = container.css(".category_nominations_ctn")[0]["data-voteid"]

          nominees = []
          voted = false
          i = 1
          container.css(".category_nomination").each { |nom|
            (voted = true; break;) if nom["class"].include?('grayed_out_nomination')

            nominees << nom["data-vote-appid"]
          }
          next if voted
          (File.open('./error.html', 'w') {|f| f.puts text}; raise "no nominees selected if";) if nominees.compact!.empty?
          appid = nominees[rand(nominees.length - 1)]


          params = {
            'voteid' => voteid,
            'sessionid' => store_cookie(),
          }
          puts "voting for #{title}"
          if title.include?('developer')
            puts "switching sides"
            params['appid'] = 0
            params['developerid'] = appid
          else
            params['appid'] = appid
            params['developerid'] = 0
          end
          post_headers = {
            'Origin' => 'https://store.steampowered.com',
            'Referer' => 'https://store.steampowered.com/SteamAwards/2018/',
            'User-Agent' => 'Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.102 Safari/537.36 OPR/57.0.3098.102',
            'X-Requested-With' => 'XMLHttpRequest'
          }
          @session.post('https://store.steampowered.com/salevote', params, post_headers)
          puts "voted for #{title}"
          sleep(2)

        }


      end

end
