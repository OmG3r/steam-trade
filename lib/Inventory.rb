module InventoryCommands





      def normal_get_inventory(steamid = @steamid ,appid = 753)
            if steamid == nil
                raise "not logged-in and no steamid specified"
            end


            appid = appid.to_s
            context = 6

            #verify given appid only
            if (3..6).to_a.include?(steamid.to_i.to_s.length)
                  puts "we got an appid"
                  raise "You cannot give an appid only if you are not logged in" if @steamid == nil
                  appid = steamid.to_s
                  steamid = @steamid
            end
            # end given appid only

            #verify given another game
            if appid.to_s != "753"
                  puts "getting a new game"
                  context = 2
            end
            #end verify given another game
            # end verify given appid only
            #verify trade link


            steamid = verify_profileid_or_trade_link_or_steamid(steamid)

            raise "invalid steamid : #{steamid}, length of received :: #{steamid.to_s.length}, normal is 17" if steamid.to_s.length != 17
            ## verify appid
            if ["753","730",'570','440'].include?(appid.to_s) == false
                  allgames = JSON.parse(File.read("#{@libdir}blueprints/game_inv_list.json"))
                  raise "invalid appid: #{appid}" if allgames.include?(appid.to_s) == false
            end
            ## end verify appid

            if @inventory_cache == true
                  verdict = verify_inventory_cache(steamid,appid)
                  if verdict != false
                        return verdict
                  end
            end
            puts "steamid :#{steamid}"
            puts "appid : #{appid}"

            items = []
            last_id = 0
            until last_id == false
                  received = get_inventory_chunk_normal_way(appid,context,steamid,last_id)
                  last_id = received['new_last_id']
                  items = items + received['assets']
                  output "loaded #{items.length}"
                  sleep(2) if last_id != false
            end

            output "total loaded #{items.length} asset"
            if @inventory_cache == true
                  File.open("./#{steamid}_#{appid}.inventory", 'w') {|f| f.puts items.to_json}
            end

            return items
      end

      private
      def get_inventory_chunk_normal_way(appid,context,steamid,last_id)


                  html = open("https://steamcommunity.com/inventory/#{steamid}/#{appid}/#{context}?start_assetid=#{last_id}&count=5000").read

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

      end





      def verify_inventory_cache(steamid,appid)
            if File.exists?("./#{steamid}_#{appid}.inventory") == false
                  return false
            end
            puts File.mtime("./#{steamid}_#{appid}.inventory").to_s
            puts Time.now.to_s
            file_last_time =  Time.parse(File.mtime("./#{steamid}_#{appid}.inventory").to_s)
            current_time = Time.parse(Time.now.to_s)
            calcule = current_time - file_last_time
            puts "difference #{calcule}"
            if calcule.to_i > @inventory_validity
                  File.delete("./#{steamid}_#{appid}.inventory")
                  return false
            else
                  output "gonna use cached inventory which is #{calcule} seconds old"
                  begin
                        return JSON.parse(File.read("./#{steamid}_#{appid}.inventory",:external_encoding => 'utf-8',:internal_encoding => 'utf-8'))
                  rescue
                        File.delete("./#{steamid}_#{appid}.inventory")
                        return false
                  end
            end

      end



end
