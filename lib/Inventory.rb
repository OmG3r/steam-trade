module InventoryCommands





      def normal_get_inventory(steamid = @steamid ,appid = 753,context = 6)
            if steamid == nil
                output "no steamid specified"
                return
          elsif steamid.to_i == 0 && steamid.include?("?partner=") ##supplied trade link
                partner_raw = steamid.split('partner=',2)[1].split('&',2)[0]
                steamid = partner_id_to_steam_id(partner_raw)
            end


            if @inventory_cache == true
                  verdict = verify_inventory_cache(steamid)
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
                  sleep(2) if last_id != false
            end

            output "total loaded #{items.length} asset"
            if @inventory_cache == true
                  File.open("./#{steamid}.inventory", 'w') {|f| f.puts items.to_json}
            end

            return items
      end

      private
      def get_inventory_chunk_normal_way(appid,context,steamid,last_id)


                  html = open("https://steamcommunity.com/inventory/#{steamid}/#{appid}/#{context}?start_assetid=#{last_id}&count=5000").read

                  get = JSON.parse(html)

                  if get.keys[3].to_s == "last_assetid"

                          new_last_id = get.values[3].to_s

                  else
                          new_last_id = false

                  end

                  assets = get["assets"]
                  descriptions = get["descriptions"]


                  descriptions_classids = {} ###sorting descriptions by key value || key is classid of the item's description
                  descriptions.each {|description|
                    classid = description["classid"]
                    descriptions_classids[classid] = description
                  }

                  assets.each { |asset| ## merging assets with names
                    classid = asset["classid"]
                    asset.replace(asset.merge(descriptions_classids[classid]))

                  }


                return {'assets' => assets, 'new_last_id' =>new_last_id}

      end





      def verify_inventory_cache(steamid)
            if File.exists?("./#{steamid}.inventory") == false
                  return false
            end
            puts File.mtime("./#{steamid}.inventory").to_s
            puts Time.now.to_s
            file_last_time =  Time.parse(File.mtime("./#{steamid}.inventory").to_s)
            current_time = Time.parse(Time.now.to_s)
            calcule = current_time - file_last_time
            puts "difference #{calcule}"
            if calcule.to_i > @inventory_validity
                  File.delete("./#{steamid}.inventory")
                  return false
            else
                  output "gonna use cached inventory which is #{calcule} seconds old"
                  begin
                        return JSON.parse(File.read("./#{steamid}.inventory",:external_encoding => 'utf-8',:internal_encoding => 'utf-8'))
                  rescue
                        File.delete("./#{steamid}.inventory")
                        return false
                  end
            end

      end



end
