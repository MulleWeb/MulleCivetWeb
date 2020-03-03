struct mg_connection;


@interface MulleCivetWebResponse( Private)

// designated initializer
- (instancetype) initWithHTTPVersion:(NSString *) s
                          connection:(struct mg_connection *) connection;

- (struct mg_connection *) connection;

@end
