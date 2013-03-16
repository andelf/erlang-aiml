%%%-------------------------------------------------------------------
%%% @author Wang Shuyu <wangshuyu@FeatherAir>
%%% @copyright (C) 2013, Wang Shuyu
%%% @doc
%%%
%%% @end
%%% Created : 15 Mar 2013 by Wang Shuyu <wangshuyu@FeatherAir>
%%%-------------------------------------------------------------------
-module(xmerl_aiml).

%% API
-export([]).
%% xmerl callbacks
-export(['#xml-inheritance#'/0,
         '#root#'/4,
         '#element#'/5,
         '#text#'/1]).
%-export([msg/4, font/4, text/4, url/4, face/4, cface/4,
%        img/4, reply/4, thumb/4, imagedata/4]).
-export([main/1]).
-compile([export_all]).
-include_lib("xmerl/include/xmerl.hrl").

%%%===================================================================
%%% API
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------
'#xml-inheritance#'() ->
    [].

'#text#'(Text) ->
    % io:format("text: ~p~n", [Text]),
    trim_whitespace(Text).

'#root#'(Data, _Attrs, [], _E) ->
    io:format("ALL: ~p~n", [Data]),
    hd(Data).

'#element#'(Tag, Data, Attrs, _Parents, _E) ->
    io:format("unknown tag: ~p attr: ~w~n", [Tag, Attrs]),
    Data.

%% {rule, {pattern(), that(), topic()}, template()}
aiml(Data, Attr, _, _) ->
    [#xmlAttribute{name=Name}] = Attr,
    Topic = proplists:get_value(topic, Data),
    io:format("~p~n", [Data]),
    Result = lists:foldl(fun([], Acc) -> Acc;
                            (Rules, Acc) when is_list(Rules) ->
                                 Acc ++ Rules;
                            ({category, {Pt, Th}, Tm}, Acc)  ->
                                 [{rule, {Pt, Th, undefined}, Tm}|Acc]
                         end,
                         [],
                         Data),
    {aiml, Result}.

topic(Data, Attr, _, _) ->
    [#xmlAttribute{name=name, value=Topic}] = Attr,
    lists:map(fun({category, {Pattern, That}, Template}) ->
                      {rule, {Pattern, That, Topic}, Template}
              end,
              filter_empty_string(Data)).

category(Data, _, _, _) ->
    Pattern = proplists:get_value(pattern, Data),
    That = proplists:get_value(that, Data),
    Template = proplists:get_value(template, Data),
    {category, {Pattern, That}, Template}.

%% <pattern> has no child element
pattern([Data], _, _, _) ->
    {pattern, Data}.

%% <that index=".." />
that([], Attr, _, _) ->
    [#xmlAttribute{name=index, value=Index}] = Attr,
    case string:tokens(Index, ",") of
        [X] -> {thatindex, list_to_integer(X), 1};
        [X, Y] -> {thatindex, list_to_integer(X), list_to_integer(Y)}
    end;
that([Data], _, _, _) ->
    {that, Data}.

template(Data, _, _, _) ->
    {template, filter_empty_string(Data)}.

star([], [], _, _) ->
    {star, 1};
star(Data, Attr, _, _) ->
    [#xmlAttribute{name=index, value=Index}] = Attr,
    {star, list_to_integer(Index)}.

input([], Attr, _, _) ->
    [#xmlAttribute{name=index, value=Index}] = Attr,
    {input, list_to_integer(Index)}.

thatstar([], Attr, _, _) ->
    [#xmlAttribute{name=index, value=Index}] = Attr,
    {thatstar, list_to_integer(Index)}.

topicstar([], Attr, _, _) ->
    [#xmlAttribute{name=index, value=Index}] = Attr,
    {topicstar, list_to_integer(Index)}.

get(_, Attr, _, _) ->
    [#xmlAttribute{name=name, value=Name}] = Attr,
    {get, Name}.

bot(_, Attr, _, _) ->
    [#xmlAttribute{name=Name}] = Attr,
    {bot, Name}.

sr([], [], _, _) ->
    {srai, {star, 1}}.

%% <person2 />
person2([], [], _, _) ->
    {persion2, {star, 1}};
person2(Data, [], _, _) ->
    {person2, Data}.

%% <person />
person([], [], _, _) ->
    {person, {star, 1}};
person(Data, [], _, _) ->
    {person, Data}.

gender([], [], _, _) ->
    {gender, {star, 1}};
gender(Data, _, _, _) ->
    {gender, Data}.

date([], Attr, _, _) ->
    [] = Attr,
    {date, "format_here"}.

id([], [], _) ->
    id.

size([], [], _, _) ->
    size.

version([], [], _, _) ->
    version.

uppercase(Data, _, _, _) ->
    {uppercase, Data}.

lowercase(Data, _, _, _) ->
    {lowercase, Data}.

formal(Data, _, _, _) ->
    {formal, Data}.

sentence(Data, _, _, _) ->
    {sentence, Data}.

%% FIXME: <condition> has 3 types
condition(Data, Attr, _, _) ->
    Props = lists:map(fun(#xmlAttribute{name=Name, value=Value}) ->
                              {Name, Value}
                      end, Attr),
    {condition, Props, filter_empty_string(Data)}.

random(Data, _, _, _) ->
    {random, filter_empty_string(Data)}.


%% FIXME: <li> has 3 types
li(Data, Attr, _, _) ->
    Props = lists:map(fun(#xmlAttribute{name=Name, value=Value}) ->
                              {Name, Value}
                      end, Attr),
    {li, Props, Data}.

set(Data, Attr, _, _) ->
    [#xmlAttribute{name=name, value=Name}] = Attr,
    {set, Name, Data}.

gossip(Data, _, _, _) ->
    {gossip, Data}.


srai(Data, _, _, _) ->
    {srai, filter_empty_string(Data)}.

think(Data, _, _, _) ->
    {think, Data}.

%% <learn> for AIML loading
learn(Data, _, _, _) ->
    io:format("<learn> loading: ~p~n", [Data]),
    [File] = Data,
    {Doc, _} = xmerl_scan:file(File),
    {'#xml-redefine#', [Doc]}.

system(Data, _, _, _) ->
    {system, Data}.

javascript(Data, _, _, _) ->
    {javascript, Data}.


main(_) ->
    %{Doc, _} = xmerl_scan:file("./cn-test.aiml"),
    {Doc, _} = xmerl_scan:file("./std-lizards.aiml"),
    xmerl:export([Doc], ?MODULE).

%%%===================================================================
%%% Internal functions
%%%===================================================================
trim_whitespace(Input) ->
    LS = re:replace(Input, "^\\s*", "", [unicode, {return, list}]),
    RS = re:replace(LS, "\\s*$", "", [unicode, {return, list}]),
    RS.

filter_empty_string(List) ->
    lists:filter(fun([]) -> false;
                    (_)  -> true
                 end,
                 List).
