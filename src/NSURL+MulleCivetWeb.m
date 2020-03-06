#import "NSURL+MulleCivetWeb.h"

#import "import-private.h"


@implementation NSURL( MulleCivetWeb)

- (instancetype) mulleInitHTTPWithEscapedURIUTF8Characters:(mulle_utf8_t *) uri
                                                    length:(NSUInteger) uri_len
                                                     host:(char *) host
                                                     isSSL:(BOOL) isSSL
{
   NSString  *s;
   NSCharacterSet   *characterSet;

   _scheme = [(isSSL ? @"http" : @"https") copy];
   if( host && *host)
   {
      s            = [[[NSString alloc] initWithUTF8String:host] autorelease];
      characterSet = [NSCharacterSet URLHostAllowedCharacterSet];
      s            = [s stringByAddingPercentEncodingWithAllowedCharacters:characterSet];
      _escapedHost = [s copy];
   }
   return( [self mulleInitResourceSpecifierWithUTF8Characters:uri
                                                       length:uri_len]);
}

@end
