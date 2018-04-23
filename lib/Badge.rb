module BadgeCommands

      def sets_count(steamid = @steamid, use_nonmarketable = true)


            if steamid == nil
                  output "no steamid specified"
                  return
            end

            thread = Thread.new(steamid) { |steamid| ##getting name
                  targetname = ''
                  begin
                         data = get_player_summaries(steamid)
                         data.each { |acc|
                              if id["steamid"].to_s == steamid.to_s
                                    targetname = id["personaname"]
                              end
                        }
                  rescue
                        targetname = ''
                  end
            }

            items = normal_get_inventory(steamid)
            sorted = {}
            items.each { |asset|
                  if use_nonmarketable == false
                        if asset["marketable"] == 0 || asset["tags"][-1]["localized_tag_name"] != "Trading Card" || asset["tags"][-2]["localized_tag_name"] == "Foil"
                              next
                        end
                  else
                        if  asset["tags"][-1]["localized_tag_name"] != "Trading Card" || asset["tags"][-2]["localized_tag_name"] == "Foil"
                              next
                        end
                  end

                  name = asset["name"].sub(" (Trading Card)", "")
                  appid = asset["market_fee_app"].to_s
                  if sorted.has_key?(appid) == true
                        if sorted[appid].has_key?(name) == true
                              sorted[appid][name] = sorted[appid][name] + 1
                        elsif sorted[appid].has_key?(name) == false
                              sorted[appid][name] = 1
                        end
                  elsif sorted.has_key?(appid) == false
                        sorted[appid] = {}
                        sorted[appid][name] = 1
                  end
            }

            bigdata = JSON.parse(File.read("#{@libdir}/blueprints/byappid.json",:external_encoding => 'utf-8',:internal_encoding => 'utf-8'))
            counted = {}

            sorted.each { |appid,cards|


                  counted[appid] = bigdata[appid].merge(cards)
            }

            setsowned = {}
            numberofsets = 0
            total_non_foil = 0

            counted.each { |appid,cards|
                  lowest = 9999
                  cards.each { |cardname, amount|
                              if amount < lowest then lowest = amount end
                              total_non_foil =  total_non_foil + amount
                  }
                  setsowned[appid] = lowest
                  numberofsets = numberofsets + lowest
            }

            persona = thread.value
            write_badges(counted,setsowned,numberofsets,total_non_foil, use_nonmarketable,persona,steamid)
            if use_nonmarketable == false
                  return {'sets' => counted, 'appxsets' => setsowned, 'totalsets' => numberofsets, 'totalcards' => total_non_foil, 'marketable' => false}
            else
                   return {'sets' => counted, 'appxsets' => setsowned, 'totalsets' => numberofsets, 'totalcards' => total_non_foil, 'marketable' => true}
            end
      end


      private
      def write_badges(hashofcards,eachappidsets,totalsets,total_non_foil,use_nonmarketable,persona,steamid)
            if persona == ''
                  filename = steamid
            else
                  filename = persona
            end

            "./#{filename}_badges.txt"
            titles = JSON.parse(File.read("#{@libdir}/blueprints/appid_title.json",:external_encoding => 'utf-8',:internal_encoding => 'utf-8'))
            eachappidsets = eachappidsets.sort_by do |k,v|
              v
            end
            eachappidsets.reverse!
            begin
                  File.truncate("./#{filename}_badges.txt", 0)
            rescue
            end

            File.open("./#{filename}_badges.txt",'a+:UTF-8') {|f| f.puts "for #{persona}(#{steamid})"}
            if use_nonmarketable == false
                  File.open("./#{filename}_badges.txt",'a+:UTF-8') {|f| f.puts "total non-foil trading cards #{total_non_foil}"}
                  File.open("./#{filename}_badges.txt",'a+:UTF-8') {|f| f.puts "only marketable cards are counted"}
            else
                  File.open("./#{filename}_badges.txt",'a+:UTF-8') {|f| f.puts "total non-foil trading cards #{total_non_foil}"}
                  File.open("./#{filename}_badges.txt",'a+:UTF-8') {|f| f.puts "all cards counted including non-marketable"}
            end


            File.open("./#{filename}_badges.txt",'a+:UTF-8') {|f| f.puts "total sets in target account #{totalsets}"}
            File.open("./#{filename}_badges.txt",'a+:UTF-8') {|f| f.puts ""}
            File.open("./#{filename}_badges.txt",'a+:UTF-8') {|f| f.puts ""}


            eachappidsets.each { |appid, sets|
                  File.open("./#{filename}_badges.txt",'a+:UTF-8') {|f| f.puts "#{titles[appid]}, sets = #{sets}, appid = #{appid}"}
                  hashofcards[appid].each { |cardname, owned|
                        File.open("./#{filename}_badges.txt",'a+:UTF-8') {|f| f.puts "#{cardname} xxx #{owned}"}
                  }
                  File.open("./#{filename}_badges.txt",'a+:UTF-8') {|f| f.puts ""}
                  File.open("./#{filename}_badges.txt",'a+:UTF-8') {|f| f.puts ""}
            }

            output "badges.txt has been created"
      end



end
