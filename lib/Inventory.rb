module InventoryCommands





      def normal_get_inventory(steamid = @steamid ,appid = 753)
            if steamid == nil
                raise "not logged-in and no steamid specified"
            end
            appid = appid.to_s
            context = 6
            #verify given appid only
            if (3..6).to_a.include?(steamid.to_i.to_s.length)
                  raise "You cannot give an appid only if you are not logged in" if @steamid == nil
                  appid = steamid.to_s
                  steamid = @steamid
            end
            # end given appid only
            #verify given another game
            if appid.to_s != "753"
                  context = 2
            end
            #end verify given another game
            # end verify given appid only
            #verify trade link
            steamid,token = verify_profileid_or_trade_link_or_steamid(steamid)
            raise "invalid steamid : #{steamid}, length of received :: #{steamid.to_s.length}, normal is 17" if steamid.to_s.length != 17
            ## verify appid
            if ["753","730",'570','440'].include?(appid.to_s) == false
                  allgames = JSON.parse(File.read("#{@libdir}blueprints/game_inv_list.json"))
                  raise "invalid appid: #{appid}" if allgames.include?(appid.to_s) == false
            end
            ## end verify appid
            if @inventory_cache == true
                  verdict = verify_inventory_cache('normal',steamid,appid)
                  if verdict != false
                        return verdict
                  end
            end
            items = []
            last_id = 0
            until last_id == false
                  received = get_inventory_chunk_normal_way(appid,context,steamid,last_id)
                  last_id = received['new_last_id']
                  items = items + received['assets']
                  output "loaded #{items.length}"
            end

            output "total loaded #{items.length} asset"
            if @inventory_cache == true
                  File.open("./normal_#{steamid}_#{appid}.inventory", 'w') {|f| f.puts items.to_json}
            end

            return items
      end
###################################




###################################
      def raw_get_inventory(*params)#steamid = @steamid ,appid = 753, trim = true
            raise "expected 3 paramters, given #{params.length}"if params.length > 3
            steamid = @steamid
            appid = 753
            trim = true
            context = 6

            if params.length == 3
                  params.delete_if { |para|
                        if [TrueClass,FalseClass].include?(para.class)
                              trim = para
                              true
                        else
                              false
                        end
                  }
                  raise "could not determine trimming boolean" if params.length != 2

                 params.delete_if { |para|
                       if (3..6).to_a.include?(para.to_i.to_s.length)
                             appid = para
                             true
                       else
                             false
                       end
                 }
                 raise "could not distinguish between appID and steamID" if params.length != 1

                 steamid = params[0]

           elsif params.length == 2 && params.count {|x| x == true || x == false} >= 1
                  params.delete_if {|para|
                        if [TrueClass,FalseClass].include?(para.class)
                              trim = para
                              true
                        else
                              false
                        end
                  }
                  raise "given 2 booleans ? param1 : #{params[0]}, param2 #{params[1]}" if params.length != 1
                  if (3..6).to_a.include?(params[0].to_i.to_s.length)
                        appid = params[0]
                  else
                        steamid = params[0]
                  end
            elsif  params.length == 2 && params.count {|x| x == true || x == false} == 0
                  params.delete_if { |para|
                        if (3..6).to_a.include?(para.to_i.to_s.length)
                              appid = para
                              true
                        else
                              false
                        end
                  }
                  raise "unable to distinguish profileID from appID:: #{params[0]} and #{params[1]}" if params.length != 1
                  steamid = params[0]
            elsif params.length == 1
                  if params.count {|x| x == true || x == false} == 1
                        trim = params[0]
                  elsif (3..6).to_a.include?(params[0].to_i.to_s.length)
                        appid = params[0]
                  else
                        steamid = params[0]
                  end
            end

            steamid,token = verify_profileid_or_trade_link_or_steamid(steamid)
            raise "invalid steamid : #{steamid}, length of received :: #{steamid.to_s.length}, normal is 17" if steamid.to_s.length != 17
            ## verify appid
            if ["753","730",'570','440'].include?(appid.to_s) == false
                  allgames = JSON.parse(File.read("#{@libdir}blueprints/game_inv_list.json"))
                  raise "invalid appid: #{appid}" if allgames.include?(appid.to_s) == false
            end
            ## end verify appid

            if appid.to_s != "753"
                  context = 2
            end

            if @inventory_cache == true
                  verdict = verify_inventory_cache('raw',steamid,appid)
                  if verdict != false
                        return verdict
                  end
            end
            last_id = 0
            hash = {"assets" => [], "descriptions" => []}
            until last_id == false
                  received = get_inventory_chunk_raw_way(appid,context,steamid,last_id,trim)
                  last_id = received['new_last_id']
                  hash["assets"] = hash["assets"] + received['assets']
                  hash["descriptions"] = hash["descriptions"] + received["descriptions"]
                  output "loaded #{hash["assets"].length}"
            end

            output "total loaded #{hash["assets"].length} asset"
            if @inventory_cache == true
                  File.open("./raw_#{steamid}_#{appid}.inventory", 'w') {|f| f.puts hash.to_json}
            end

            return hash
      end










      private
      def get_inventory_chunk_normal_way(appid,context,steamid,last_id)


                  html = @session.get("https://steamcommunity.com/inventory/#{steamid}/#{appid}/#{context}?start_assetid=#{last_id}&count=5000").content

                  get = JSON.parse(html)
                  raise "something totally unexpected happened while getting inventory with appid #{appid} of steamid #{steamid} with contextid #{context}" if get.key?("error") == true
                  if get["total_inventory_count"] == 0
                        output "EMPTY :: inventory with appid #{appid} of steamid #{steamid} with contextid #{context}"
                        return {'assets' => [], 'new_last_id' =>false}
                  end
                  if get.keys[3].to_s == "last_assetid"

                          new_last_id = get.values[3].to_s

                  else
                          new_last_id = false

                  end

                  assets = get["assets"]
                  descriptions = get["descriptions"]


                  descriptions_classids = {} ###sorting descriptions by key value || key is classid of the item's description
                  descriptions.each {|description|
                       classidxinstance = description["classid"] + '_' + description["instanceid"] # some items has the same classid but different instane id
                       descriptions_classids[classidxinstance] = description
                  }

                  assets.each { |asset| ## merging assets with names
                       classidxinstance = asset["classid"] + '_' + asset["instanceid"]
                       asset.replace(asset.merge(descriptions_classids[classidxinstance]))
                  }


                return {'assets' => assets, 'new_last_id' =>new_last_id}

      end ## end inventory get normal

