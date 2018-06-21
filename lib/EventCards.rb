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




end
