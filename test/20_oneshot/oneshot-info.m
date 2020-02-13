#import <MulleCivetWeb/MulleCivetWeb.h>
#import <MulleCivetWeb/private/MulleCivetWebRequest+Private.h>

#include <MulleCivetWeb/civetweb.h>


@interface TestWebServer : MulleCivetWebServer <MulleCivetWebRequestHandler>
@end


@implementation TestWebServer

- (void) writeWebResponse:(id <MulleCivetWebResponse>) response
               onlyHeader:(BOOL) onlyHeader
{
   NSData   *headerData;
   NSData   *contentData;

   headerData = [response headerDataUsingEncoding:NSUTF8StringEncoding];
   printf( "%.*s", (int) [headerData length], [headerData bytes]);
   if( onlyHeader)
      return;

   contentData = [response contentData];
   printf( "%.*s", (int) [contentData length], [contentData bytes]);
}


- (MulleCivetWebResponse *) webResponseForWebRequest:(MulleCivetWebRequest *) request
{
   MulleCivetWebTextResponse  *response;
   NSURL                      *url;
   NSString                   *key;
   NSDictionary               *headers;

   response = [MulleCivetWebTextResponse webResponseForWebRequest:request];
   url      = [request URL];
   [response setDate:[NSDate dateWithTimeIntervalSinceReferenceDate:0]];

   [response appendLine:@"Reply"];
   [response appendLine:@"---------------------"];
   [response appendString:@"URL: "];
   [response appendLine:[url description]];

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
   TestWebServer              *server;
   MulleCivetWebRequest       *request;
   struct mg_request_info     info;
   int                        rval;

   server = [TestWebServer object];
   [server setRequestHandler:server];

   // fake a request manually
   memset( &info, 0, sizeof( info));
   info.request_method = "GET";
   info.local_uri      = "/foo";
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
}
