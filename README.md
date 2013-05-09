# leo_manager_client

The library of LeoFS-Manager's client for Ruby

## Installation
    
    $ gem install leo_manager_client

## Usage

```ruby
require "leo_manager_client"

manager = LeoManager::Client.new("localhost:10020")
manager.status #=> #<LeoManager::Status:0x00000001578310 @system_info=#<LeoManager::Status::SystemInfo:0x000000015782e8 @version="0.10.1", @n="1", @r="1", @w="1", @d="1", @ring_size="128", @ring_cur=nil, @ring_prev=nil>, @node_list=[#<LeoManager::Status::NodeInfo:0x00000001578298 @type="S", @node="storage_0@127.0.0.1", @state="running", @ring_cur="a039acc0", @ring_prev="a039acc0", @joined_at="2012-09-21 15:08:22 +0900">, #<LeoManager::Status::NodeInfo:0x00000001578248 @type="G", @node="gateway_0@127.0.0.1", @state="running", @ring_cur="a039acc0", @ring_prev="a039acc0", @joined_at="2012-09-21 15:08:25 +0900">]>
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
