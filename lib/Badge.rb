module BadgeCommands

      def sets_count(steamid = @steamid, use_nonmarketable = true)
            if steamid == nil
                  output "no steamid specified"
                  return
            end

            if [TrueClass,FalseClass].include?(steamid.class) && @steamid != nil
                  use_nonmarketable = steamid
                  steamid = @steamid
            elsif [TrueClass,FalseClass].include?(steamid.class) && @steamid == nil
                  raise "You are not logged in and did not specify a steamid"
            end

            steamid,token = verify_profileid_or_trade_link_or_steamid(steamid)
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
            hash = raw_get_inventory(steamid)
            sorted = {}
            classxinstance = {}

            hash["descriptions"].delete_if {|desc|
                  conc = desc["classid"] + "_" +  desc["instanceid"]
                  classxinstance[conc] = desc
                  true
            }

            #GC.start


            hash["assets"].each { |asset|
                  identity = asset["classid"] + "_" + asset["instanceid"]
                  assetdesc = classxinstance[identity]
                  if use_nonmarketable == false
                        if assetdesc["marketable"] == 0 || assetdesc["tags"][-1]["localized_tag_name"] != "Trading Card" || assetdesc["tags"][-2]["localized_tag_name"] == "Foil"
                              next
                        end
                  else
                        if  assetdesc["tags"][-1]["localized_tag_name"] != "Trading Card" ||assetdesc["tags"][-2]["localized_tag_name"] == "Foil"
                              next
                        end
                  end

                  name = assetdesc["name"].sub(" (Trading Card)", "")
                  appid =assetdesc["market_fee_app"].to_s
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

            bigdata = JSON.parse(File.read("#{@libdir}blueprints/byappid.json",:external_encoding => 'utf-8',:internal_encoding => 'utf-8'))
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


            titles = JSON.parse(File.read("#{@libdir}blueprints/appid_title.json",:external_encoding => 'utf-8',:internal_encoding => 'utf-8'))
            eachappidsets = eachappidsets.sort_by do |k,v|
              v
            end
            eachappidsets.reverse!
            output "Writing the badges to #{filename}_badges.txt "
            text = []
            text << "for #{persona}(#{steamid})"
            if use_nonmarketable == false
                  text << "only marketable cards are counted"
                  text << "total non-foil trading cards #{total_non_foil}"
            else
                  text << "total non-foil trading cards #{total_non_foil}"
                  text << "all cards counted including non-marketable"
            end


            text << "total sets in target account #{totalsets}"
            text << ""
            text << ""
            eachappidsets.each { |appid, sets|
                  text << "             #{titles[appid]}, sets = #{sets}, appid = #{appid}"
                  hashofcards[appid].each { |cardname, owned|
                        text << "#{cardname} xxx #{owned}"
                  }
                  text << ""
                  text << ""
            }
            File.open("./#{filename}_badges.txt",'w:UTF-8') {|f| f.puts text}
            output "badges.txt has been created"
      end



end
