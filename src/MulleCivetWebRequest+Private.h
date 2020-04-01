
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

- (instancetype) initWithConnection:(struct mg_connection *) conn;

// can be useful for testing
- (instancetype) initWithRequestInfo:(struct mg_request_info *) info;

- (struct mg_connection *) connection;

@end
