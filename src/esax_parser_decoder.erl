-module(esax_parser_decoder).

-include("esax_parser.hrl").

-export([file/2, stream/2]).

%% API FUNCTION

file(Name, Options) ->
    case file:read_file(Name) of 
        {error, Reason} ->
            ?LOG_ERROR("Error read file ~p~n", [Reason]);
        {ok, Bin} ->
            stream(Bin, Options)           
    end.

%% INTERNAL FUNCTION

stream(Bin, Options) ->
    Fun = parse_options(Options),
    Bin1 = advert(Bin, Fun),
    Bin2 = doctype(ltrim(Bin1)),
    content(Bin2, Fun).

content(Bin, Fun) ->
    Bin1 = ltrim(Bin),
    case Bin1 of
        <<"<!--", _/binary>> ->
            Rest = comment(Bin1, Fun),
            content(Rest, Fun);
        <<"<![CDATA[", _/binary>> ->
            Rest = cdata(Bin1, Fun),
            content(Rest, Fun);
        <<"<", _/binary>> ->
            Rest = tag(Bin1, Fun),
            content(Rest, Fun);
        <<>> ->
            Fun(endChunk);
        <<_Text/binary>> ->
            Rest = tag_content(Bin1, Fun),
            content(Rest, Fun);
        ok ->
            ok;
        {endChunk, rest, Rest} ->
            {endChunk, rest, Rest}
    end.            


advert(<<"<?xml", Bin/binary>>, Fun) -> 
    [_, Rest] = binary:split(Bin, <<"?>">>),
    Fun(startDocument),
    Rest;
advert(Bin, _Fun) ->
    Bin.

doctype(<<"<!DOCTYPE", Bin/binary>>) -> 
    [_, Rest] = binary:split(Bin, <<">">>),
    Rest;
doctype(Bin) ->
    Bin.

tag(Chunk = <<"<", Bin/binary>>, Fun) ->
    case binary:split(Bin, <<">">>) of                   
        [TagHeader1, Rest] ->
            Len = size(TagHeader1)-1, 
            Rest1 = case TagHeader1 of
                <<"/", TagHeader/binary>> ->
                    {Name, Attributes} = tag_header(TagHeader),
                    Fun({endElement, Name, Attributes}),
                    Rest;
                <<TagHeader:Len/binary, "/">> ->
                    {Name, Attributes} = tag_header(TagHeader),
                    Fun({startElement, Name, Attributes}),
                    Fun({endElement, Name, Attributes}),
                    Rest;
                _TagHeader ->
                    check_end(TagHeader1, Rest, Bin, Fun)
            end,
            Rest1;
        [_Rest] ->
            {endChunk, rest, Chunk}
    end.

tag_header(TagHeader) ->
    case binary:split(TagHeader, <<" ">>) of
        [Tag] -> 
            {Tag, []};
        [Tag, Attrs] -> 
            {Tag, tag_attrs(Attrs)}
    end.

tag_attrs(<<Blank, Bin/binary>>) when ?IS_BLANK(Blank) ->
    tag_attrs(Bin);
tag_attrs(<<>>) ->
    [];
tag_attrs(Attrs) ->
    [Key, Value1] = binary:split(Attrs, <<"=">>),
    [Value2, Rest] = attr_value(ltrim(Value1)),
    [{rtrim(Key), unescape(Value2)}|tag_attrs(Rest)].

attr_value(<<Quote, Value/binary>>) when ?IS_QUOTE(Quote) ->
    binary:split(Value, <<Quote>>).

tag_content(Bin, Fun) ->
    [Content, Rest] = binary:split(rtrim(Bin), <<"</">>),
    Content1 = rtrim(Content), 
    Fun({characters, Content1}),
    content(<<"</", Rest/binary>>, Fun).
        

comment(Chunk = <<"<!--", Bin/binary>>, Fun) -> 
    case  binary:split(ltrim(Bin), <<"-->">>) of
    [Comment, Rest] ->
        Comment1 = rtrim(Comment),
        Fun({comment, Comment1}),
        Rest;
    [<<>>] ->
        <<>>;
    [_Rest] ->
        {endChunk, rest, Chunk}
    end.

cdata(Chunk = <<"<![CDATA[", Bin/binary>>, Fun) -> 
    case binary:split(Bin, <<"]]>">>) of
    [Cdata, Rest] ->
        Fun({cdata, Cdata}),
        Rest; 
    [<<>>] ->
        <<>>;
    [_Rest] ->
        {endChunk, rest, Chunk}
    end.

ltrim(<<Blank, Bin/binary>>) when ?IS_BLANK(Blank) ->
    ltrim(Bin);
ltrim(Bin) -> 
    Bin.

rtrim(<<>>) ->
    <<>>;
rtrim(Bin) ->
    case binary:last(Bin) of
        Blank when ?IS_BLANK(Blank) ->
            Size = size(Bin) - 1,
            <<Part:Size/binary, _/binary>> = Bin,
            rtrim(Part);
        _ ->
            Bin
    end.

unescape(Bin) ->
    case binary:split(Bin, <<"&">>) of
        [Unescaped] ->
            Unescaped;
        [Unescaped, Rest1] ->
            {Char, Rest3} = case Rest1 of
                <<"quot;", Rest2/binary>> -> {$", Rest2};
                <<"apos;", Rest2/binary>> -> {$', Rest2};
                <<"lt;", Rest2/binary>> -> {$<, Rest2};
                <<"gt;", Rest2/binary>> -> {$>, Rest2};
                <<"amp;", Rest2/binary>> -> {$&, Rest2}
            end,
            <<Unescaped/binary, Char, (unescape(Rest3))/binary>>
    end. 

parse_options(Options) ->
    case Options of     
        [] ->
            fun default_event/1;
        [{event_fun, Fun}] ->
            Fun
    end.

check_end(TagHeader, Rest, Bin, Fun) ->
    case binary:split(Rest, <<">">>) of
        [_Content, _Rest1] ->
            {Name, Attributes} = tag_header(TagHeader),
            Fun({startElement, Name, Attributes}),
            Rest;
        [_Rest] ->
            {endChunk, rest, <<"<", Bin/binary>>}
    end.            

default_event(Event) ->
    io:format("Event ~p~n", [Event]).             
