# MulleCivetWeb Library Documentation for AI

## 1. Introduction & Purpose

**MulleCivetWeb** is an Objective-C wrapper around the Civetweb HTTP server library, providing a lightweight, embedded web server for MulleFoundation applications. Civetweb is a fast, standards-compliant HTTP 1.1 server with support for both HTTP and HTTPS, query parameters, headers, chunked transfer encoding, and more.

This library is particularly useful for:
- Embedding HTTP APIs directly into applications without external server dependencies
- Building RESTful services in Objective-C
- Creating local admin interfaces or dashboards
- Rapid prototyping of web services
- Single-threaded or multi-threaded request handling

## 2. Key Concepts & Design Philosophy

- **Embedded Server**: Civetweb runs in-process; no external server installation needed
- **Request/Response Pattern**: Clean MulleCivetWebRequest → Handler → MulleCivetWebResponse cycle
- **Handler Protocol**: Implement `MulleCivetWebRequestHandler` protocol for request dispatching
- **Thread-Safe Methods**: Critical methods marked `MULLE_OBJC_THREADSAFE_METHOD` for concurrent access
- **Ephemeral Request Objects**: MulleCivetWebRequest instances are only valid during request/response cycle
- **Configurable Options**: Flexible initialization via Civetweb option strings

## 3. Core API & Data Structures

### 3.1 Server Management: `MulleCivetWebServer`

#### Initialization
- `- (instancetype) initWithCStringOptions:(char **)options`
  - Initialize server with Civetweb options (see 3.4 for common options)
  - Server starts immediately after init
  - **options**: NULL-terminated array of option strings (e.g., `"listening_ports", "8080", NULL`)

#### Server Status
- `- (volatile BOOL) isReady` [THREADSAFE]
  - Check if server is listening and ready to accept connections
  - Returns YES when port binding succeeds

#### Port Information
- `- (NSArray *) openPortInfos`
  - Returns array of NSDictionary containing port information
  - Each dict has keys like "port", "proto" (http/https)
  - Returns nil if information cannot be obtained

#### Option Access
- `- (NSString *) optionForKey:(NSString *)key`
  - Get configured option value as NSString
- `- (char *) optionCStringForKeyCString:(char *)key`
  - Get option value as C string (lower-level)

#### Request Handling Configuration
- `@property (assign) id<NSObject, MulleCivetWebRequestHandler> requestHandler`
  - Set object implementing MulleCivetWebRequestHandler protocol
  - Alternative to subclassing; handler receives all requests

#### Response Methods
- `- (MulleCivetWebResponse *) webResponseForWebRequest:(MulleCivetWebRequest *)request` [THREADSAFE]
  - Primary method for generating responses (override or use requestHandler)
  - Must return a valid MulleCivetWebResponse subclass instance
  
- `- (NSUInteger) handleWebRequest:(MulleCivetWebRequest *)request` [THREADSAFE]
  - Lower-level handler for custom control over response dispatch
  - Returns HTTP status code or NSUInteger error

- `- (MulleCivetWebResponse *) webResponseForError:(NSUInteger)code errorDescription:(NSString *)description forWebRequest:(MulleCivetWebRequest *)request` [THREADSAFE]
  - Generate standard HTTP error responses (404, 500, etc.)
  - **code**: HTTP status code
  - **description**: Error message text

#### Logging
- `- (void) log:(NSString *)format, ...` [THREADSAFE]
  - Server logging (Future interface)

### 3.2 Incoming Request: `MulleCivetWebRequest`

**⚠️ EPHEMERAL**: Valid only during request/response cycle. Do not retain or copy.

#### HTTP Method & Version
- `- (enum MulleHTTPRequestMethod) method`
  - Returns HTTP method (GET, POST, PUT, DELETE, PATCH, HEAD, OPTIONS, TRACE, CONNECT)
- `- (NSString *) HTTPVersion`
  - Returns version string (e.g., "HTTP/1.1")

#### Content Access
- `- (NSData *) contentData`
  - Blocking call: waits for all request body data to arrive
  - Returns complete body as NSData
  
