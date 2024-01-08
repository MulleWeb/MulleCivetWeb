#import <MulleCivetWeb/MulleCivetWeb.h>
#import <MulleCivetWeb/MulleCivetWebRequest+Private.h>

#include <MulleCivetWeb/civetweb.h>

#include <unistd.h>


@implementation MulleCivetWebResponse ( Test)

- (void) sendHeaderData
{
   NSData   *headerData;

   headerData = [self headerDataUsingEncoding:NSUTF8StringEncoding];
   printf( "%.*s", (int) [headerData length], [headerData bytes]);
}

- (void) sendContentData
{
   NSData   *contentData;

   contentData = [self contentData];
   printf( "%.*s", (int) [contentData length], [contentData bytes]);
}

@end



@interface RequestHandler : NSObject <MulleCivetWebRequestHandler>
@end


@implementation RequestHandler


- (MulleCivetWebResponse *) webServer:(MulleCivetWebServer *) server
             webResponseForWebRequest:(MulleCivetWebRequest *) request
{
   MulleCivetWebTextResponse  *response;
   NSURL                      *url;
   NSString                   *key;
   NSDictionary               *headers;
   NSData                     *contentData;

   response    = [MulleCivetWebTextResponse webResponseForWebRequest:request];
   url         = [request URL];
   contentData = [request contentData];
   [response setDate:[NSDate dateWithTimeIntervalSinceReferenceDate:0]];

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

static char  *options[] =
{
   "num_threads", "1",
   NULL, NULL
};


int   main( int argc, char *argv[])
{
   RequestHandler         *handler;
   MulleCivetWebServer    *server;
   MulleCivetWebRequest   *request;
   NSData                 *contentData;
   int                    rval;

   server  = [[[MulleCivetWebServer alloc] initWithCStringOptions:options] autorelease];
   @autoreleasepool
   {
      handler = [RequestHandler object];
      [server setRequestHandler:handler];

      //
      // chance to try with curl from the outside
      // interestingly, Sublime Text broadcasts changes to files via :8080
      // so you may get some stray requests :)
      //
      if( argc == 2)
      {
         fprintf( stderr, "CTRL-C to exit\n");
         for(;;)
         {
            sleep( 100);
         }
      }

      contentData = [@"VfL Bochum 1848" dataUsingEncoding:NSUTF8StringEncoding];

      request = [MulleCivetWebRequest webRequestWithServer:server
                                                       URL:[NSURL URLWithString:@"/foo"]
                                                   headers:@{
                                                               MulleHTTPContentTypeKey: @"text/plain; charset=utf-8",
                                                               MulleHTTPContentLengthKey: [NSString stringWithFormat:@"%ld", [contentData length]]
                                                            }
                                               contentData:contentData];
      rval = [server handleWebRequest:request];
      printf( "%d\n", rval);
   }
   [server mullePerformFinalize];

   return( 0);
}
