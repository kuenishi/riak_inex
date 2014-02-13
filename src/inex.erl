-module(inex).

-export([main/1]).

usage() ->
    io:format("inet <host> <port> <bucketname> <datafile>~n"
              "accepted suffices: csv~n").

main([Host, Port0, Bucketname, File]) ->
    ok = application:start(gen_queue),
    ok = application:start(poolcat),

    Port = list_to_integer(Port0),
    {ok, Pid} = poolcat:create_pool(?MODULE, inex_worker, 4,
                                    {Host, Port}),
    io:format("connecting ~p ~p, to import ~p~n", [Host, Port, File]),

    %% {ok, Schema} = parse_schema(SchemaFile),
    ok = loop_start(File, unicode:characters_to_binary(Bucketname)),

    poolcat:safe_destroy_pool(?MODULE, Pid),
    ok = application:stop(poolcat),
    ok = application:stop(gen_queue),
    ok;
main(_) ->
    usage().

%% parse_schema(SchemaFile) ->
%%     {ok, Data} = file:consult(SchemaFile),
%%     io:format("~p", [Data]),
%%     {ok, Data}.

loop_start(File, Bucket) ->
    case string:to_lower(filename:extension(File)) of
        ".csv" ->
            inex_csv_parser:parse(File, Bucket,
                                  fun(RObject) ->
                                          poolcat:push_task(?MODULE, RObject)
                                  end);
        _ ->
            {error, wrong_suffix}
    end.
