require 'mechanize'
require 'json'
require 'openssl'
require 'base64'
require 'open-uri'
require 'thread'


require_relative 'LoginExecutor.rb'
require_relative 'Misc.rb'
require_relative 'Trade.rb'
require_relative 'Confirmation.rb'
require_relative 'Trade.rb'
require_relative 'Inventory.rb'
require_relative 'Badge.rb'
require_relative 'Guard.rb'
require_relative 'Playerinfo.rb'

class Handler
      include MiscCommands
      include LoginCommands
      include TradeCommands
      include ConfirmationCommands
      include GuardCommands
      include InventoryCommands
      include BadgeCommands
      include GuardCommands
      include PlayerCommands

      def initialize(username = nil ,password = nil,secret = nil)
            @loggedin = false # will be set to true once we login

            @username = username
            @password = password
            @secret = secret

            @steamid = nil # will be initialized once you login and can be initialized with mobile_info
            @identity_secret = nil # can and should be initialized using mobile_info
            @api_key = nil # can be initalized through set_api_key or will be initialized once you login if possilbe
            @persona = nil # will be initialized once you login
            @session = Mechanize.new { |agent| # the session which will hold your cookies to communicate with steam
                  agent.user_agent_alias = 'Windows Mozilla'
                  agent.follow_meta_refresh = true
            }

            @inventory_cache = false
            @libdir = Util.gem_libdir
            output "Handler started"
            if username != nil && password != nil
                  login()
            end
      end

      def mobile_info(identity_secret, steamid = nil)
            @identity_secret = identity_secret
            if @steamid == nil && steamid != nil
                  @steamid = steamid
            end
      end

      def set_inventory_cache(timer = 120)
            integer = 5
            float = 5.5
            if timer.class == integer.class || timer.class == float.class
                  @inventory_validity = timer
                  output "inventory validity set to #{timer}"
            end
            if @inventory_cache == false
                  @inventory_cache = true
                  output "inventory cache enabled"
            else
                  @inventory_cache == false
                  output "inventory cache disabled"
            end
      end

      def set_api_key(api_key)
            @api_key = api_key
      end

end