- `- (NSData *) partialContentDataWithCapacity:(NSUInteger)length`
  - Non-blocking streaming read: waits up to `length` bytes (single mg_read call)
  - Data read here won't be available via contentData
  - Returns nil on failure
  
- `- (NSUInteger) contentLength`
  - Content-Length header value (capped at INT_MAX; use partialContentData for larger bodies)

#### HTTP Headers
- `- (NSDictionary *) headers`
  - All request headers as key-value dictionary
- `- (NSString *) headerValueForKey:(NSString *)key`
  - Retrieve single header value by key

#### Client Information
- `- (NSString *) remoteIP`
  - Client IP address
- `- (unsigned int) remotePort`
  - Client port number
- `- (NSString *) remoteUser`
  - Authenticated user (if auth enabled)
- `- (BOOL) isSSL`
  - Whether request arrived via HTTPS

#### URI & Query
- `- (char *) URICString`
  - Request URI as C string (includes path and query)
- `- (char *) queryCString`
  - Query string as C string (after `?`)

#### HTTPS/Security
- `- (void *) clientCertificate`
  - Client SSL certificate (if provided)

#### Low-Level Access
- `- (void *) info`
  - Direct access to `struct mg_request_info` (for C API integration)
- `- (char *) findHeaderValueAsCStringForKeyCString:(char *)key`
  - Fast header lookup with C strings

### 3.3 Outgoing Response: `MulleCivetWebResponse`

#### Properties
- `@property (readonly) BOOL hasSentHeader`
  - True if HTTP header already transmitted
- `@property (readonly) BOOL hasCreatedStream`
  - True if output stream created
- `@property (assign) NSUInteger status`
  - HTTP status code (200, 404, 500, etc.)
- `@property (retain) NSString *statusText`
  - HTTP status text (e.g., "OK", "Not Found")
- `@property (retain) NSData *contentData`
  - Response body (automatically sent when headers sent)
- `@property (retain) NSDate *date`
  - Override Date header (normally auto-set to current time; useful for testing)

#### Creation
- `+ (instancetype) webResponseForWebRequest:(MulleCivetWebRequest *)request`
  - Factory method to create response for request
  - **request** cannot be nil

#### Headers
- `- (void) setHeaderValue:(NSString *)value forKey:(NSString *)key`
  - Set HTTP response header
- `- (NSString *) headerValueForKey:(NSString *)key`
  - Get previously-set header value
- `- (NSData *) headerDataUsingEncoding:(NSStringEncoding)encoding`
  - Serialize headers to NSData (for advanced cases)

#### Sending Response
- `- (BOOL) sendHeaderData`
  - Transmit HTTP header to client
  - Must be called before contentData
  - Returns success/failure

- `- (BOOL) sendContentData`
  - Transmit body (set via contentData property)
  - Call after sendHeaderData

#### Chunked Transfer Encoding
- `- (void) addToTransferEncodings:(NSString *)encoding`
  - Add value to Transfer-Encoding header (e.g., "chunked")
- `- (BOOL) containsTransferEncoding:(NSString *)encoding`
  - Check if transfer encoding already set

- `- (BOOL) sendChunkedContentData`
  - Send body as chunked transfer encoding
  - Clears contentData after send; can fill again for multiple chunks

#### Stream API (Streaming Responses)
- `- (MulleObjCBufferedOutputStream *) createStream`
  - Create output stream for streaming responses
  - Must call sendHeaderData before first write
  - Must add "chunked" to transfer encodings first

- `- (MulleObjCBufferedOutputStream *) createStreamAndSendHeaderData`
  - Convenience: creates stream and sends headers automatically
  - Automatically sets "chunked" transfer encoding

#### Cleanup
- `- (void) clearContentData`
  - Discard accumulated response body data

### 3.4 Request Handler Protocol: `MulleCivetWebRequestHandler`

Implement this protocol to handle requests:

