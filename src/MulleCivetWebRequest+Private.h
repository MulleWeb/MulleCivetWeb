
struct mg_connection;
struct mg_request_info;

@interface MulleCivetWebRequest( Private)

- (instancetype) initWithConnection:(struct mg_connection *) conn;

// useful for testing
- (instancetype) initWithRequestInfo:(struct mg_request_info *) info;

//
// this is a way to create "fake" requests for testing
//
+ (instancetype) webRequestWithServer:(MulleCivetWebServer *) server
                                  URL:(NSURL *) url
                              headers:(NSDictionary *) headers
                          contentData:(NSData *) data;

@end
