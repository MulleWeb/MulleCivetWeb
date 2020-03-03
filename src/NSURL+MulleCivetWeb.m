#import "NSURL+MulleCivetWeb.h"

#import "import-private.h"


@implementation NSURL( MulleCivetWeb)

- (instancetype) mulleInitHTTPWithEscapedURIUTF8Characters:(mulle_utf8_t *) uri
                                                    length:(NSUInteger) uri_len
                                                     isSSL:(BOOL) isSSL
{
   _scheme = [(isSSL ? @"http" : @"https") copy];
   return( [self mulleInitResourceSpecifierWithUTF8Characters:uri
                                                       length:uri_len]);
}

@end
