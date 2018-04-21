# steam-trade

This gem simplifes/allows sending steam trade offers programmatically

## Installation
in your commandline :

`gem install steam-trade`

## Usage
First you need to require the gem:
```ruby
require 'steam-trade'
```

then you need to login and optionally set your shared_secret and identity_secret:
- `shared_secret` is used to generate steam authentication codes so you won't have to write them manually each time you login.
- `identity_secret` is used to confirm trade offers automatically.
```ruby
require 'steam-trade'

account = Handler.new('username','password','shared_secret') # share secret is optional
#username and password are required, shared_secret is optional


account.mobile_info('identity_secret')
#identity_secret is requred

```

then you can send your offer 
- `Myarray` is an array which contains hashes of selected items to send in the offer. (currently you must get this alone)
- `Theirarray` is an array which contains hashes of selected items to receive in the offer. (currently you must get this alone)
- `trade_offer_link` is the trade link of you partner ex: https://steamcommunity.com/tradeoffer/new/?partner=410155236&token=H-yK-GFt
- `message` is the comment you want to include in the trade offer

- `Myarray`, `Theirarray`, `trade_offer_link` are required, `message` is optional
```ruby
require 'steam-trade'

account = Handler.new('username','password','shared_secret')
account.mobile_info('identity_secret')


account.send_offer(Myarray,Theirarray,trade_offer_link,message)
```


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
