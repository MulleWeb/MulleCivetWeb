
struct mg_request_info;


@interface MulleCivetWebRequest( Private)

- (id) initWithRequestInfo:(struct mg_request_info *) info;
@end
