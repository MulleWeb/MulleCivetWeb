#import <MulleCivetWeb/MulleCivetWeb.h>
#import <MulleCurl/MulleCurl.h>
#import <MulleCivetWeb/MulleCivetWebRequest+Private.h>

#include <MulleCivetWeb/civetweb.h>
#include <stdlib.h>
#include <unistd.h>


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

   url         = [request URL];
   contentData = [request contentData];

   response    = [MulleCivetWebTextResponse webResponseForWebRequest:request];
   [response setDate:[NSDate dateWithTimeIntervalSinceReferenceDate:0]];
   [response addToTransferEncodings:MulleHTTPTransferEncodingChunked];

   if( [request method] == MulleHTTPHead)
      return( response);

   [response sendHeaderData];

   [response appendLine:@"Reply"];

   [response appendLine:@"---------------------"];
   [response appendString:@"URL: "];
   [response appendLine:[url description]];
   [response appendString:@"Content: "];
   [response appendLine:[NSString mulleStringWithData:contentData
                                             encoding:NSUTF8StringEncoding]];

   [response sendChunkedContentData];

   headers = [request headers];
   for( key in headers)
   {
      [response appendString:@"Header "];
      [response appendString:key];
      [response appendString:@": "];
      [response appendLine:[headers :key]];
   }
   [response appendLine:@"---------------------"];

   [response sendChunkedContentData];

   // send a trailing nil ?
   [response sendChunkedContentData];

   return( nil);
}



- (BOOL) curl:(MulleCurl *) curl
   parseBytes:(void *) bytes
       length:(NSUInteger) length
 {
   printf( "%.*s\n", (int) length, bytes);
   return( YES);  // always happy
}


- (id) parsedObjectWithCurl:(MulleCurl *) curl
{
   return( nil);
}



- (void) request:(id) server
{
   MulleCurl        *curl;
   NSDictionary     *headers;
   NSData           *data;
   NSData           *postData;
   NSString         *encoded;
   NSCharacterSet   *characterSet;

   while( server && ! [server isReady])
   {
      fprintf( stderr, "waiting for server to become ready...");
      sleep( 1);
   }

   [MulleCurl setDefaultUserAgent:@"test"];
   curl = [MulleCurl object];

   // means that data should be stringEscaped
   headers = @{
                  MulleHTTPContentTypeKey: @"application/x-www-form-urlencoded",
                  MulleHTTPAcceptEncodingKey: MulleHTTPTransferEncodingChunked
              };

   [curl setRequestHeaders:headers];

   // lets be super pedantic and use x-www-form-urlencoded
   characterSet = [NSCharacterSet mulleURLAllowedCharacterSet];
   encoded      = [@"VfL Bochum 1848" stringByAddingPercentEncodingWithAllowedCharacters:characterSet];
   postData     = [NSData dataWithBytes:[encoded UTF8String]
                                 length:[encoded mulleUTF8StringLength]];

   [curl setParser:self];
   [curl parseContentsOfURLWithString:@"http://localhost:8080/foo"
                        byPostingData:postData];
//  data = [curl dataWithContentsOfURLWithString:@"http://localhost:8080/foo"
//                                 byPostingData:postData]; // @"https://www.mulle-kybernetik.com/robots.txt"];
//  if( ! data)
//     printf( "no data\n");
//  printf( "%.*s\n", (int) [data length], [data bytes]);
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
         fprintf( stderr, "CTRL-C to exit\n");
         for(;;)
         {
            sleep( 100);
         }
      }
   }

   //
   // chance to try with curl from the outside
   // interestingly, Sublime Text broadcasts changes to files via :8080
   // so you may get some stray requests :)
   //

   if( mode == 'c' || mode == 'b')
   {
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
      [thread mulleStart];
      fprintf( stderr, "waiting for curl to finish...\n");
      [thread mulleJoin];
      fprintf( stderr, "done\n");

      // if we use the pedantic exit, then the server will have worker threads
      // still going. These will have retained the universe, so we will wait
      // indefinetely
   }

   [server mullePerformFinalize];

   return( 0);
}
