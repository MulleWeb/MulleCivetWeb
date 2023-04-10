#import "NSURL+MulleCivetWeb.h"

#import "import-private.h"


@implementation NSURL( MulleCivetWeb)

- (instancetype) mulleInitHTTPWithEscapedURIUTF8Characters:(char *) uri
                                                    length:(NSUInteger) uri_len
                                escapedQueryUTF8Characters:(char *) query
                                                    length:(NSUInteger) query_len
                                                      host:(char *) host
                                                     isSSL:(BOOL) isSSL
{
   NSString                           *s;
   NSCharacterSet                     *characterSet;
   struct MulleEscapedURLPartsUTF8    parts;
   char                               *parameter;

   memset( &parts, 0, sizeof( parts));

   parts.scheme.characters = (isSSL ? "http" : "https");
   parts.scheme.length     = -1;

   parts.escaped_host.characters = host;
   parts.escaped_host.length     = -1;

   parts.escaped_path.characters = uri;
   parts.escaped_path.length     = uri_len;

   parameter = (char *) mulle_utf8_strnchr( (mulle_utf8_t *) uri, uri_len, ';');
   if( parameter)
   {
      parts.escaped_path.length = parameter - uri;

      parts.escaped_parameter.characters = parameter + 1;
      parts.escaped_parameter.length     = uri_len - (parts.escaped_path.length + 1);
   }

   parts.escaped_query.characters = query;
   parts.escaped_query.length     = query_len;

   return( [self mulleInitWithEscapedURLPartsUTF8:&parts
                           allowedURICharacterSet:nil]);
}

@end
