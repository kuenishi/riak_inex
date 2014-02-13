-module(inex_worker).

-behaviour(poolcat_worker).

-export([handle_pop/2, init/1, terminate/2]).

handle_pop(RObject, Conn) ->
    {ok, _} = riakc_pb_socket:put(Conn, RObject),
    {ok, Conn}.

init({Host,Port}) ->
    case riakc_pb_socket:start(Host,Port) of
        {ok, Conn} -> {ok, Conn};
        E ->          io:format("~p~n", [E])
    end.

terminate(_, Conn) ->
    ok = riakc_pb_socket:stop(Conn).
