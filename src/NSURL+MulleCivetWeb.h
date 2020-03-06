#import "import.h"


@interface NSURL( MulleCivetWeb)

- (instancetype) mulleInitHTTPWithEscapedURIUTF8Characters:(mulle_utf8_t *) uri
                                                    length:(NSUInteger) uri_len
                                                      host:(char *) host
                                                     isSSL:(BOOL) isSSL;
@end
