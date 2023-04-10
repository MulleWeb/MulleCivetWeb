@interface MulleCivetWebResponse( Private)

// designated initializer
- (instancetype) initWithHTTPVersion:(NSString *) s
                          connection:(void *) connection;

- (void *) connection;

@end
