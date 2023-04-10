
struct mg_connection;
struct mg_request_info;
@class MulleCivetWebServer;
@class NSDictionary;
@class NSData;


@interface MulleCivetWebRequest( Private)


//
// this is a way to create "fake" requests for testing
//
+ (instancetype) webRequestWithServer:(MulleCivetWebServer *) server
                                  URL:(id) url
                              headers:(NSDictionary *) headers
                          contentData:(NSData *) data;

- (instancetype) initWithConnection:(void *) conn;

// can be useful for testing
- (instancetype) initWithRequestInfo:(struct mg_request_info *) info;

- (void *) connection;

@end
