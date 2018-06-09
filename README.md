# steam-trade V0.2.3

**PLEASE IF SOMETHING DOES NOT WORK PROPERLY MAKE A GITHUB ISSUE**

Please check constantly for updates cause i'm still making this gem.

This gem simplifes/allows sending steam trade offers programmatically.

this gem is primarly for trading cards, tho can be used to CS:GO and other games inventories

# Changelog
```
0.2.3:
- hotfix

0.2.2:
- fixed issues with ruby 2.4+
- added class methods for fa(), normal_get_inventory(), raw_get_inventory, sets_count()

0.2.1:
- many many bugs fixed

0.2.0:
- hotfix

0.1.9:
- Handler.new() now accepts a hash contains login cookies.
- get_auth_cookies() returns cookies to use for the next login

0.1.8:
- hotfix

0.1.7:
- hotfix

0.1.6:
- hotfix

0.1.5:
- added mobile_login() which allows you to send and receive steam messages
- added oauth_login() uses oauth token and steamMachine cookie to login in ( you get those from mobile_login())

0.1.4:
- added Social commands : send friend request, accept friend request, remove friend, send message, get messages
- added function to update badges blueprint (useful when there is no gem update)

0.1.3:
- decreased cooldown between requests from 2 seconds to 1 second.
- added a 0.6 second wait before attempting to confirm a trade offer (mobile).
- added a 3 times retry to get an inventory chunk before raising an error.
- exception handling for sets_count, now no longer raises an error if the target inventory contains trading cards which are not specified in the bluepirnt.

0.1.2:
- normal_get_inventory() and raw_get_inventory() now uses Mechanize instead of open-uri.
- Handler.new() and fa() now accepts a time difference parameter to adjust your 2FA codes.
- sets_count() now writes the txt file faster.
- Mechanize session associated with the account now has a 2 second cooldown before each request to avoid spamming steam servers and resulting in a ban.
```
# Table of content

