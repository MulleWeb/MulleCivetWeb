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



int   main( int argc, char *argv[])
{
   TestWebServer              *server;
   MulleCivetWebRequest       *request;
   NSData                     *contentData;
   struct mg_request_info     info;
   int                        rval;

   server = [TestWebServer object];
   [server setRequestHandler:server];

   contentData = [@"VfL Bochum 1848" dataUsingEncoding:NSUTF8StringEncoding];

   request = [MulleCivetWebRequest webRequestWithServer:server
                                                    URL:[NSURL URLWithString:@"/foo"]
                                                headers:@{
                                                            MulleCivetWebContentTypeKey: @"text/plain; charset=utf-8",
                                                            MulleCivetWebContentLengthKey: [NSString stringWithFormat:@"%ld", [contentData length]]
                                                         }
                                            contentData:contentData];


   rval    = [server handleWebRequest:request];
   printf( "%d\n", rval);
}