```objc
@protocol MulleCivetWebRequestHandler

// Required: called for each HTTP request
- (MulleCivetWebResponse *) webServer:(MulleCivetWebServer *)server
              webResponseForWebRequest:(MulleCivetWebRequest *)request
                                             MULLE_OBJC_THREADSAFE_METHOD;

// Optional: called if exception thrown during request processing
- (MulleCivetWebResponse *) webServer:(MulleCivetWebServer *)server
               webResponseForException:(NSException *)exception
                      duringWebRequest:(MulleCivetWebRequest *)request
                                             MULLE_OBJC_THREADSAFE_METHOD;

@end
```

### 3.5 Common Civetweb Options (for initWithCStringOptions:)

Pass as NULL-terminated char* array. Common options:

- `"listening_ports"` → `"8080"` - Port to listen on
- `"num_threads"` → `"4"` - Number of request handling threads
- `"enable_directory_listing"` → `"yes"/"no"` - Allow directory browsing
- `"document_root"` → `"/path/to/root"` - Static file directory
- `"ssl_certificate"` → `"/path/to/cert.pem"` - HTTPS certificate
- `"ssl_protocol_version"` → `"3"` - TLS version
- `"authentication_domain"` → `"realm"` - HTTP auth realm
- `"access_log_file"` → `"access.log"` - Log file path

Example:
```c
char *opts[] = {
    "listening_ports", "8080",
    "num_threads", "4",
    NULL
};
```

## 4. Performance Characteristics

- **Request Handling**: O(1) per request (excluding handler logic)
- **Thread Pool**: Configurable via num_threads option; default typically 1-4
- **Memory**: Minimal overhead; Civetweb allocates buffers per request
- **Throughput**: Typical: 1,000-10,000 req/sec depending on handler complexity
- **Latency**: < 1ms server overhead per request (handler logic may dominate)
- **Concurrency**: Safe for multiple threads; use THREADSAFE_METHOD annotations

## 5. AI Usage Recommendations & Patterns

### Pattern 1: Simple HTTP API Server
Subclass MulleCivetWebServer and override webResponseForWebRequest:

```objc
@interface MyServer : MulleCivetWebServer
@end

@implementation MyServer
- (MulleCivetWebResponse *) webResponseForWebRequest:(MulleCivetWebRequest *)request {
    MulleCivetWebResponse *response = [MulleCivetWebResponse webResponseForWebRequest:request];
    
    if ([[request URICString] hasPrefix:"/api/status"]) {
        response.contentData = [@"OK" dataUsingEncoding:NSUTF8StringEncoding];
        response.status = 200;
    }
    
    return response;
}
@end
```

### Pattern 2: Using Request Handler Delegate
Implement protocol without subclassing:

```objc
@interface MyHandler : NSObject <MulleCivetWebRequestHandler>
@end

@implementation MyHandler
- (MulleCivetWebResponse *) webServer:(MulleCivetWebServer *)server
              webResponseForWebRequest:(MulleCivetWebRequest *)request {
    // handle request
    return [MulleCivetWebResponse webResponseForWebRequest:request];
}
@end

// In startup:
MyHandler *handler = [[MyHandler alloc] init];
char *opts[] = {"listening_ports", "8080", NULL};
MulleCivetWebServer *srv = [[MulleCivetWebServer alloc] initWithCStringOptions:opts];
srv.requestHandler = handler;
```

### Pattern 3: Streaming Large Responses
Use stream API for memory-efficient responses:

```objc
MulleCivetWebResponse *response = [MulleCivetWebResponse webResponseForWebRequest:request];
response.status = 200;
response.contentData = nil;

MulleObjCBufferedOutputStream *stream = [response createStreamAndSendHeaderData];

for (int i = 0; i < 1000000; i++) {
    NSString *chunk = [NSString stringWithFormat:@"%d,", i];
    NSData *data = [chunk dataUsingEncoding:NSUTF8StringEncoding];
    [stream write:data];
}

return response;
```

### Pattern 4: RESTful Resource Handler
Pattern for handling different HTTP methods:

