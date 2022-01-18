CloudContext
======
...


```ruby
require 'cloud_context'
```


## Size Limitations
While there is technically no limit to header size, servers generally enforce limits.  For example, Apache's default is 8KB and will return HTTP Status code 413 - Entity Too Large.  Additionally, headers adds overhead to every request being made, so use CloudContext sparingly.  To approximate byte size:

```ruby
CloudContext.bytesize
```


## Multi-threading Limitations
CloudContext allocates a new context for each thread.


----
## Contributing

Yes please  :)

1. Fork it
1. Create your feature branch (`git checkout -b my-feature`)
1. Ensure the tests pass (`bundle exec rspec`)
1. Commit your changes (`git commit -am 'awesome new feature'`)
1. Push your branch (`git push origin my-feature`)
1. Create a Pull Request


----
### Inspired by

- https://webapps-for-beginners.rubymonstas.org/rack/rack_env.html
- [request_store](https://github.com/steveklabnik/request_store)
- [request_store-sidekiq](https://github.com/madebylotus/request_store-sidekiq)
- [request_context](https://github.com/remind101/request_context)
- [faraday_middleware](https://github.com/lostisland/faraday_middleware)


----
![Gem](https://img.shields.io/gem/dt/cloud_context?style=plastic)
[![codecov](https://codecov.io/gh/dpep/cloud_context_rb/branch/main/graph/badge.svg)](https://codecov.io/gh/dpep/cloud_context_rb)
