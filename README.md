# 🦡 MulleCivetWeb

MulleCivetWeb is a WebServer as a library. It is based on
[civetweb](//github.com/civetweb/civetweb). You typically interact with
MulleCivetWeb by creating a webserver object, and attaching your request
handler to it:

``` objc
@interface MyRequestHandler : NSObject < MulleCivetWebRequestHandler>
@end


int   main( int argc, char *argv[])
{
   MulleCivetWebServer  *server;
   MyRequestHandler     *handler;

   @autoreleasepool
   {
      server  = [MulleCivetWebServer object];

      // the server is already running now!
      handler = [MyRequestHandler object];
      [server setRequestHandler:handler];

      getchar();
      // the server will die now...
   }
   return( 0);
}
```

The request handler will receive `MulleCivetWebRequests` and return
`MulleCivetWebResponses`:

``` objc
@implementation MyRequestHandler

- (MulleCivetWebResponse *) webResponseForWebRequest:(MulleCivetWebRequest *) request
{
   MulleCivetWebTextResponse  *response;

   response = [MulleCivetWebTextResponse webResponseForWebRequest:request];
   [response setObject:@"text/plain"
                forKey:MulleCivetWebContentTypeKey];

   [response appendString:@"Hello World"];
   return( response);
}

@end
```


Class                       | Description
----------------------------|-----------
`MulleCivetWebServer`       | The WebServer class. Add your request handler to it.
`MulleCivetWebRequest`      | Requests as received by the MulleCivetWebServer
`MulleCivetWebResponse`     | Responses returned by a request handler. They contain header information and the reponse content.
`MulleCivetWebTextResponse` | Subclass of MulleCivetWebResponse to produce plain text, JSON, HTML...


## Build

This is a [mulle-sde](https://mulle-sde.github.io/) project.

It has it's own virtual environment, that will be automatically setup for you
once you enter it with:

```
mulle-sde MulleCivetWeb
```

Now you can let **mulle-sde** fetch the required dependencies and build the
project for you:

```
mulle-sde craft
```


## Author

[Nat!](//www.mulle-kybernetik.com/weblog) for
[Mulle kybernetiK](//www.mulle-kybernetik.com) and
[Codeon GmbH](//www.codeon.de)
