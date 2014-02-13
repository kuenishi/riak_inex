-module(inex_csv_parser).

-export([parse/3]).

parse(File, Bucket, Emit) when is_function(Emit) ->

    {ok, IoDevice} = file:open(File, [read]),
    MyFun = fun({newline, NewLine}, I) ->
                    handle_line(NewLine, Bucket, Emit),
                    I+1;
               ({eof}, I) ->
                    io:format("~p lines imported.~n", [I]),
                    I
            end,
    {ok, _} = ecsv:process_csv_file_with(IoDevice, MyFun, 0),
    file:close(IoDevice).

handle_line(Line, Bucket, Emit) ->
    JSON = jsx:encode(lists:map(fun unicode:characters_to_binary/1, Line)),
    Key = undefined,
    RObject = riakc_obj:new(Bucket, Key, JSON, "application/json"),
    Emit(RObject).