#######################################


#####################################


      def get_inventory_chunk_raw_way(appid,context,steamid,last_id,trim)


            html = @session.get("https://steamcommunity.com/inventory/#{steamid}/#{appid}/#{context}?start_assetid=#{last_id}&count=5000").content

            get = JSON.parse(html)
            raise "something totally unexpected happened while getting inventory with appid #{appid} of steamid #{steamid} with contextid #{context}" if get.key?("error") == true
            if get["total_inventory_count"] == 0
                  output "EMPTY :: inventory with appid #{appid} of steamid #{steamid} with contextid #{context}"
                  return {'assets' => [], "descriptions" => [], 'new_last_id' =>false}
            end
            if get.keys[3].to_s == "last_assetid"

                    new_last_id = get.values[3].to_s

            else
                    new_last_id = false

            end

            assets = get["assets"]
            descriptions = get["descriptions"]
            if trim == true
                  descriptions.each { |desc|
                        desc.delete_if {|key, value| key != "appid" && key != "classid" && key != "instanceid" && key != "tags" && key != "type" && key != "market_fee_app" && key != "marketable" &&key != "name" }
                        desc["tags"].delete_at(0)
                        desc["tags"].delete_at(0)
                  }
            end

           return {'assets' => get["assets"], "descriptions" => get["descriptions"], 'new_last_id' =>new_last_id}

    end



      def verify_inventory_cache(type,steamid,appid)
            if File.exists?("./#{type}_#{steamid}_#{appid}.inventory") == false
                  return false
            end

            file_last_time =  Time.parse(File.mtime("./#{type}_#{steamid}_#{appid}.inventory").to_s)
            current_time = Time.parse(Time.now.to_s)
            calcule = current_time - file_last_time
            if calcule.to_i > @inventory_validity
                  File.delete("./#{type}_#{steamid}_#{appid}.inventory")
                  return false
            else
                  output "gonna use cached inventory which is #{calcule} seconds old"
                  begin
                        return JSON.parse(File.read("./#{type}_#{steamid}_#{appid}.inventory",:external_encoding => 'utf-8',:internal_encoding => 'utf-8'))
                  rescue
                        File.delete("./#{type}_#{steamid}_#{appid}.inventory")
                        return false
                  end
            end

      end



end
