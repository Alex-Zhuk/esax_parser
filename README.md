XML SAX parser
=============================

 API
----

```
 Function: file(Filename, Options) -> Result

 Function: stream(Stream, Options) -> Result

 Input:    Filename = string()

           Stream = binary()

           Options = [{OptTag, EventFun()}]

           OptTag = event_fun

           EventFun(Event) -> Result1
                        This function is called for every event sent by the parser. 

 Output:   Result = {endChunk, rest, Rest()} | ok

           Rest() = binary()                            
```

```
           Event =
                             startDocument            
                                              Receive notification of the beginning of a document. 
                                              The SAX parser will send this event only once 
                                              after xml prolog. 

                             endChunk
                                              Receive notification of the end of a document. 
                                              The SAX parser will send this event only once, 
                                              and it will be the last event during the parse.

                            {startElement, Name, Attributes}
                                    Name = binary()
                                    Attributes = list()
                                              Receive notification of the beginning of an element. 
                                              The Parser will send this event at the 
                                              beginning of every element in the XML document.                

                            {endElement, Name, Attributes}
                                    Name = binary()
                                    Attributes = list()
                                              Receive notification of the end of an element. 
                                              The SAX parser will send this event 
                                              at the end of every element in the XML document.
                
                            {characters, Content}
                                    Content = binary()
                                              Receive notification of character data.

                            {comment, Comment}
                                    Comment = binary()
                                              Report an XML comment anywhere in the document.

                            {cdata, Cdata}
                                    Cdata = binary()
                                             Report an XML CDATA anywhere in the document.
```

  Example
---------
 Chunk of xml file test.xml contain next content
 
```
 <?xml version="1.0" encoding="utf-8"?>
    <aw:Address aw:Type="Shipping"> <!-- Comment -->
      <aw:Name>Ellen Mills</aw:Name>
      <aw:Street>123 Maple Street</aw:Street>
      <aw:City>Mill Valley</aw:City>
    </aw:Address>
    <aw:Phone>38099
```

 Run parsing

 esax_parser_decoder:file("test.xml", [{event_fun, fun (E) -> io:format("~p~n", [E]), ok end}]).

 Output after parsing

```
 startDocument
 {startElement,<<"aw:Address">>,[{<<"aw:Type">>,<<"Shipping">>}]}
 {comment,<<"Comment">>} 
 {startElement,<<"aw:Name">>,[]}
 {characters,<<"Ellen Mills">>}
 {endElement,<<"aw:Name">>,[]}
 {startElement,<<"aw:Street">>,[]}
 {characters,<<"123 Maple Street">>}
 {endElement,<<"aw:Street">>,[]}
 {startElement,<<"aw:City">>,[]}
 {characters,<<"Mill Valley">>}
 {endElement,<<"aw:City">>,[]}
 {endElement,<<"aw:Address">>,[]}
 {endChunk,rest,<<"<aw:Phone>38099">>}
```
