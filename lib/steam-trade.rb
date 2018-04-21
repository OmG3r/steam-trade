require 'mechanize'
require 'json'
require 'openssl'
require 'base64'

require 'LoginExecutor.rb'
require 'Misc.rb'
require 'Trade.rb'
require 'Confirmation.rb'
require 'Trade.rb'

class Handler
      include LoginCommands
      include TradeCommands
      include ConfirmationCommands
      include GuardCommands
      include Abilites

      def initialize(username,password,secret = nil)
            @username = username
            @password = password
            @secret = secret

            @steamid = nil # will be initialized once you login and can be initialized with mobile_info
            @identity_secret = nil # can and should be initialized using mobile_info
            @confirmator = nil # will be initialized once steamid and identity secret are set

            @session = Mechanize.new { |agent|
                  agent.user_agent_alias = 'Windows Mozilla'
                  agent.follow_meta_refresh = true
            }
            login
      end

      def mobile_info(identity_secret, steamid = nil)
            @identity_secret = identity_secret
            if @steamid == nil && steamid != nil
                  @steamid = steamid
            end
      end

end
