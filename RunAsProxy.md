# Introduction #

RabbitMQ-memcached can be run as a standalone AMQP proxy, which will receive the client request with memcache protocol, and forward the message to or from the RabbitMQ with AMQP protocol. The client could just use get and set method of memcache method to play with messages.

The proxy mode could provide high stability because the RabbitMQ and RabbitMQ-memcached run in two processes or machines, but it will pay a little performance cost.

# Details #

  1. Download the RabbitMQ-memcached package
  1. Extract the package to a folder, like %RABBITM\_MEMCACHED%
  1. Edit the application configuration file, at %RABBITM\_MEMCACHED%/ebin/rabbit\_memcached.app
  1. Modify the settings in the server\_mode section with your server
```
            %{ server_mode, local },
            { server_mode, { remote, [
                { username, "guest" },
                { password, "guest" },
                { virtual_host, "/" },
                { host, "localhost" },
                { port, 5672 },
                { ssl_options, none }    
            ]}},
```
  1. Modify the TCP and UDP listener address and port in the listeners section
  1. Start the server with %RABBITM\_MEMCACHED%/scripts/rabbitmq-memcached