```objc
- (MulleCivetWebResponse *) webResponseForWebRequest:(MulleCivetWebRequest *)request {
    MulleCivetWebResponse *response = [MulleCivetWebResponse webResponseForWebRequest:request];
    
    enum MulleHTTPRequestMethod method = [request method];
    NSString *uri = [NSString stringWithCString:[request URICString] encoding:NSUTF8StringEncoding];
    
    if ([uri isEqualToString:@"/api/items"] && method == GET) {
        response.contentData = [self listItemsJSON];
        response.status = 200;
    } else if ([uri hasPrefix:@"/api/items/"] && method == GET) {
        NSString *itemId = [uri substringFromIndex:11];
        response.contentData = [self itemJSONForId:itemId];
        response.status = 200;
    } else if ([uri isEqualToString:@"/api/items"] && method == POST) {
        NSData *body = [request contentData];
        [self createItemFromJSON:body];
        response.status = 201;
    }
    
    return response;
}
```

### Pattern 5: Error Handling with Exception Handler
Gracefully handle unexpected errors:

```objc
@implementation MyServer
- (MulleCivetWebResponse *) webServer:(MulleCivetWebServer *)server
               webResponseForException:(NSException *)exception
                      duringWebRequest:(MulleCivetWebRequest *)request {
    NSLog(@"Exception: %@", exception);
    return [self webResponseForError:500 
                   errorDescription:[exception reason]
                      forWebRequest:request];
}
@end
```

### Common Pitfalls
- **Retaining ephemeral request/response objects**: Always create new responses; don't cache requests
- **Blocking contentData calls**: Slows server; consider streaming for large bodies
- **Not setting status codes**: Default is 200; explicitly set non-2xx codes
- **Forgetting headers before sending**: Set headers before calling sendHeaderData
- **Thread safety**: Only call marked THREADSAFE_METHOD from handler threads; coordinate access to shared state

## 6. Integration Examples

### Example 1: Simple Echo API
```objc
@interface EchoServer : MulleCivetWebServer
@end

@implementation EchoServer
- (MulleCivetWebResponse *) webResponseForWebRequest:(MulleCivetWebRequest *)request {
    MulleCivetWebResponse *response = [MulleCivetWebResponse webResponseForWebRequest:request];
    
    NSData *bodyData = [request contentData];
    response.contentData = [@"Echo: " dataUsingEncoding:NSUTF8StringEncoding];
    [response.contentData appendData:bodyData];
    response.status = 200;
    [response setHeaderValue:@"text/plain" forKey:@"Content-Type"];
    
    return response;
}
@end

// Usage:
char *opts[] = {"listening_ports", "8080", NULL};
EchoServer *server = [[EchoServer alloc] initWithCStringOptions:opts];
// Server listens at http://localhost:8080/
```

### Example 2: JSON API with Query Parameters
```objc
@interface JSONServer : MulleCivetWebServer
@end

@implementation JSONServer
- (MulleCivetWebResponse *) webResponseForWebRequest:(MulleCivetWebRequest *)request {
    MulleCivetWebResponse *response = [MulleCivetWebResponse webResponseForWebRequest:request];
    
    // Parse query string
    NSString *queryStr = [NSString stringWithCString:[request queryCString] encoding:NSUTF8StringEncoding];
    NSDictionary *params = [self parseQueryString:queryStr];
    
    // Generate JSON response
    NSDictionary *result = @{
        @"status": @"success",
        @"params": params ?: @{},
        @"timestamp": @([[NSDate date] timeIntervalSince1970])
    };
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:result options:0 error:nil];
    response.contentData = jsonData;
    response.status = 200;
    [response setHeaderValue:@"application/json; charset=utf-8" forKey:@"Content-Type"];
    
    return response;
}

- (NSDictionary *) parseQueryString:(NSString *)query {
    // Simple parsing (use proper URL query parsing in production)
    // Left as exercise
    return @{};
}
@end
```

