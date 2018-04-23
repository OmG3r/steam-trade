# steam-trade V0.0.8

This gem simplifes/allows sending steam trade offers programmatically.

this gem is primarly for trading cards, tho can be used to CS:GO and other games inventories
## Installation
in your commandline :

`gem install steam-trade`

## Usage
First you need to require the gem:
```ruby
require 'steam-trade'
```
## Logging-in
then you need to login and optionally set your shared_secret and identity_secret:
- `shared_secret` is used to generate steam authentication codes so you won't have to write them manually each time you login.
- `identity_secret` is used to confirm trade offers automatically.
```ruby
require 'steam-trade'

account = Handler.new('username','password','shared_secret') # share secret is optional
#username and password are required, shared_secret is optional

account.mobile_info('identity_secret')
#identity_secret is required

##########
account = Handler.new('username') #this of course counts as non logged in

```
keep in mind you can initialize a Handler without params however the commands you will be able to use will be limited
```ruby
require 'steam-trade'

account = Handler.new()
puts account.fa('v3dWNq2Ncutc7RelwRVXswT8CJX=v3dWNq2Ncutc7WelwRVXswT8CJk=') => random code

```
## Getting someone's inventory
#### `normal_get_inventory('steamid','inventoryappid')`
- `steamid` is the target's steamid
- `inventoryappid` is the inventory type you want to load, `ex : normal inventory(the one which holds trading cards), it's is 753`
- if you call `normal_get_inventory()` with no params, it will be default use the current logged-in account `steamid`, `inventoryappid = 753`

```ruby
require 'steam-trade'

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
#### `set_inventory_cache()`
`set_inventory_cache()` is:

- a switch to locally save each inventory you get to a local file.
- disabled by default, you need to initiate it by calling the command
- accepts a parameter `timer` which defaults to `timer = 120`, this parameter is the difference between the save file was created and the moment it was checked (upong trying to retrieve the inventory).

- this switch is useful if you are getting a "static" inventory or testing your code.


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
## Counting badges owned
#### `sets_count(target,non_marketable)`
**this command does not count foil badges (only normal trading cards)**
- `target` can be a steamID, a profileID or a trade link
- `non_marketable` this is a switch to count marketable cards(defaults to true if not specified)
- a .txt will be created from this command to read the badges
- this returns a hash  `{'sets' => appsets, 'appxsets' => setsowned, 'totalsets' => numberofsets, 'totalcards' => total_non_foil, 'marketable' => true}`
  - `'sets'` is a hash with game appids as keys and each card and number of copies owned of each card `{'appid1' => {'card1' => 5,'card2' => 3, ... 'cardN' => Z},{'appid1' => {'card1' => 0,'card2' => 2, ... 'cardN' => K} }`
  - `'appxsets'` is a hash containing the number of sets available of each set `{'appid1' => 5,'appid2' => 20,...'appidN' => Z}`
  - `'totalsets'` is an integer equals to the number of sets owned
  - `'totalcards'` is an integer equals to the number of non-foil cards account for
```ruby
require 'steam-trade'

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
logged = account.sets_count() raise exception
logged = account.sets_count(false) # raise exception
hash = account.sets_count('CardExchange')
hash = account.sets_count(76561198370420964)
hash = account.sets_count('https://steamcommunity.com/tradeoffer/new/?partner=410155236&token=H-yK-GFt',false)

```
## 2FA codes
#### `fa(shared_secret)`
- `shared_secret` is the account's shared secret (if you don't know what is this try googling 'steam shared_secret'), defaults to the logged in account's steamid if logged in.

**NOTE**: using this command with a new shared_secret will not change/set the current saved shared_secret for the account
```ruby
require 'steam-trade'

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
puts nonlogged.fa() # will give a random code

```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
