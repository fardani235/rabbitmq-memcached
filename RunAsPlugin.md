# Introduction #

RabbitMQ-memcached can be run as an embedded RabbitMQ plugin, which will be started in the same process of RabbitMQ, and receive the client request with memcache protocol, forward the message to or from the RabbitMQ with Erlang Message. The client could just use get and set method of memcache method to play with messages.

The plugin mode could provide the ultimate performance, better than the AMQP protocol itself in theory, because it direct interactive with RabbitMQ at Erlang message level.

# Details #

  1. Download the RabbitMQ-memcached package
  1. Extract the package to a folder, like %RABBITM\_MEMCACHED%
  1. Edit the application configuration file, at %RABBITM\_MEMCACHED%/ebin/rabbit\_memcached.app
  1. Modify the server\_mode section as local mode
```
            { server_mode, local },
            % { server_mode, { remote, [
            %    { username, "guest" },
            %    { password, "guest" },
            %    { virtual_host, "/" },
            %    { host, "localhost" },
            %    { port, 5672 },
            %    { ssl_options, none }    
            ]}},
```
  1. Modify the TCP and UDP listener address and port in the listeners section
  1. Install the plugin in the RabbitMQ server, please check its [plugin document](http://www.rabbitmq.com/plugin-development.html) for more detail