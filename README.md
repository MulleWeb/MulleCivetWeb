# MulleCivetWeb

#### 🦊 HTTP Server for mulle-objc

MulleCivetWeb is a "WebServer as a library". It is based on
[civetweb](//github.com/civetweb/civetweb).

### You are here

```
   .------------------------------.
   | MulleWebServer               |
   '------------------------------'
   .================.
   | CivetWeb       |
   '================'
   .----------------..------------.
   | HTTP           || JSMN       |
   '----------------''------------'
   .----------------..------------.
   | Inet           || Plist      |
   '----------------''------------'
   .------..----------------------.
   | Lock || Standard             |
   '------''----------------------'
```

## About

MulleCivetWeb add the following principal classes:

Class                       | Description
----------------------------|-----------
`MulleCivetWebServer`       | The WebServer class. Add your request handler to it.
`MulleCivetWebRequest`      | Requests as received by the MulleCivetWebServer
`MulleCivetWebResponse`     | Responses returned by a request handler. They contain header information and the reponse content.
`MulleCivetWebTextResponse` | Subclass of MulleCivetWebResponse to produce plain text, JSON, HTML...

#### Example

You typically interact with MulleCivetWeb by creating a
**MulleCivetWebServer** object, and by attaching a
**MulleCivetWebRequestHandler** to it:


``` objc
@interface MyRequestHandler : NSObject < MulleCivetWebRequestHandler>
@end


int   main( int argc, char *argv[])
{
   MulleCivetWebServer  *server;
   MyRequestHandler     *handler;

   server  = [MulleCivetWebServer object];

   // the server is already running now!
   handler = [MyRequestHandler object];
   [server setRequestHandler:handler];

   return( 0);
}
```

The request handler will receive `MulleCivetWebRequests` and return
`MulleCivetWebResponses`:

``` objc
@implementation MyRequestHandler

- (MulleCivetWebResponse *) webResponseForWebRequest:(MulleCivetWebRequest *) request
{
   MulleCivetWebTextResponse   *response; // subclass of MulleCivetWebResponse

   response = [MulleCivetWebTextResponse webResponseForWebRequest:request];
   [response appendFormat:@"Method is %@\n",
                     [request method] == MulleHTTPPost ? @"POST" : @"GET"]
   [response appendFormat:@"Accept-Encoding is %@",
                     [request headerValueForKey:MulleHTTPAcceptEncodingKey]];
   [response appendString:@"Hello World"];
   return( response);
}

@end
```

That's it.


## Add

Use [mulle-sde](//github.com/mulle-sde) to add MulleCivetWeb to your project:

```
mulle-sde dependency add --objc --github MulleWeb MulleCivetWeb
```

## Install

Use [mulle-sde](//github.com/mulle-sde) to build and install MulleCivetWeb and
all its dependencies:

```
mulle-sde install --objc --prefix /usr/local \
   https://github.com/MulleWeb/MulleCivetWeb/archive/latest.tar.gz
```

## Acknowledgements

MulleZlib links against [civetweb](https://github.com/civetweb/civetweb).
civetweb was forned from the MIT version of Mongoose, whose original author
is Sergey Lyubka.


## Author

[Nat!](//www.mulle-kybernetik.com/weblog) for
[Mulle kybernetiK](//www.mulle-kybernetik.com) and
[Codeon GmbH](//www.codeon.de)
