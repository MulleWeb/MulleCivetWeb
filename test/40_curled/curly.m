#import <MulleCivetWeb/MulleCivetWeb.h>
#import <MulleCurl/MulleCurl.h>
#import <MulleCivetWeb/private/MulleCivetWebRequest+Private.h>

#include <MulleCivetWeb/civetweb.h>
#include <stdlib.h>


@interface MyWebRequestHandler : NSObject <MulleCivetWebRequestHandler>
@end


@implementation MyWebRequestHandler

- (MulleCivetWebResponse *) webServer:(MulleCivetWebServer *) server
             webResponseForWebRequest:(MulleCivetWebRequest *) request
{
   MulleCivetWebTextResponse   *response;
   NSURL                       *url;
   NSString                    *key;
   NSDictionary                *headers;
   NSData                      *contentData;

   response    = [MulleCivetWebTextResponse webResponseForWebRequest:request];
   url         = [request URL];
   contentData = [request contentData];
   [response setDate:[NSDate dateWithTimeIntervalSinceReferenceDate:0]];
   // [response addToTransferEncodings:MulleHTTPTransferEncodingChunked];

   [response appendLine:@"Reply"];

   [response appendLine:@"---------------------"];
   [response appendString:@"URL: "];
   [response appendLine:[url description]];
   [response appendString:@"Content: "];
   [response appendLine:[NSString mulleStringWithData:contentData
                                             encoding:NSUTF8StringEncoding]];

   headers = [request headers];
   for( key in headers)
   {
      [response appendString:@"Header "];
      [response appendString:key];
      [response appendString:@": "];
      [response appendLine:[headers :key]];
   }
   [response appendLine:@"---------------------"];

   return( response);
}


- (void) request:(id) server
{
   MulleCurl       *curl;
   NSDictionary    *headers;
   NSData          *data;

   while( ! [server isReady])
   {
      fprintf( stderr, "waiting for server to become ready...");
      sleep( 1);
   }

   curl = [MulleCurl object];

   headers = @{
                  MulleHTTPContentTypeKey: @"text/plain; charset=utf-8"
//                  MulleHTTPTransferEncodingKey: MulleHTTPTransferEncodingChunked
              };

   [curl setRequestHeaders:headers];
   data = [curl dataWithContentsOfURLString:@"http://localhost:8080/foo"]; // @"https://www.mulle-kybernetik.com/robots.txt"];
   if( ! data)
      printf( "no data\n");
   printf( "%.*s\n", (int) [data length], [data bytes]);
}
@end


static char  *options[] =
{
   "num_threads", "1",
   NULL, NULL
};


int   main( int argc, char *argv[])
{
   MyWebRequestHandler      *handler;
   MulleCivetWebServer      *server;
   MulleCivetWebRequest     *request;
   NSData                   *contentData;
   struct mg_request_info   info;
   int                      rval;
   NSDictionary             *headers;
   NSThread                 *thread;

   handler = [MyWebRequestHandler object];
   server  = [[[MulleCivetWebServer alloc] initWithCStringOptions:options] autorelease];
   [server setRequestHandler:handler];

   fprintf( stderr, "%s\n", [[server openPortInfos] cStringDescription]);

   //
   // "abuse" handler to also send the request via curl and http
   // to server ...
   //
   thread = [[[NSThread alloc] initWithTarget:handler
                                     selector:@selector( request:)
                                       object:server] autorelease];
   //
   // need to wait for the server to be ready though...
   //
   fprintf( stderr, "starting curl...\n");
   [thread mulleStartUndetached];
   fprintf( stderr, "waiting for curl to finish...\n");
   [thread mulleJoin];
   fprintf( stderr, "done\n");

   // if we use the pedantic exit, then the server will have worker threads
   // still going. These will have retained the universe, so we will wait
   // indefinetely

   [server mullePerformFinalize];
   return( 0);
}