- [Installation](#installation)
- [Usage & Examples](#usage)
  - [Logging-in](#logging-in)
    - [Hander.new() (this is how you login)](#handlernew)
      - [Handler.new() (normal login)](#handlernewusername-passwordshared_secrettime_differenceremember_me)
      - [Handler.new() (cookies login)](#handlernewcookies_hashshared_secrettime_differenceremember_me)
    - [get_auth_cookies()](#get_auth_cookies)
    - [mobile_info()](#mobile_infoidentity_secret)
  - [Getting someone's inventory](#getting-someones-inventory)
    - [normal_get_inventory()](#normal_get_inventorysteamidinventoryappid)
    - [raw_get_inventory()](#raw_get_inventorytargetinventoryappidtrimming)
    - [set_inventory_cache()](#set_inventory_cache)
  - [Sending a trade offer](#sending-a-trade-offer)
    - [send_offer()](#send_offermyarraytheirarraytrade_offer_linkmessage)
  - [Handling Trade Offers](#handling-trade-offers)
    - [set_api_key()](#set_api_keyapi_key)
    - [get_trade_offers()](#get_trade_offerstime)
    - [get_trade_offer()](#get_trade_offertrade_offer_id)
    - [accept_trade_offer()](#accept_trade_offertrade_offer_id)
    - [decline_trade_offer()](#decline_trade_offertrade_offer_id)
    - [cancel_trade_offer()](#cancel_trade_offertrade_offer_id)
  - [Counting badges owned](#counting-badges-owned)
    - [sets_count()](#sets_counttargetnon_marketable)
    - [update_blueprint()](#update_blueprint)
  - [2FA codes](#2fa-codes)
    - [fa()](#fashared_secret-time_difference)
  - [Social Features](#social-commands)
    - [mobile_login()](#mobile_loginusernamepasswordshared_secret)
    - [oauth_login()](#oauth_loginoauth_tokensteammachine)
    - [send_message()](#send_messagetarget-message)
    - [poll_messages()](#poll_messages)
    - [send_friend_request()](#send_friend_requesttarget)
    - [accept_friend_request()](#accept_friend_requesttarget)
    - [remove_friend()](#remove_friendtarget)
  - [More commands](#more-commands)

## Installation
in your commandline :

`gem install steam-trade`

## Usage
First you need to require the gem:
```ruby
require 'steam-trade'
```
## Logging-in
#### `Handler.new()`
##### `Handler.new(username, password,shared_secret,time_difference,remember_me)`
then you need to login and optionally set your shared_secret and identity_secret:
- `shared_secret` is used to generate steam authentication codes so you won't have to write them manually each time you login.
- `time_difference`is the difference between your time and steam servers, this affects how 2FA codes are generated (**this MUST BE an integer**)
- `remember_me` is a boolean used to indicate whether you want cookies which expire shortly if set to **false** or stay valid for weeks if set to **true**
```ruby
require 'steam-trade'

account = Handler.new('username','password','shared_secret') # share secret is optional
account = Handler.new('username','password',50) #works
account = Handler.new('username','password','shared_secret',50)
account = Handler.new('username','password',50,'shared_secret') # this will not work

account = Handler.new('username','password','shared_secret',20,true) # works
account = Handler.new('username','password','shared_secret',true) #works
account = Handler.new('username','password',20,true) #works
account = Handler.new('username','password',true) #works

account = Handler.new('username','password','shared_secret',true,20) # will not work
##########
account = Handler.new('username') #this of course counts as non logged in

```
keep in mind you can initialize a Handler without params however the commands you will be able to use will be limited
```ruby
require 'steam-trade'

account = Handler.new()
puts account.fa('v3dWNq2Ncutc7RelwRVXswT8CJX=v3dWNq2Ncutc7WelwRVXswT8CJk=') => random code

```

##### `Handler.new(cookies_hash,shared_secret,time_difference,remember_me)`
- `cookies_hash` is hash containing `steamLogin`, `steamLoginSecure` and `steamMachineAuth` cookies.
this can be used with `get_auth_cookies()` for faster login.
- `shared_secret` is used to generate steam authentication codes so you won't have to write them manually each time you login.
- `time_difference`is the difference between your time and steam servers, this affects how 2FA codes are generated (**this MUST BE an integer**)
- `remember_me` is a boolean used to indicate whether you want cookies which expire shortly if set to **false** or stay valid for weeks if set to **true**


```ruby
require 'steam-trade'
account = Handler.new(JSON.parse(File.read('./creds.json'))) # creds.json is created by get_auth_cookies()

account = Handler.new(JSON.parse(File.read('./creds.json')), 'shared_secret', 50)
```

#### `get_auth_cookies()`
- returns the current logged in account cookies to use in the future.
```ruby
require 'steam-trade'
account = Handler.new('username','password','shared_secret',true)
cookies = h.get_auth_cookies

File.open('creds.json', 'w') {|f| f.puts cookies.to_json)
```
next time :
```ruby
require 'steam-trade'
account = Handler.new(JSON.parse(File.read('./creds.json')))
```

#### `mobile_info(identity_secret)`
- `identity_secret` is your account's identity secret (try using google if you don't know what this is).
- `identity_secret` is used to automatically confirm trade offers.
```ruby
require 'steam-trade'

account = Handler.new('username','password','shared_secret')
account.mobile_info('identity_secret')
```

## Getting someone's inventory
you might want to read this [guide](https://dev.doctormckay.com/topic/332-identifying-steam-items/)
#### `normal_get_inventory('steamid','inventoryappid')`
- `steamid` is the target's steamID, or profileID, or trade link
- `inventoryappid` is the inventory type you want to load, `ex : normal inventory(the one which holds trading cards), it's is 753`
- if you call `normal_get_inventory()` with no params, it will be default use the current logged-in account `steamid`, `inventoryappid = 753`

```ruby
require 'steam-trade'
inventory = Handler.normal_get_inventory("nomg3r")


logged = Handler.new('username','password','shared_secret')
logged.mobile_info('identity_secret')
# while logged in
my_inventory = logged.normal_get_inventory() #will get your normal inventory(753) if you are logged in else raise an exception
my_inventory = logged.normal_get_inventory('730') # will get your CS:GO inventory if you are logged in else raise an exeception


#whatever can be done while **not** logged in, can be of course used while logged in
#while not logged in
nonlogged = Handler.new()
my_inventory = nonlogged.normal_get_inventory() #will raise an exception
my_inventory = nonlogged.normal_get_inventory('730') #will raise an exception

#whenever
partner_inventory = nonlogged.normal_get_inventory('76561198044170935') #using steamid
partner_inventory = nonlogged.normal_get_inventory('https://steamcommunity.com/tradeoffer/new/?partner=410155236&token=H-yK-GFt') #using trade link
partner_inventory = nonlogged.normal_get_inventory('CardExchange') #using profile id


partner_inventory = nonlogged.normal_get_inventory('76561198044170935',730) #will get that steamid CS:GO inventory
partner_inventory = nonlogged.normal_get_inventory('https://steamcommunity.com/tradeoffer/new/?partner=410155236&token=H-yK-GFt', '730') #will get that trade link owner's CS:GO inventory
partner_inventory = nonlogged.normal_get_inventory('CardExchange',730) # will get CardExchange's CS:GO inventory


```
the returned items from `normal_get_inventory()` are in the form of an array example : `[item1,item2,item3...itemN]`.

each item is a hash which contains information about the item in the form of `{"appid"=>'xxx',"contextid"=>'xxx',"assetid" => 'xxx',"classid"=> 'xxx',......"name"=> 'xxxx',"market_fee_app" => 'xxx',....}`.

`market_fee_app` key gives you the appid of the game's app (for trading cards), for other items technically `inventoryappid` is the games appid.

`name` key gives you the item name.
#### `raw_get_inventory(target,inventoryappid,trimming)`
**IMPORTANT**: this command efficiency is better than `normal_get_inventory`, therefore i **recommend**  using this one.
- `target` is a steamID/profileID/trade link
- `inventoryappid` is the inventory type you want to load, `ex : normal inventory(the one which holds trading cards), it's is 753`
- `trimming`, defaults to `true` this will remove images link and steam-server-side related informations from the descriptions hash, drastically reducing the size of data received.

This command will return a hash nearly identitical to the one received from steam the hash will have 2 keys `assets` and `descriptions`:
- `assets` has an array as value, identical to steam's [(example)](https://steamcommunity.com/inventory/76561198044170935/753/6?start_assetid=0&count=100)
- `descriptions` has an array as a value identical to steam's [(example)](https://steamcommunity.com/inventory/76561198044170935/753/6?start_assetid=0&count=100)

```ruby
require 'steam-trade'
inv = Handler.raw_get_inventory("nomg3r")


logged = Handler.new('username','password','shared_secret')
inv = logged.raw_get_inventory() #works
inv = logged.raw_get_inventory(false) # returns non trimmed
inv = logged.raw_get_inventory(440) #works
inv = logged.raw_get_inventory(76561198044170935,false) #works
inv = logged.raw_get_inventory(76561198044170935,440) # works

print inv['assets'] will print all the assets
print inv['descriptions'] will print all the descriptions

### how to accurately use this

class_instance = {}
## map all the items
inv['descriptions'].each { |desc|
  identifier = desc['classid'] + '_' + desc['instanceid']
  class_instance[identifier] = desc
}

## identify your items

inv['assets'].each { |asset|
  identifier = asset['classid'] + '_' + asset['instanceid']
  puts class_instance[identifier] this will output the item's description
}

```

#### `set_inventory_cache()`
`set_inventory_cache()` is:

- a switch to locally save each inventory you get to a local file.
- disabled by default, you need to initiate it by calling the command
- accepts a parameter `timer` which defaults to `timer = 120`, this parameter is the difference between the save file was created and the moment it was checked (upong trying to retrieve the inventory).

- this switch is useful if you are getting a "static" inventory or testing your code.
```ruby
require 'steam-trade'

logged = Handler.new('username','password','shared_secret')
logged.mobile_info('identity_secret')
logged.set_inventory_cache(150)


partner_inventory = loggedlogged.normal_get_inventory('CardExchange') #this will save CardExchange's inventory to a local file and return the inventory

partner_inventory = loggedlogged.normal_get_inventory('CardExchange') # this will load the locally saved file


```

**IMPORTANT**: `normal_get_inventory()` will load the whole target inventory, for each **5k** of items, you are adding **~40MB** to your memory and of course will affect performance of the code and the computer
## Sending a trade offer
#### `send_offer(myarray,theirarray,trade_offer_link,message)`
**MUST be logged in to use this command**
then you can send your offer
- `myarray` is an array which contains hashes of selected items to send in the offer. (currently you must get this alone)
- `Theirarray` is an array which contains hashes of selected items to receive in the offer. (currently you must get this alone)
- `trade_offer_link` can be the trade link of you partner `ex: https://steamcommunity.com/tradeoffer/new/?partner=410155236&token=H-yK-GFt`
- `trade_offer_link` can be a steamID, however using a steamID requires you and your partner to be friends on steam
- `trade_offer_link` can  be a profileID, however using a profileID requires you and your partner to be friends on steam
- `message` is the comment you want to include in the trade offer

- `myarray`, `theirarray`, `trade_offer_link` are required, `message` is optional
```ruby
require 'steam-trade'

account = Handler.new('username','password','shared_secret')
account.mobile_info('identity_secret')

me = account.normal_get_inventory()
his = account.normal_get_inventory("nomg3r")

myarray = [me[5] , me[20] , me[60]].compact!
theirarray = [his[1], his[20], his[30]].compact!

# if you are friends
account.send_offer(myarray,theirarray,"nomg3r",message)
#or (as friends)
account.send_offer(myarray,theirarray,'76561198370420964',message)

# whenever
account.send_offer(myarray,theirarray,"https://steamcommunity.com/tradeoffer/new/?partner=410155236&token=H-yK-GFt",message)

```
## Handling Trade Offers
you might want to read [Steam Trading API](https://developer.valvesoftware.com/wiki/Steam_Web_API/IEconService)

**ALL OF THE COMMANDS BELOW REQUIRE AN API_KEY**

#### `set_api_key(API_KEY)`
**NOTE**:If you are using a **logged in** Handler there is no need to set the API_KEY.
- `API_KEY` is your apikey, you can get that from [here](https://steamcommunity.com/dev/apikey).
```ruby
require 'steam-trade'
acc = Handler.new()
trade_offers = acc.get_trade_offers() # will raise an exception
acc.set_api_key('mykey')
trade_offers = acc.get_trade_offers() # after setting an API_KEY this will succeed
```
#### `get_trade_offers(time)`
- `time` is the moment from which you want to get updates (explained in the example)
this will return a hash with `trade_offers_sent`, `trade_offers_received`, `descriptions` as keys.
`descriptions` includes the descriptions of all items returned from `trade_offers_sent` or `trade_offers_received`

```ruby
require 'steam-trade'
logged = Handler.new('username','password','shared_secret')
logged.mobile_info('identity_secret')

time = '' # this is the initial check for offers so we want them all
polling = Thread.new(logged) { |logged|
  loop do
    offers = logged.get_trade_offers(time)
    time = Time.new.to_i # we save the time of the last check
    next if offers['trade_offers_received'] == nil # do nothing, if there is no trades
    puts offers['trade_offers_received'] # puts the trades
    sleep(15) # make sure not to spam steam's server or they will block list your IP for a period of time therefore you can't make requests
  end
}
```
#### `get_trade_offer(trade_offer_id)`
gets more information about a specific trade offer
- `trade_offer_id` is the id of the offer you want to confirm (you can get the id using [this](#get_trade_offerstime) to get the offerID

have no example how to actually use this cause `get_trade_offers(time)` is probably better

#### `accept_trade_offer(trade_offer_id)`
- `trade_offer_id` is the id of the offer you want to confirm (you can get the id using [this](#get_trade_offerstime) to get the offerID
```ruby
require 'steam-trade'
logged = Handler.new('username','password','shared_secret')
logged.mobile_info('identity_secret')

time = '' # this is the initial check for offers so we want them all
polling = Thread.new(logged) { |logged|
  loop do
    offers = logged.get_trade_offers(time)
    time = Time.new.to_i # we save the time of the last check
    next if offers['trade_offers_received'] == nil # do nothing, if there is no trades
    offers['trade_offers_received'].each { |trade|
      if trade['accountid_other'].to_i == 83905207 ## this will accept all trade received from 83905207 (Steam32 ID)
        logged.accept_trade_offer(trade['tradeofferid']) # to accept the trade
      end
    }
    sleep(15) # make sure not to spam steam's server or they will block list your IP for a period of time therefore you can't make requests
  end
}
```
#### `decline_trade_offer(trade_offer_id)`
this declines a trade offer you **RECEIVED**
- `trade_offer_id` is the id of the offer you want to confirm (you can get the id using [this](#get_trade_offerstime) to get the offerID

```ruby
require 'steam-trade'
logged = Handler.new('username','password','shared_secret')
logged.mobile_info('identity_secret')

time = '' # this is the initial check for offers so we want them all
polling = Thread.new(logged) { |logged|
  loop do
    offers = logged.get_trade_offers(time)
    time = Time.new.to_i # we save the time of the last check
    next if offers['trade_offers_received'] == nil # do nothing, if there is no trades
    offers['trade_offers_received'].each { |trade| # we need to check received offers to use 'decline'
      if trade['accountid_other'].to_i != 83905207 ## notice the '!='
        logged.decline_trade_offer(trade['tradeofferid']) # decline the trade
      end
    }
    sleep(15) # make sure not to spam steam's server or they will block list your IP for a period of time therefore you can't make requests
  end
}
```
#### `cancel_trade_offer(trade_offer_id)`
this cancels a trade offer you **SENT**
- `trade_offer_id` is the id of the offer you want to confirm (you can get the id using [this](#get_trade_offerstime) to get the offerID
```ruby
require 'steam-trade'
logged = Handler.new('username','password','shared_secret')
logged.mobile_info('identity_secret')

time = '' # this is the initial check for offers so we want them all
polling = Thread.new(logged) { |logged|
  loop do
    offers = logged.get_trade_offers(time)
    time = Time.new.to_i # we save the time of the last check
    next if offers['trade_offers_sent'] == nil # do nothing, if there is no trades
    offers['trade_offers_sent'].each { |trade| # we need to check sentoffers to use 'cancel'
      if trade['accountid_other'].to_i != 83905207 ## notice the '!='
        logged.cancel_trade_offer(trade['tradeofferid']) # cancel the trade
      end
    }
    sleep(15) # make sure not to spam steam's server or they will block list your IP for a period of time therefore you can't make requests
  end
}
```
## Counting badges owned
#### `sets_count(target,non_marketable)`
**this command does not count foil badges (only normal trading cards)**
- `target` can be a steamID, a profileID or a trade link
- `non_marketable` this is a switch to count **non**-marketable trading cards(defaults to **true** if not specified)
- a .txt will be created from this command to read the badges
- this returns a hash  `{'sets' => appsets, 'appxsets' => setsowned, 'totalsets' => numberofsets, 'totalcards' => total_non_foil, 'marketable' => true}`
  - `'sets'` is a hash with game appids as keys and each card and number of copies owned of each card `{'appid1' => {'card1' => 5,'card2' => 3, ... 'cardN' => Z},{'appid1' => {'card1' => 0,'card2' => 2, ... 'cardN' => K} }`
  - `'appxsets'` is a hash containing the number of sets available of each set `{'appid1' => 5,'appid2' => 20,...'appidN' => Z}`
  - `'totalsets'` is an integer equals to the number of sets owned
  - `'totalcards'` is an integer equals to the number of non-foil cards account for
```ruby
require 'steam-trade'
data = Handler.sets_count("CardExchange")


logged = Handler.new('username','password','shared_secret')
logged.mobile_info('identity_secret')
#with login
logged = account.sets_count()
logged = account.sets_count(false)
hash = account.sets_count('CardExchange',false)
hash = account.sets_count(76561198370420964)
hash = account.sets_count('https://steamcommunity.com/tradeoffer/new/?partner=410155236&token=H-yK-GFt',false)


#without login
nonlogged = Handler.new()
logged = account.sets_count() #raise exception
logged = account.sets_count(false) # raise exception
hash = account.sets_count('CardExchange')
hash = account.sets_count(76561198370420964)
hash = account.sets_count('https://steamcommunity.com/tradeoffer/new/?partner=410155236&token=H-yK-GFt',false)

```

#### `update_blueprint()`
- updates your locally saved badges blueprint
```ruby
require 'steam-trade'

handler = Handler.new

handler.update_blueprint()
```
## 2FA codes
#### `fa(shared_secret, time_difference)`
- `shared_secret` is the account's shared secret (if you don't know what is this try googling 'steam shared_secret'), defaults to the logged in account's steamid if logged in.
- `time_difference` is the difference between your pc's time and steam's time (**this MUST BE an integer**)
**NOTE**: using this command with a new shared_secret will not change/set the current saved shared_secret for the account
```ruby
require 'steam-trade'
puts Hander.fa('random_shared_secret')


logged = Handler.new('username','password','inital_shared_secret')
puts logged.fa() #=> random code for your account
puts logged.fa('new_shared_secret') # => this will give you a random code for another account, AND will not edit your initial_shared_secret

####
logged_without_shared_secret = Handler.new('username','password') # this is possible of course
puts logged_without_shared_secret.fa() # this will not work
puts logged_without_shared_secret.fa('shared_secret') ## will give a random code
###
nonlogged = Handler.new()
puts nonlogged.fa() # will not work
puts logged.fa() # will give a random code

```
## Social Commands
#### `mobile_login('username','password','shared_secret')`
- this command will be called automatically if you attempt to use `send_message()` or `poll_messages()` without authentication
- calling this explicitly allows you to painlessly retrieve the OAuth token and `SteamMachine#{steamid}` cookie to use in `oauth_login()`
- this function returns a hash with `oauth_token` and `machine` as keys
```ruby
require 'steam-trade'

h = Handler.new('user','pass','secret')
data = h.mobile_login() #this works are you have setted username and password
puts data ## will output with oauth token and steamMachine cookie

###################
h = Handler.new()
data = h.mobile_login() # will raise an error cause there is no username or password

##########

h = Handler.new()
data = h.mobile_login('user','pass','secret') ## will work, you are not logged in ( talking about community) here you can't use most of the commands (send_offer() etc) and those parameters you passed will not be setted as the Handler's

######
h = Handler.new('user1','pass1','secret1')
data = mobile_login('user2','pass2','secret2') # this works but trading commands etc will be called using user1, and chat commands will be called using user2
```
#### `oauth_login(oauth_token,SteamMachine)`
- `oauth_token` and `SteamMachine` can be retrieved from `mobile_login()`
```ruby
require 'steam-trade'
h = Handler.new()
h.oauth_login('oauth_token','SteamMachine')
```
#### `send_message(target, message)`
sends a message to the target
- `target` can be a steamID64, tradelink, or profileID
- `message` the message to send
```ruby
require 'steam-trade'

h = Handler.new('username', 'password')
h.send_message('nomg3r', "Hello, Friend")
```

#### `poll_messages()`
gives you the messages you receieved (after mobile login is initiated (after you call send_message() or poll_messages()  ) )

```ruby
require 'steam-trade'

h = Handler.new('username', 'password')
print h.poll_messages() # will not return messages so you call at again ( only the first time in the whole program )
puts ""
puts "------"
sleep(10) #send a message to the logged in account
print h.poll_messages() # actually have messages ( if you received some in the time between the first and the second request )
```
**ALL OF THE COMMANDS BELOW REQUIRES LOGIN**
#### `send_friend_request(target)`
sends a friend request to the target
- `target` can be a steamID64, tradelink, or profileID

```ruby
require 'steam-trade'

h = Handler.new('username', 'password')
h.send_friend_request('nomg3r')
```

#### `accept_friend_request(target)`
accepts a friend request from the target
- `target` can be a steamID64, tradelink, or profileID

```ruby
require 'steam-trade'

h = Handler.new('username', 'password')
h.accept_friend_request('nomg3r')
```

### `remove_friend(target)`
removes a friend
- `target` can be a steamID64, tradelink, or profileID

```ruby
require 'steam-trade'

h = Handler.new('username', 'password')
h.remove_friend('nomg3r')
```

## More commands
you can find more non-vital commands in the [wiki](https://github.com/OmG3r/steam-trade/wiki)
## License

The gem is available as open source under the terms of the [GNU GPLV3](https://github.com/OmG3r/steam-trade/blob/master/LICENSE).
