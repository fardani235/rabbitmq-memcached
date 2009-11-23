{ application, rabbit_memcached,
    [
        { description, "Embedded RabbitMQ Memcached Adapter" },
        { vsn, "0.01" },
        %{ sasl, [ 
        %    { sasl_error_logger, {file, "logs/sasl.log"} },
        %    { errlog_type, error },
        %    { error_logger_mf_dir, "logs/memcached.log" },
        %    { error_logger_mf_maxbytes, 1024000 },
        %    { error_logger_mf_maxfiles, 100 }
        %]},
        { modules, [
            rabbit_memcached_app,
            rabbit_memcached_server_sup,
            rabbit_memcached_server,
            rabbit_memcached_worker,
            rabbit_memcached_stats,
            tcp_acceptor_sup,  
            tcp_acceptor,        
            tcp_listener_sup,
            tcp_listener
        ]},
        { registered, [] },
        { mod, {rabbit_memcached_app, []} },
        { env, [
            %{ server_mode, local },
            { server_mode, { remote, [
                { username, "guest" },
                { password, "guest" },
                { virtual_host, "/" },
                { host, "localhost" },
                { port, 5672 },
                { ssl_options, none }    
            ]}},
            { server_module, rabbit_memcached_server },
            { listeners, [ 
                { tcp, "0.0.0.0", 11211 }
            ]}
        ]},
        %{ applications, [kernel, stdlib, rabbit, amqp_client]}
        { applications, [kernel, stdlib]}
    ] 
}.