### Example 3: Static File Server with Dynamic Routes
```objc
@interface MixedServer : MulleCivetWebServer
@property (retain) NSString *documentRoot;
@end

@implementation MixedServer
- (MulleCivetWebResponse *) webResponseForWebRequest:(MulleCivetWebRequest *)request {
    MulleCivetWebResponse *response = [MulleCivetWebResponse webResponseForWebRequest:request];
    NSString *uri = [NSString stringWithCString:[request URICString] encoding:NSUTF8StringEncoding];
    
    // Handle dynamic APIs
    if ([uri hasPrefix:@"/api/"]) {
        NSString *action = [uri substringFromIndex:5];
        if ([action isEqualToString:@"version"]) {
            response.contentData = [@"1.0.0" dataUsingEncoding:NSUTF8StringEncoding];
            response.status = 200;
        } else {
            response.status = 404;
        }
        return response;
    }
    
    // Serve static files
    NSString *filePath = [self.documentRoot stringByAppendingString:uri];
    NSData *fileData = [NSData dataWithContentsOfFile:filePath];
    if (fileData) {
        response.contentData = fileData;
        response.status = 200;
        // Set content-type based on extension...
    } else {
        response.status = 404;
    }
    
    return response;
}
@end
```

### Example 4: Multi-threaded Request Handling
```objc
char *opts[] = {
    "listening_ports", "8080",
    "num_threads", "8",  // 8 worker threads
    NULL
};

MulleCivetWebServer *server = [[MulleCivetWebServer alloc] initWithCStringOptions:opts];

if (![server isReady]) {
    fprintf(stderr, "Failed to start server\n");
} else {
    printf("Server ready. Open port info: %s\n", [[server openPortInfos] UTF8String]);
    
    // Server handles up to 8 concurrent requests
    // Run event loop or sleep...
    while (1) sleep(1);
}
```

### Example 5: Streaming CSV Download
```objc
@interface CSVServer : MulleCivetWebServer
- (NSArray *) generateLargeDataset;
@end

@implementation CSVServer
- (MulleCivetWebResponse *) webResponseForWebRequest:(MulleCivetWebRequest *)request {
    MulleCivetWebResponse *response = [MulleCivetWebResponse webResponseForWebRequest:request];
    response.status = 200;
    
    [response setHeaderValue:@"text/csv; charset=utf-8" forKey:@"Content-Type"];
    [response setHeaderValue:@"attachment; filename=\"data.csv\"" forKey:@"Content-Disposition"];
    [response addToTransferEncodings:@"chunked"];
    
    MulleObjCBufferedOutputStream *stream = [response createStreamAndSendHeaderData];
    
    // Send CSV header
    NSString *header = @"ID,Name,Value\n";
    [stream write:[header dataUsingEncoding:NSUTF8StringEncoding]];
    
    // Stream large dataset
    for (NSUInteger i = 0; i < 1000000; i++) {
        NSString *line = [NSString stringWithFormat:@"%lu,Item%lu,%.2f\n", i, i, rand() % 100000 / 100.0];
        [stream write:[line dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    return response;
}
@end
```

## 7. Dependencies

- **MulleFoundation** - NSString, NSData, NSDictionary, exception handling
- **civetweb** - Embedded HTTP server library (C) - vendored, no external dependency
- **mulle-objc** (runtime) - Objective-C runtime support
- **Standard C library**

## 8. Version Information

MulleCivetWeb version macro: `MULLE_CIVETWEB_VERSION`
- Format: `(major << 20) | (minor << 8) | patch`
- Reflects both MulleCivetWeb wrapper and bundled Civetweb versions
- No unbounded allocations in normal operation
- Follows mulle-objc conventions for efficiency

## 5. AI Usage Recommendations & Patterns

### Best Practices

- Use factory methods for object creation
- Follow mulle-objc reference counting (retain/release/autorelease)
- Prefer immutable variants when available
- Check return values for error conditions

### Common Pitfalls

- Don't bypass public APIs; use documented interfaces
- Remember to release retained objects
- Validate input parameters when appropriate
- Check for nil returns from factory methods

### Integration Pattern

```objc
// Typical usage pattern
id obj = [[ClassName alloc] initWithParameter:value];
// Use obj...
[obj release];
```

## 6. Integration Examples

See test directory for practical compilable examples:
- `test/` directory contains usage demonstrations
- Examples show initialization, usage, and cleanup patterns
- Test assertions illustrate expected behavior

## 7. Dependencies

- MulleObjC (core runtime)
- MulleFoundationBase
- MulleObjCStandardFoundation and related components
- See project .mulle/etc/sourcetree/config for exact dependencies
