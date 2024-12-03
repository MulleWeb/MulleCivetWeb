#import <MulleCivetWeb/MulleCivetWeb.h>
#import <MulleCurl/MulleCurl.h>
#import <MulleCivetWeb/MulleCivetWebRequest+Private.h>

#include <MulleCivetWeb/civetweb.h>
#include <stdlib.h>
#include <unistd.h>


// Sublime Text broadcasts changes to files via :8080 so you may get
// some stray requests, if you use that port :)

static NSString   *URL = @"http://localhost:51293/foo";

static char  *options[] =
{
   "num_threads", "1",
   "listening_ports", "51293", // random ...
   NULL, NULL
};




@interface MyWebRequestHandler : MulleObject <MulleCivetWebRequestHandler,
                                              MulleAutolockingObjectProtocols,
                                              MulleCurlParser>
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

   mulle_fprintf( stderr, "composing response for request...\n");

   url         = [request URL];
   contentData = [request contentData];

   response    = [MulleCivetWebTextResponse webResponseForWebRequest:request];
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

@end


@interface MyWebRequestser : MulleObject <MulleCivetWebRequestHandler,
                                              MulleAutolockingObjectProtocols,
                                              MulleCurlParser>
@end


static int    sendRequest( NSThread *thread, id server)
{
   MulleCurl             *curl;
   NSDictionary          *headers;
   NSData                *data;
   NSData                *postData;
   NSString              *encoded;
   NSCharacterSet        *characterSet;

   while( server && ! [server isReady])
   {
      mulle_fprintf( stderr, "waiting for server to become ready...");
      sleep( 1);
   }

   mulle_fprintf( stderr, "sending request via curl...\n");

   [MulleCurl setDefaultUserAgent:@"test"];
   curl = [MulleCurl object];

   // means that data should be stringEscaped
   headers = @{
                  MulleHTTPContentTypeKey: @"application/x-www-form-urlencoded"
              };

   [curl setRequestHeaders:headers];

   // lets be super pedantic and use x-www-form-urlencoded
   characterSet = [NSCharacterSet mulleURLAllowedCharacterSet];
   encoded      = [@"VfL Bochum 1848" stringByAddingPercentEncodingWithAllowedCharacters:characterSet];
   postData     = [NSData dataWithBytes:[encoded UTF8String]
                                 length:[encoded mulleUTF8StringLength]];

   data = [curl dataWithContentsOfURLWithString:URL
                                  byPostingData:postData]; // @"https://www.mulle-kybernetik.com/robots.txt"];
   if( ! data)
      mulle_fprintf( stderr, "no data\n");
   mulle_printf( "%.*s\n", (int) [data length], [data bytes]);

   MulleObjCDumpAutoreleasePoolsToFile( "pooldump-1.csv");
   return( 0);
}


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
   int                      mode;

   server  = nil;
   handler = [MyWebRequestHandler object];

   mode = argc == 2 ? argv[1][0] : 'b';

   if( mode == 's' || mode == 'b')
   {
      server  = [[[MulleCivetWebServer alloc] initWithCStringOptions:options] autorelease];
      [server setRequestHandler:handler];

      fprintf( stderr, "%s\n", [[server openPortInfos] UTF8String]);

      if( mode == 's')
      {
         mulle_fprintf( stderr, "CTRL-C to exit\n");
         for(;;)
         {
            sleep( 100);
         }
      }
   }

   //
   // chance to try with curl from the outside interestingly
   //

   if( mode == 'c' || mode == 'b')
   {

      thread = [[[NSThread alloc] mulleInitWithObjectFunction:sendRequest
                                                      object:server] autorelease];
      //
      // need to wait for the server to be ready though...
      //
      mulle_fprintf( stderr, "starting curl...\n");
      [thread mulleStart];
      mulle_fprintf( stderr, "waiting for curl to finish...\n");
      [thread mulleJoin];
      mulle_fprintf( stderr, "done\n");

      // if we use the pedantic exit, then the server will have worker threads
      // still going. These will have retained the universe, so we will wait
      // indefinetely
   }

   MulleObjCDumpAutoreleasePoolsToFile( "pooldump-2.csv");

   [server mullePerformFinalize];

   MulleObjCDumpAutoreleasePoolsToFile( "pooldump-3.csv");

   return( 0);
}
