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
                  begin
                        counted[appid.to_s] = bigdata[appid].merge(cards)
                  rescue
                        output "badges blueprint does not include #{appid}"
                  end
            }
            counted.each { |appid, cards|
                  cards.delete_if { |key,value|
                        key == 'title'
                  }
            }

            setsowned = {}
            numberofsets = 0
            total_non_foil = 0

            counted.each { |appid,cards|
                  lowest = 9999
                  cards.each { |cardname, amount|
                              next if amount.class == String # apptitle
                              if amount < lowest then lowest = amount end
                              total_non_foil =  total_non_foil + amount
                  }
                  setsowned[appid.to_s] = lowest
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




      def update_blueprint()
            session = Mechanize.new

            session.pre_connect_hooks << lambda do |agent, request|
               request['Origin'] = 'http://steam.tools'
               request['Referer'] = 'http://steam.tools/cards/'
               request['User-Agent'] ='Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/65.0.3325.181 Safari/537.36 OPR/52.0.2871.99'
             end


            pag = session.get('http://cdn.steam.tools/data/set_data.json')
            data = JSON.parse(pag.content)
            old = JSON.parse(File.read("#{@libdir}blueprints/byappid.json" ,:external_encoding => 'utf-8',:internal_encoding => 'utf-8'))

            newapps = []
            data["sets"].each { |set|
                  newapps << set['appid']
            }
            get = []
            haveapps = old.keys
            newapps.each { |app|
                  get << app if haveapps.include?(app) == false
            }

            progress = 0
            error = 0
            (output("your blueprint is up-to-date");return) if get.length.zero?
            get.each {|app|
                  begin
                        card = {}
                        steam_nokogiri = Nokogiri::HTML(session.get("http://www.steamcardexchange.net/index.php?inventorygame-appid-#{app}").content)
                        title = steam_nokogiri.css('h2[class=empty]').text.force_encoding(Encoding::UTF_8)
                        steam_nokogiri.css('div[class=name-image-container]').css('span').each do |e|
                              card[e.text.force_encoding(Encoding::UTF_8)] = 0
                        end
                        card['title'] = title
                        full_data = card

                        old[app] = full_data
                        File.open("#{@libdir}blueprints/byappid.json", 'w:UTF-8') {|f| f.puts old.to_json}

                        progress = progress + 1
                        output "#{progress} / #{get.length} done, error = #{error}"
                  rescue Exception => e
                        File.open("#{@libdir}blueprints/byappid.json", 'w:UTF-8') {|f| f.puts old.to_json}
                        error = error + 1
                        progress = progress + 1
                        output "#{progress} / #{get.length} done, error = #{error}"
                        output "error occured saved data"
                        raise e
                  end
            }


      end





      private
      def write_badges(hashofcards,eachappidsets,totalsets,total_non_foil,use_nonmarketable,persona,steamid)
            if persona == ''
                  filename = steamid
            else
                  filename = persona
            end


             bigdata = JSON.parse(File.read("#{@libdir}blueprints/byappid.json",:external_encoding => 'utf-8',:internal_encoding => 'utf-8'))
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
                  w_title = bigdata[appid]['title']
                  text << "             #{w_title}, sets = #{sets}, appid = #{appid}"
                  hashofcards[appid].each { |cardname, owned|
                        next if !owned.is_a?(Numeric)
                        text << "#{cardname} xxx #{owned}"
                  }
                  text << ""
                  text << ""
            }
            File.open("./#{filename}_badges.txt",'w:UTF-8') {|f| f.puts text}
            output "badges.txt has been created"
      end

      def self.included(base)
           base.extend(BadgeCommands_ClassMethods)
      end

      module BadgeCommands_ClassMethods
            @@libdir = Util.gem_libdir
            def sets_count(steamid, use_nonmarketable = true)




                  steamid,token = verify_profileid_or_trade_link_or_steamid(steamid)

                  hash = raw_get_inventory(steamid)
                  sorted = {}
                  classxinstance = {}

                  hash["descriptions"].delete_if {|desc|
                        conc = desc["classid"] + "_" +  desc["instanceid"]
                        classxinstance[conc] = desc
                        true
                  }



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

                  bigdata = JSON.parse(File.read("#{@@libdir}blueprints/byappid.json",:external_encoding => 'utf-8',:internal_encoding => 'utf-8'))

                  counted = {}

                  sorted.each { |appid,cards|
                        begin
                              counted[appid.to_s] = bigdata[appid].merge(cards)
                        rescue
                              output "badges blueprint does not include #{appid}"
                        end
                  }

                  counted.each { |appid, cards|
                        cards.delete_if { |key,value|
                              key == 'title'
                        }
                  }
                  setsowned = {}
                  numberofsets = 0
                  total_non_foil = 0

                  counted.each { |appid,cards|
                        lowest = 9999
                        cards.each { |cardname, amount|
                                    next if amount.class == String # apptitle
                                    if amount < lowest then lowest = amount end
                                    total_non_foil =  total_non_foil + amount
                        }
                        setsowned[appid.to_s] = lowest
                        numberofsets = numberofsets + lowest
                  }

                  persona = ''
                  write_badges(counted,setsowned,numberofsets,total_non_foil, use_nonmarketable,persona,steamid)
                  if use_nonmarketable == false
                        return {'sets' => counted, 'appxsets' => setsowned, 'totalsets' => numberofsets, 'totalcards' => total_non_foil, 'marketable' => false}
                  else
                         return {'sets' => counted, 'appxsets' => setsowned, 'totalsets' => numberofsets, 'totalcards' => total_non_foil, 'marketable' => true}
                  end
            end




            def update_blueprint()
                  session = Mechanize.new

                  session.pre_connect_hooks << lambda do |agent, request|
                     request['Origin'] = 'http://steam.tools'
                     request['Referer'] = 'http://steam.tools/cards/'
                     request['User-Agent'] ='Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/65.0.3325.181 Safari/537.36 OPR/52.0.2871.99'
                   end


                  pag = session.get('http://cdn.steam.tools/data/set_data.json')
                  data = JSON.parse(pag.content)
                  old = JSON.parse(File.read("#{@@libdir}blueprints/byappid.json" ,:external_encoding => 'utf-8',:internal_encoding => 'utf-8'))

                  newapps = []
                  data["sets"].each { |set|
                        newapps << set['appid']
                  }
                  get = []
                  haveapps = old.keys
                  newapps.each { |app|
                        get << app if haveapps.include?(app) == false
                  }

                  progress = 0
                  error = 0
                  (output("your blueprint is up-to-date");return) if get.length.zero?
                  get.each {|app|
                        begin
                              card = {}
                              steam_nokogiri = Nokogiri::HTML(session.get("http://www.steamcardexchange.net/index.php?inventorygame-appid-#{app}").content)
                              title = steam_nokogiri.css('h2[class=empty]').text.force_encoding(Encoding::UTF_8)
                              steam_nokogiri.css('div[class=name-image-container]').css('span').each do |e|
                                    card[e.text.force_encoding(Encoding::UTF_8)] = 0
                              end
                              card['title'] = title
                              full_data = card

                              old[app] = full_data
                              File.open("#{@@libdir}blueprints/byappid.json", 'w:UTF-8') {|f| f.puts old.to_json}

                              progress = progress + 1
                              output "#{progress} / #{get.length} done, error = #{error}"
                        rescue Exception => e
                              File.open("#{@@libdir}blueprints/byappid.json", 'w:UTF-8') {|f| f.puts old.to_json}
                              error = error + 1
                              progress = progress + 1
                              output "#{progress} / #{get.length} done, error = #{error}"
                              output "error occured saved data"
                              raise e
                        end
                  }


            end





            private
            def write_badges(hashofcards,eachappidsets,totalsets,total_non_foil,use_nonmarketable,persona,steamid)
                  if persona == ''
                        filename = steamid
                  else
                        filename = persona
                  end


                   bigdata = JSON.parse(File.read("#{@@libdir}blueprints/byappid.json",:external_encoding => 'utf-8',:internal_encoding => 'utf-8'))
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
                        w_title = bigdata[appid]['title']
                        text << "             #{w_title}, sets = #{sets}, appid = #{appid}"
                        hashofcards[appid].each { |cardname, owned|
                              next if !owned.is_a?(Numeric)
                              text << "#{cardname} xxx #{owned}"
                        }
                        text << ""
                        text << ""
                  }
                  File.open("./#{filename}_badges.txt",'w:UTF-8') {|f| f.puts text}
                  output "badges.txt has been created"
            end



      end


end
