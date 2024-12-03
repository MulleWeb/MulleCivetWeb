#import <MulleCivetWeb/MulleCivetWeb.h>
#import <MulleCivetWeb/MulleCivetWebRequest+Private.h>

#include <MulleCivetWeb/civetweb.h>

#include <unistd.h>


static char  *options[] =
{
   "num_threads", "1",
   "listening_ports", "51295", // random ...
   NULL, NULL
};




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
   NSDictionary               *parameterDict;
   NSDictionary               *queryDict;

   response = [MulleCivetWebTextResponse webResponseForWebRequest:request];
   url      = [request URL];
   [response setDate:[NSDate dateWithTimeIntervalSinceReferenceDate:0]];

   [response appendLine:@"Reply"];
   [response appendLine:@"---------------------"];
   [response appendString:@"URL: "];
   [response appendLine:[url description]];

   parameterDict = [url mulleParameterDictionary];
   for( key in parameterDict)
   {
      [response appendString:@"Parameter :"];
      [response appendString:key];
      [response appendString:@"="];
      [response appendLine:[parameterDict objectForKey:key]];
   }

   queryDict = [url mulleQueryDictionary];
   for( key in queryDict)
   {
      [response appendString:@"Query : "];
      [response appendString:key];
      [response appendString:@"="];
      [response appendLine:[queryDict objectForKey:key]];
   }
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


int   main( int argc, char *argv[])
{
   MulleCivetWebServer        *server;
   RequestHandler             *handler;
   MulleCivetWebRequest       *request;
   struct mg_request_info     info;
   int                        rval;

   server  = [[[MulleCivetWebServer alloc] initWithCStringOptions:options] autorelease];
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

   // fake a request manually
   memset( &info, 0, sizeof( info));
   info.request_method = "GET";
   info.local_uri      = "/foo%20bar;param1;param2=OK";
   info.query_string   = "name=foo%20bar";
   info.http_version   = "1.1";
   info.content_length = -1;
   info.remote_port    = 1848;
   info.user_data      = server;

   info.num_headers    = 2;
   info.http_headers[ 0].name  = "Content-Type";
   info.http_headers[ 0].value = "text/plain; charset=utf-8";
   info.http_headers[ 1].name  = "Content-Length";
   info.http_headers[ 1].value = "-1";

   request = [[[MulleCivetWebRequest alloc] initWithRequestInfo:&info] autorelease];
   rval    = [server handleWebRequest:request];
   printf( "%d\n", rval);

   [server mullePerformFinalize];

   return( 0);
}
