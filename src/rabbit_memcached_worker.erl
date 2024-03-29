%%   The contents of this file are subject to the Mozilla Public Licenses
%%   Version 1.1 (the "License"); you may not use this file except in
%%   compliance with the License. You may obtain a copy of the License at
%%   http://www.mozilla.org/MPL/
%%
%%   Software distributed under the License is distributed on an "AS IS"
%%   basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
%%   License for the specific language governing rights and limitations
%%   under the License.
%%
%%
%%   Contributor(s): ______________________________________.
%%
-module(rabbit_memcached_worker).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include_lib("amqp_client/include/amqp_client.hrl").

%% --------------------------------------------------------------------
%% External exports
-export([start/0, start/2, stop/0, stop/1, start_link/1]).
-export([get/1, put/2]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {connection, channel}).
-define(RKFormat, "~4.10.0B.~2.10.0B.~2.10.0B.~1.10.0B.~2.10.0B.~2.10.0B.~2.10.0B").

%% ====================================================================
%% External functions
%% ====================================================================
start() ->
    start_link(local),
    ok.

start(normal, []) ->
    start_link(local).

stop() ->
    ok.

stop(_State) ->
    stop().

start_link(Params) ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, Params, []).

get(Queue) ->
    gen_server:call(?MODULE, {get, Queue}).

put(Exchange, Data) ->
    gen_server:call(?MODULE, {put, Exchange, Data}).

%% ====================================================================
%% Server functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init(local) ->
    process_flag(trap_exit, true),
    
    io:format("connect RabbitMQ server w/ local mode\n"),
    
    Connection = amqp_connection:start_direct(),
    Channel = amqp_connection:open_channel(Connection),
    {ok, #state{connection = Connection, channel = Channel}};

init({ remote, Params }) when is_list(Params) ->
    Connection = amqp_connection:start_network(parse_params(Params, #amqp_params{})),
    Channel = amqp_connection:open_channel(Connection),
    {ok, #state{connection = Connection, channel = Channel}}.

parse_params([], Params) ->
    Params;
parse_params([{username, Value} | L], Params) when is_list(Value) ->
    parse_params(L, Params#amqp_params{ username = list_to_binary(Value) });
parse_params([{password, Value} | L], Params) when is_list(Value) ->
    parse_params(L, Params#amqp_params{ password = list_to_binary(Value) });
parse_params([{virtual_host, Value} | L], Params) when is_list(Value) ->
    parse_params(L, Params#amqp_params{ virtual_host = list_to_binary(Value) });
parse_params([{host, Value} | L], Params) when is_list(Value) ->
    parse_params(L, Params#amqp_params{ host = Value });
parse_params([{port, Value} | L], Params) when is_integer(Value) ->
    parse_params(L, Params#amqp_params{ port = Value });
parse_params([{ssl_options, Value} | L], Params) when is_atom(Value) ->
    parse_params(L, Params#amqp_params{ ssl_options = Value }).

%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_call({get, Queue}, _From, State = #state{connection=Connection, channel=Channel}) ->
    Method = #'basic.get'{queue = Queue, no_ack = true},    
    
    try amqp_channel:call(Channel, Method) of
        { #'basic.get_ok'{routing_key=Key}, #amqp_msg {payload=Content} } ->            
            {reply, {ok, {Key, Content}}, State};
        #'basic.get_empty'{} ->
            {reply, empty, State}
    catch            
        exit:{{server_initiated_close, 404, Reason}, _} ->
            {reply, {error, Reason}, State#state{channel=amqp_connection:open_channel(Connection)}};
        exit:Error ->
            {reply, {error, Error}, State}
    end;

handle_call({put, Exchange, Data}, _From, State = #state{connection=Connection, channel = Channel}) ->
    Props = #'P_basic'{content_type = <<"text/plain">>, delivery_mode = 1},
    {Date={Year,Month,Day},{Hour, Min,Sec}} = erlang:universaltime(),
    DayOfWeek = calendar:day_of_the_week(Date),
    RoutingKey = list_to_binary(io_lib:format(?RKFormat, [Year, Month, Day, DayOfWeek, Hour, Min, Sec])),    
    Method =  #'basic.publish'{exchange = Exchange, routing_key = RoutingKey},
    Content = #amqp_msg{props = Props, payload = Data},
    try amqp_channel:call(Channel, Method, Content) of
        ok ->
            {reply, ok, State}        
    catch
        exit:{{server_initiated_close, 404, Reason}, _} ->
            {reply, {error, Reason}, State#state{channel=amqp_connection:open_channel(Connection)}};
        exit:Error ->
            {reply, {error, Error}, State}
    end;

handle_call(Request, _From, State) ->
    {stop, {unknown_call, Request}, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_cast(_Msg, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info(_Info, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_, #state{channel = Channel}) ->
    amqp_channel:close(Channel),
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

