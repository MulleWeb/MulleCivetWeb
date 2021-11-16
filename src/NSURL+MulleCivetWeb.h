#import "import.h"


@interface NSURL( MulleCivetWeb)

- (instancetype) mulleInitHTTPWithEscapedURIUTF8Characters:(char *) uri
                                                    length:(NSUInteger) uri_len
                                escapedQueryUTF8Characters:(char *) query
                                                    length:(NSUInteger) query_len
                                                      host:(char *) host
                                                     isSSL:(BOOL) isSSL;
                                                     
@end
