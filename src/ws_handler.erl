-module(ws_handler).
-behaviour(cowboy_websocket_handler).

-export([init/3]).
-export([websocket_init/3]).
-export([websocket_handle/3]).
-export([websocket_info/3]).
-export([websocket_terminate/3]).

-define(PRESENCE, {global, presence_handler}).
-define(CHANNEL, {global, channel_handler}).

init({tcp, http}, _Req, _Opts) ->
    {upgrade, protocol, cowboy_websocket}.

websocket_init(_TransportName, Req, _Opts) ->
    {ok, Req, undefined_state}.

websocket_handle({text, <<"register:",Username/binary>>}, Req, State) ->
    UserProcess = list_to_binary(pid_to_list(self())),
    gen_event:notify(?PRESENCE,
					 <<"register",
					   ":username:",Username/binary,
					   ":userprocess:",UserProcess/binary>>),
    {reply, {text, Username}, Req, State};

websocket_handle({text, <<"subscribe:",Channel/binary>>}, Req, State) ->
	UserProcess = list_to_binary(pid_to_list(self())),
	gen_event:notify(?CHANNEL,
					 <<"subscribe",
					   ":channel:",Channel/binary,
					   ":userprocess:",UserProcess/binary>>),
	{reply, {text, ok}, Req, State};

websocket_handle({text, Msg}, Req, State) ->
    {reply, {text, <<Msg/binary >>}, Req, State};

websocket_handle(_Data, Req, State) ->
    {ok, {text, _Data}, Req, State}.

websocket_info({timeout, _Ref, Msg}, Req, State) ->
    {reply, {text, Msg}, Req, State};

websocket_info(Msg, Req, State)->
    {reply, {text, <<Msg/binary>>}, Req, State}.


websocket_terminate(_Reason, _Req, _State) ->
	UserProcess = list_to_binary(pid_to_list(self())),
	gen_event:notify(?PRESENCE,
					 <<"disconnect",":userprocess:",UserProcess/binary>>),
    ok.
