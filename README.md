CloudContext
======

Propagate request-scoped context across the distributed systems in your stack.

`CloudContext` is a thread-local key/value store that rides along with downstream
HTTP requests (via headers) and Sidekiq jobs (via job metadata), so
request-scoped data — request ids, tenant ids, user ids, feature flags, locale,
etc. — flows automatically across service and process boundaries without
having to thread it through every method signature.

```ruby
require 'cloud_context'

CloudContext['request_id'] = 'abc-123'
CloudContext['tenant_id']  = 42

# ...any HTTP call made with Faraday or Sidekiq job enqueued
#    downstream will carry these values along.
```


## Installation

```ruby
# Gemfile
gem 'cloud_context'
```

```sh
bundle install
```


## Usage

`CloudContext` behaves like a `Hash`, scoped to the current thread:

```ruby
CloudContext['request_id'] = 'abc-123'
CloudContext['request_id']           # => "abc-123"
CloudContext.fetch('request_id')     # => "abc-123"
CloudContext.fetch('missing')        # => raises KeyError
CloudContext.to_h                    # => { "request_id" => "abc-123" }

CloudContext.update(user_id: 7, tenant_id: 42)

CloudContext.delete('request_id')
CloudContext['tenant_id'] = nil      # equivalent to .delete
CloudContext.clear

CloudContext.empty?                  # => true
CloudContext.size                    # => 0
```

Keys are stringified, so `:user_id` and `'user_id'` are equivalent.

Values must be round-trippable through JSON — strings, numbers, booleans,
arrays, and hashes are fine.  Symbols, `Time`, and other non-JSON-native
types will raise `ArgumentError` at assignment time so problems surface
at the call site rather than across the wire.

```ruby
CloudContext['user_id'] = :alice      # raises ArgumentError
CloudContext['ts']      = Time.now    # raises ArgumentError
```


## Propagating across the network

### Rails

Just require it.  The Railtie installs Rack middleware that hydrates
`CloudContext` from the incoming request and isolates each request's
context from the next.

```ruby
# Gemfile
gem 'cloud_context'
```

### Rack

For non-Rails Rack apps, mount the middleware:

```ruby
require 'cloud_context/rack'

use CloudContext::Rack::Adapter
```

### Faraday

Add the middleware to any Faraday connection that should forward context
downstream:

```ruby
require 'cloud_context/faraday'

conn = Faraday.new(url: 'https://service.internal') do |f|
  f.use :cloud_context
  f.adapter Faraday.default_adapter
end

CloudContext['request_id'] = 'abc-123'
conn.get('/widgets')   # sends X-Cloud-Context: {"request_id":"abc-123"}
```

Per-connection overrides:

```ruby
# send a different header name
f.use :cloud_context, header: 'X-Trace-Context'

# send a custom payload instead of CloudContext.to_h
f.use :cloud_context, context: -> { { request_id: Current.request_id } }
```

### Sidekiq

Requiring `cloud_context/sidekiq` installs both client and server
middleware automatically, so context propagates from the enqueuer into
the worker — and from one worker into any jobs it enqueues.

```ruby
require 'cloud_context/sidekiq'

CloudContext['request_id'] = 'abc-123'
SomeWorker.perform_async   # job carries CloudContext along
```


## Scoping context with `contextualize`

`contextualize` runs a block with a fresh, empty context, then restores
the previous one — even if the block raises.  This is what the Rack and
Sidekiq adapters use internally to isolate one request or job from the
next, and it's also useful directly:

```ruby
CloudContext['tenant_id'] = 42

CloudContext.contextualize do
  CloudContext['tenant_id'] = 99
  do_some_work   # sees tenant_id => 99
end

CloudContext['tenant_id']   # => 42
```


## Configuration

By default, `CloudContext` uses the HTTP header `X-Cloud-Context`.  To
change it globally:

```ruby
CloudContext.http_header = 'X-Trace-Context'
```

Header names are normalized to uppercase with underscores, matching Rack's
`HTTP_*` env conventions.


## Testing with RSpec

To clear `CloudContext` between examples, enable the RSpec adapter in
your `spec_helper.rb`:

```ruby
require 'cloud_context/rspec'

CloudContext::RSpec.enable
```

This installs an `after(:example)` hook that calls `CloudContext.clear`.
Call `CloudContext::RSpec.disable` to turn it off without removing the
hook.


## Size Limitations

While there is technically no limit to header size, servers generally
enforce limits.  For example, Apache's default is 8KB and will return
HTTP 413 - Entity Too Large.  Headers also add overhead to every request,
so use `CloudContext` sparingly.  To approximate byte size:

```ruby
CloudContext.bytesize
```


## Threading

`CloudContext` allocates a separate context per thread (and per Fiber).
Contexts are not shared across threads, so worker pools and async
frameworks won't leak state between concurrent units of work.


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
