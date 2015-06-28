## What is RabbitMQ-memcached ##
[RabbitMQ](http://www.rabbitmq.com/) is a complete and highly reliable enterprise messaging system based on the [emerging AMQP standard](http://www.rabbitmq.com/specification.html).

Even the AMQP standard is very powerful, it also means that we should introduce a new complicated protocol and a lot concepts, such as exchange, queue, vhost and binding etc. So, why not just reuse a simple and well known protocol, like memcache, get and put the message with any client language.

The rabbitmq-memcached project is a memcached adapter for the [RabbitMQ](http://www.rabbitmq.com/) server, which allow you use [the memcache protocol](http://github.com/memcached/memcached/blob/master/doc/protocol.txt) to get or publish a message from or to RabbitMQ, just like the [memcached](http://memcached.org/) based [MemcacheQ](http://memcachedb.org/memcacheq/) (Simple Queue Service over Memcache) project.

Both of RabbitMQ and RabbitMQ-memcached are licensed under the open source Mozilla Public License and has a platform-neutral distribution, plus platform-specific packages and bundles for easy installation.

## Example ##
```
import memcache

mc = memcache.Client(...) # create a memcache client

mc.set('exchange', 'hello world') # publish the message through memcache

body = mc.get('queue') # get the message from queue through memcache get
```
## Deployment ##

The rabbitmq-memcached could act as [a standalone proxy](RunAsProxy.md) or [an embedded plugin](RunAsPlugin.md), and support TCP and UDP based memcache protocol.