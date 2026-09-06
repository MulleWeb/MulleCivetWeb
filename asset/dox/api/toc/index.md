# MulleCivetWeb Library Documentation for AI
<!-- Keywords: http, server, request, response, handler, streaming, url -->
## 1. Introduction & Purpose

**MulleCivetWeb** is a "WebServer as a library" for mulle-objc. It is an
Objective-C wrapper around the embedded [civetweb](//github.com/civetweb/civetweb)
HTTP 1.1 server. The server runs in-process: as soon as a
`MulleCivetWebServer` is initialized it starts listening on the configured
ports and dispatches every incoming request to a
`MulleCivetWebRequestHandler` (or to a subclass overriding
`webResponseForWebRequest:`).

Key high-level features:

- Embedded, dependency-free HTTP(S) serving with no external server process.
- Request/response cycle fully wrapped in Objective-C classes
  (`MulleCivetWebRequest`, `MulleCivetWebResponse`).
- A `MulleCivetWebTextResponse` convenience subclass for plain text, JSON,
  HTML and similar payloads.
- Chunked transfer-encoding support and a streaming output interface based
  on `MulleObjCBufferedOutputStream`.
- URL handling integrated with `NSURL`: requests expose an `NSURL`, query
  strings can be turned into `NSDictionary` and back.
- Multi-threaded request handling with explicit
  `MULLE_OBJC_THREADSAFE_METHOD` contract points.

It is a component of the MulleWeb universe and depends on
`MulleObjCHTTPFoundation` (HTTP enums, header keys, status text) and
`MulleFoundation`. It vendors `civetweb` (a fork of Mongoose) as a
no-build, no-link source dependency.

## 2. Key Concepts & Design Philosophy

- **Embedded server:** `mg_start` is called during
  `initWithCStringOptions:`. The server is live immediately; there is no
  separate "start" call. All civetweb `mg_*` C functions are resolved inside
  the library, so application code never touches civetweb except for the
  `struct mg_request_info` and `struct mg_connection` pointers exposed by the
  request/response objects.
- **Request → Handler → Response cycle:** civetweb worker threads call
  `handleWebRequest:` on the server. If a `requestHandler` was assigned, it is
  consulted first; otherwise the server calls its own
  `webResponseForWebRequest:` (which is meant to be overridden). Exceptions
  raised while handling a request are caught and routed to the optional
  `webResponseForException:` protocol method.
- **Ephemeral request/response objects:** Both `MulleCivetWebRequest` and
  `MulleCivetWebResponse` are only valid during the request/response cycle.
  They are created by the server, must not be copied and must not be
  retained. Requests live on a civetweb worker thread and are affine to it,
  so they are not thread-safe and do not need to be.
- **No autolocking by design:** the server deliberately does not take a lock
  in the request path ("We can't make this autolocking, as multiple threads
  from mongoose/civetweb would block each other"). If a handler needs shared
  state, it should implement `MulleAutolockingObjectProtocols` (as the
  examples in `test/` do).
- **Threads:** civetweb spawns its own worker threads. The library registers
  them with the mulle-objc universe (`init_thread`/`exit_thread` callbacks)
  and pushes/pops an `@autoreleasepool` per request. `MULLE_OBJC_PEDANTIC_EXIT`
  therefore requires calling `[server mullePerformFinalize]` so the worker
  threads release the universe before exit.
- **Streaming:** responses implement `MulleObjCOutputStream`; a
  `MulleObjCBufferedOutputStream` can be created on them for incremental
  chunked output, avoiding the need to assemble the whole body in memory.

## 3. Core API & Data Structures

All signatures below are copied verbatim from the public headers in `src/`.

### 3.1. `MulleCivetWeb.h` — version numbers

```c
#define MULLE_CIVET_WEB_VERSION  ((0UL << 20) | (17 << 8) | 18)

static inline unsigned int   MulleCivetWeb_get_version_major( void)
static inline unsigned int   MulleCivetWeb_get_version_minor( void)
static inline unsigned int   MulleCivetWeb_get_version_patch( void)
extern uint32_t   MulleCivetWeb_get_version( void);
```

- Version is packed `(major << 20) | (minor << 8) | patch`, currently 0.17.18.
- `MulleCivetWeb_get_version()` is the runtime callable counterpart of the
  macro; the `_major/_minor/_patch` accessors unpack it.
- This header also `#import`s every other public header, so
  `#import <MulleCivetWeb/MulleCivetWeb.h>` pulls in the whole public API.

### 3.2. `MulleCivetWebServer.h`

#### `@protocol MulleCivetWebRequestHandler`

The extension point for handling requests. Implement it and assign the object
via the `requestHandler` property; or subclass `MulleCivetWebServer` and
override `webResponseForWebRequest:`.

```objc
@protocol MulleCivetWebRequestHandler

// required, called for every request
- (MulleCivetWebResponse *) webServer:(MulleCivetWebServer *) server
             webResponseForWebRequest:(MulleCivetWebRequest *) request
                                            MULLE_OBJC_THREADSAFE_METHOD;

 @optional
// called if an exception is raised while `webResponseForWebRequest:`
// was running; lets the handler produce a custom error response
- (MulleCivetWebResponse *) webServer:(MulleCivetWebServer *) server
              webResponseForException:(NSException *) exception
                     duringWebRequest:(MulleCivetWebRequest *) request
                                            MULLE_OBJC_THREADSAFE_METHOD;

@end
```

- The required method must return a `MulleCivetWebResponse` subclass, or
  `nil` if the handler already transmitted the response itself (e.g. via
  chunked streaming). A `nil` return makes the server assume 200.
- Both are `MULLE_OBJC_THREADSAFE_METHOD` because civetweb may invoke them
  concurrently on different worker threads.

#### `@interface MulleCivetWebServer : MulleObject`

Instance fields (private, do not touch): `void *_ctx;`
`char _server_name[256];` `char _isReady;`.

```objc
@property( assign) id <NSObject, MulleCivetWebRequestHandler>   requestHandler;
- (instancetype) initWithCStringOptions:(char **) options;
- (volatile BOOL) isReady  MULLE_OBJC_THREADSAFE_METHOD;
- (MulleCivetWebResponse *) webResponseForWebRequest:(MulleCivetWebRequest *) request MULLE_OBJC_THREADSAFE_METHOD;
- (NSUInteger) handleWebRequest:(MulleCivetWebRequest *) request  MULLE_OBJC_THREADSAFE_METHOD;
- (NSArray *) openPortInfos;
- (NSString *) optionForKey:(NSString *) key;
- (char *) optionCStringForKeyCString:(char *) key;
- (MulleCivetWebResponse *) webResponseForError:(NSUInteger) code
                               errorDescription:(NSString *) errorDescription
                                  forWebRequest:(MulleCivetWebRequest *) request
                                  MULLE_OBJC_THREADSAFE_METHOD;
```

- **Lifecycle:** `initWithCStringOptions:` receives a NULL-terminated array
  of Civetweb option strings (e.g. `"listening_ports"`, `"8080"`, NULL, NULL
  — note the tests append a trailing `NULL, NULL`) and immediately starts the
  server via `mg_start`. Returns `nil` (after releasing itself) if
  `mg_start` fails. There is also a plain `init` (no options). The server
  stops listening in `finalize`. Shut the server down with
  `[server mullePerformFinalize]`.
- `isReady`: `YES` once the main accept thread is running (poll this before
  connecting from a client thread).
- `openPortInfos`: `NSArray` of `NSDictionary` per listening port, or `nil`.
  Keys: `"port"` (NSNumber), `"isSSL"`, `"isRedirect"` (BOOL), `"protocol"`
  (`"IPv4"`, `"IPV6"` or `"???"`).
- `optionForKey:` / `optionCStringForKeyCString:`: look up a running option
  value (wraps `mg_get_option`). The NSString form returns `nil` for
  unset options.
- `handleWebRequest:`: the dispatch entry point. If `requestHandler` is set,
  delegates to it (a `nil` response yields 200); otherwise calls
  `webResponseForWebRequest:`. Exceptions are caught and routed to
  `webResponseForException:`. Then it sends the header, sends content unless
  the method was `MulleHTTPHead`, and returns the response status code.
- `webResponseForError:`: handy factory for standard HTTP errors (404, 500,
  ...) producing a text response with the given description and status.
- Default `webResponseForWebRequest:` returns a 404 "Nothing here".

```objc
@interface MulleCivetWebServer(Future) < MulleObjCFuture>
- (void) log:(NSString *) format, ...     MULLE_OBJC_THREADSAFE_METHOD;
@end
```

`log:` feeds civetweb log messages to a server-side logging hook (used by the
`log_message` callback); it is a MulleObjCFuture-conforming interface.

### 3.3. `MulleCivetWebRequest.h`

**EPHEMERAL INSTANCES, ONLY VALID IN SCOPE. DON'T COPY OR RETAIN.** Created
by the server per request; do not create one yourself (except the private
test helper below). All accessors read from the underlying
`struct mg_request_info`.

```objc
- (enum MulleHTTPRequestMethod) method;
- (NSString *) HTTPVersion;
- (NSString *) remoteUser;
- (NSString *) remoteIP;
- (NSData *) contentData;
- (NSData *) partialContentDataWithCapacity:(NSUInteger) length;
- (NSUInteger) contentLength;
- (NSDictionary *) headers;
- (NSString *) headerValueForKey:(NSString *) key;
- (char *) URICString;
- (char *) queryCString;
- (void *) info;
- (unsigned int) remotePort;
- (BOOL) isSSL;
- (void *) clientCertificate;
- (char *) findHeaderValueAsCStringForKeyCString:(char *) key;
```

- **`method`:** `enum MulleHTTPRequestMethod` — resolves GET, HEAD, POST,
  PUT, DELETE; everything else (OPTIONS, TRACE, CONNECT, PATCH) maps to
  `MulleHTTPOther`.
- **`contentData`:** blocking — reads until the whole body arrived
  (`Content-Length`, respectably capped at `INT_MAX`); `nil` if the read
  fails or the length is `> INT_MAX`. For streaming reads use
  `partialContentDataWithCapacity:`, which does a single `mg_read` of up to
  `length` bytes and is **not** re-read: bytes consumed there will not appear
  in `contentData` later.
- **`contentLength`:** the `Content-Length` value, or `(NSUInteger)-1` when
  the request has no length.
- **`headers`:** lazily built `NSDictionary` (name → value), `nil` if the
  request carries no headers. `headerValueForKey:` is a convenience wrapper.
- **`URICString` / `queryCString`:** raw, escaped URI (from `local_uri`) and
  query string, as C strings. `findHeaderValueAsCStringForKeyCString:` is the
  fast C-level header lookup used internally.
- **Client info:** `remoteIP`, `remotePort`, `remoteUser` (authenticated
  user, may be empty), `isSSL`, `clientCertificate` (raw cert pointer).
- **`HTTPVersion`:** version string such as `"1.1"` (no `HTTP/` prefix).
- **`info`:** the raw `struct mg_request_info *` for C-level integration.

#### `MulleCivetWebRequest+NSURL.h` extension

```objc
@interface MulleCivetWebRequest( NSURL)
- (NSURL *) URL;
@end
```

- `URL:` builds (and caches) the request `NSURL` from the raw escaped URI,
  query, `Host` header and SSL flag. Returns `nil` (and sets `errno`) if the
  URI is missing (`EINVAL`), unreasonably long (`EFBIG`) or unparseable
  (`EFAULT`). A `nil` here is the cue to answer 414.

#### `MulleCivetWebRequest+Private.h` (private)

```objc
+ (instancetype) webRequestWithServer:(MulleCivetWebServer *) server
                                  URL:(id) url
                              headers:(NSDictionary *) headers
                          contentData:(NSData *) data;
- (instancetype) initWithConnection:(void *) conn;
- (instancetype) initWithRequestInfo:(struct mg_request_info *) info;
- (void *) connection;
```

- `webRequestWithServer:` builds a fake in-memory request (GET, HTTP/1.1)
  from an URL, headers dict and content data — this is how `test/` exercises
  a server without a live socket (see `test/20_oneshot/oneshot.m`).
- `connection:` returns the `struct mg_connection *`.

### 3.4. `MulleCivetWebResponse.h`

Abstract class — use a subclass that implements `contentData`
(e.g. `MulleCivetWebTextResponse`). It wraps the connection and sends
headers/body back to the client. **You cannot copy or retain it**: the
`_connection` is gone once the response is through. Default header values:
`Date: <now>` and `Content-Type: text/plain; charset=utf-8`; default status
is 200 "OK". Implements `MulleObjCOutputStream`.

```objc
@property( readonly) BOOL      hasSentHeader;
@property( readonly) BOOL      hasCreatedStream;
@property( assign) NSUInteger  status;
@property( retain) NSString    *statusText;
@property( retain) NSData      *contentData;
@property( retain) NSDate      *date;  // useful for testing (usually nil)

+ (instancetype) webResponseForWebRequest:(MulleCivetWebRequest *) request;

- (void) setHeaderValue:(NSString *) value
                 forKey:(NSString *) key;
- (NSString *) headerValueForKey:(NSString *) key;

- (BOOL) sendHeaderData;
- (BOOL) sendContentData;
- (BOOL) sendChunkedContentData;

- (NSData *) headerDataUsingEncoding:(NSStringEncoding) encoding;

- (void) addToTransferEncodings:(NSString *) s;
- (BOOL) containsTransferEncoding:(NSString *) s;

- (void) clearContentData;

- (MulleObjCBufferedOutputStream *) createStream;
- (MulleObjCBufferedOutputStream *) createStreamAndSendHeaderData;
```

- **Factory:** `+webResponseForWebRequest:` is the way to create a response;
  `request` must not be `nil`. Subclassing requires overriding the
  designated initializer `initWithHTTPVersion:` `connection:` from
  `MulleCivetWebResponse+Private.h`.
- **Properties:** `status` (assign, e.g. 200/404/500) and `statusText`
  ("OK", ...) build the status line; `date` overrides the `Date` header
  (tests set it to a fixed date). `contentData` is the body. `hasSentHeader`
  / `hasCreatedStream` guard the send/stream state.
- **Headers:** `setHeaderValue:` for `forKey:` records header order for
  output (asserts the key has no trailing `:`). `headerDataUsingEncoding:`
  serializes the header block — it always emits `Date`, `Content-Type`
  (defaulted as above) and, when no `Transfer-Encoding: chunked` is set, a
  computed `Content-Length` (this forces `contentData` evaluation).
- **Sending:** `sendHeaderData` first (asserts `! hasSentHeader`), then
  `sendContentData`. `sendChunkedContentData` sends the current `contentData`
  as one chunk and clears it, so you can append and send repeatedly — but only
  after `addToTransferEncodings:MulleHTTPTransferEncodingChunked` was set
  *before* the header went out. All send methods return `BOOL` success.
- **Transfer encodings:** `addToTransferEncodings:` merges into a
  comma-separated `Transfer-Encoding` list; `containsTransferEncoding:`
  checks membership.
- **Streaming:** `createStream` returns a `MulleObjCBufferedOutputStream`
  (1200 byte buffer) over the response; you must have sent the header and set
  `chunked` first, and must not create multiple streams.
  `createStreamAndSendHeaderData` adds `chunked`, sends the header and creates
  the stream for you.
- **Failure semantics:** if a write to a disconnected client fails, the
  internal sink NULLs the connection and raises an
  `NSInternalInconsistencyException` ("remote client shut down ?"). The
  stream subclass here swallows that exception during finalization so pool
  drain during teardown does not `abort()`.

#### `MulleCivetWebResponse+Private.h` (private)

```objc
@interface MulleCivetWebResponse( Private)
- (instancetype) initWithHTTPVersion:(NSString *) s
                          connection:(void *) connection;
- (void *) connection;
@end
```

The designated initializer (fails/returns `nil` if `connection` is NULL) and
raw connection accessor, used by the factory and by server internals.

### 3.5. `MulleCivetWebTextResponse.h`

Concrete subclass of `MulleCivetWebResponse` for text output (HTML, TXT,
JSON, ...). Default content type is `text/plain`. Accumulates content in an
`NSMutableString` and converts it on demand.

```objc
@property( assign) NSStringEncoding   encoding;

- (void) appendString:(NSString *) s;
- (void) appendLine:(NSString *) s;  // adds CR/LF
- (void) appendFormat:(NSString *) format, ...;
```

- `appendString:` / `appendLine:` / `appendFormat:` build the body
  incrementally (vararg `appendFormat:` uses mulle varargs).
- `encoding` (default `NSUTF8StringEncoding`) selects the bytes produced for
  `contentData`. `clearContentData` also empties the accumulated text.

### 3.6. URL helpers

#### `NSURL+MulleCivetWeb.h`

```objc
@interface NSURL( MulleCivetWeb)
- (instancetype) mulleInitHTTPWithEscapedURIUTF8Characters:(char *) uri
                                                    length:(NSUInteger) uri_len
                                escapedQueryUTF8Characters:(char *) query
                                                    length:(NSUInteger) query_len
                                                      host:(char *) host
                                                     isSSL:(BOOL) isSSL;
@end
```

Low-level URI initializer used by `[request URL]`; splits `;` parameters from
the escaped path and feeds `mulleInitWithEscapedURLPartsUTF8:`.

#### `NSURL+NSDictionary.h` — percent-encoding round trips

```objc
@interface NSURL( NSDictionary)
- (NSDictionary *) mulleQueryDictionary;
- (NSDictionary *) mulleParameterDictionary;
@end

@interface NSString( NSDictionaryPercentEncodedParser)
- (NSDictionary *) mulleDictionaryByRemovingPercentEncodingWithLineSeparator:(NSString *) lineSep
                                                           keyValueSeparator:(NSString *) kvSep;
@end

@interface NSDictionary( NSDictionaryPercentEncodedPrinter)
- (NSString *) mulleURLEscapedQueryString;
- (NSString *) mulleURLEscapedParameterString;
- (NSString *) mulleStringByAddingPercentEncodingWithAllowedCharacters:(NSCharacterSet *) characterSet
                                                         lineSeparator:(NSString *) lineSep
                                                     keyValueSeparator:(NSString *) kvSep
                                                        skipEmptyValue:(BOOL) skipEmptyValue;
@end
```

- `[url mulleQueryDictionary]` decodes the query (`&`/`=` separated) into an
  `NSDictionary`; `mulleParameterDictionary` does the same for the `;`-path
  parameters.
- `[dict mulleURLEscapedQueryString]` / `mulleURLEscapedParameterString`
  encode back (caching appropriate `NSCharacterSet`s). The generic
  `mulleStringByAddingPercentEncoding...` takes an explicit character set and
  separators; `skipEmptyValue` omits `key=` for empty values (used by the
  parameter form).

### 3.7. `MulleObjCDeps+MulleCivetWeb.h`

```objc
@interface MulleObjCDeps( MulleCivetWeb)
+ (struct _mulle_objc_dependency *) dependencies;
@end
```

Loader bookkeeping: declares the runtime dependency list (auto-generated
`objc-deps.inc`) so other `MulleObjcLoader` classes can resolve the load
order. Not something application code calls directly.

## 4. Performance Characteristics

- **Per-request overhead:** the library adds one
  `MulleCivetWebRequest`/response object pair and header serialization per
  request; civetweb does the socket I/O and keep-alive handling. Total server
  overhead per request is sub-millisecond; throughput is dominated by handler
  work (low thousands of req/s on typical hardware, less for heavy
  `contentData` reads).
- **Concurrency:** civetweb runs a configurable thread pool
  (`num_threads`), so handlers can execute in parallel. Only the methods
  marked `MULLE_OBJC_THREADSAFE_METHOD` are safe to call from any worker
  thread; everything on `MulleCivetWebRequest` is thread-affine and must be
  consumed in the dispatching thread.
- **Body reading:** `contentData` is O(body size) and blocking; one
  `mg_read`-at-a-time. Streaming via `partialContentDataWithCapacity:` or the
  response stream holds memory to the buffer size (~1200 bytes for the stream)
  instead of the whole body.
- **Headers:** stored in dictionaries/arrays; `headerDataUsingEncoding:`
  builds a fresh `NSData` per response (allocates a 2 KiB buffer).
- **Thread safety:** the server is intentionally *not* autolocking; any lock
  would serialize civetweb worker threads. Coordinate shared handler state
  with `MulleAutolockingObjectProtocols`.

## 5. AI Usage Recommendations & Patterns

### Best practices

- Create the server with
  `[[[MulleCivetWebServer alloc] initWithCStringOptions:options] autorelease]`
  (the `alloc`+`init`+`autorelease` idiom used throughout `test/`). The
  server is listening immediately after this call.
- Attach a handler object via `[server setRequestHandler:handler]` — or
  subclass the server and override `webResponseForWebRequest:`. Both work;
  the handler object is the composable option, subclassing is for
  self-contained servers.
- Poll `[server isReady]` (or `openPortInfos`) from client threads before
  connecting.
- Always create responses with the `+webResponseForWebRequest:` factory (or
  `webResponseForError:` for error pages) and return them from the handler.
- For large or streaming bodies use `createStreamAndSendHeaderData` or
  manual `addToTransferEncodings:MulleHTTPTransferEncodingChunked` +
  `sendHeaderData` + repeated `sendChunkedContentData`. Return `nil` from the
  handler when you already sent the response yourself.
- Set the `date` property for deterministic, testable responses.
- On a strict (`MULLE_OBJC_PEDANTIC_EXIT`) build, call
  `[server mullePerformFinalize]` before exit so the civetweb threads release
  the universe.

### Common pitfalls

- Do **not** retain or copy `MulleCivetWebRequest`/`MulleCivetWebResponse`
  — they die with the request/response cycle. Never stash them in fields.
- Do not call `sendHeaderData` twice (asserts `! hasSentHeader`), and set all
  headers and transfer encodings before the first send.
- `contentData` blocks until the full body arrives and caps at `INT_MAX`;
  use `partialContentDataWithCapacity:` for big uploads — and never mix the
  two (partial reads are consumed and lost).
- `openPortInfos` and `optionForKey:` can return `nil` — check before use.
- `[request URL]` can return `nil` (too-long/malformed URI) — answer 414.
- Don't touch the `_`-prefixed instance variables (`_ctx`, `_info`,
  `_connection`, ...).
- If a client disconnects mid-write the response raises an exception; wrap
  handler body work in `@try`/`@catch` only if you need custom error text —
  the default `webResponseForException:` already returns a 500.

## 6. Integration Examples

### Example 1: Minimal HTTP server with a text-response handler

```objc
#import <MulleCivetWeb/MulleCivetWeb.h>

@interface MyHandler : NSObject < MulleCivetWebRequestHandler>
@end

@implementation MyHandler

- (MulleCivetWebResponse *) webServer:(MulleCivetWebServer *) server
             webResponseForWebRequest:(MulleCivetWebRequest *) request
                                    MULLE_OBJC_THREADSAFE_METHOD
{
   MulleCivetWebTextResponse   *response;

   response = [MulleCivetWebTextResponse webResponseForWebRequest:request];
   [response appendFormat:@"Method is %@\n",
      [request method] == MulleHTTPPost ? @"POST" : @"GET"];
   [response appendFormat:@"Accept-Encoding is %@\n",
      [request headerValueForKey:MulleHTTPAcceptEncodingKey]];
   [response appendString:@"Hello World"];

   return( response);
}

@end

int   main( void)
{
   MulleCivetWebServer      *server;
   MyHandler                *handler;
   static char              *options[] =
   {
      "listening_ports", "8080",
      "num_threads",     "4",
      NULL, NULL
   };

   server  = [[[MulleCivetWebServer alloc] initWithCStringOptions:options] autorelease];
   handler = [MyHandler object];

   // the server is already running now!
   [server setRequestHandler:handler];

   // strict exit needs the worker threads finalized before returning
   [server mullePerformFinalize];
   return( 0);
}
```

### Example 2: Custom error page, exception handler and port info

```objc
#import <MulleCivetWeb/MulleCivetWeb.h>

@interface InfoServer : MulleCivetWebServer
@end

@implementation InfoServer

- (MulleCivetWebResponse *) webResponseForWebRequest:(MulleCivetWebRequest *) request
                                    MULLE_OBJC_THREADSAFE_METHOD
{
   MulleCivetWebResponse   *response;
   NSArray                 *ports;

   response = [MulleCivetWebResponse webResponseForWebRequest:request];
   ports    = [self openPortInfos];
   [response setStatus:200];
   [response setHeaderValue:@"application/json" forKey:@"Content-Type"];
   [response setContentData:[[ports description] dataUsingEncoding:NSUTF8StringEncoding]];
   return( response);
}

- (MulleCivetWebResponse *) webServer:(MulleCivetWebServer *) server
              webResponseForException:(NSException *) exception
                     duringWebRequest:(MulleCivetWebRequest *) request
                                    MULLE_OBJC_THREADSAFE_METHOD
{
   return( [self webResponseForError:500
                  errorDescription:[exception description]
                     forWebRequest:request]);
}

@end
```

### Example 3: Chunked streaming response (self-sent, handler returns nil)

```objc
#import <MulleCivetWeb/MulleCivetWeb.h>
#import <MulleObjC/MulleObjC.h>

@interface ChunkedHandler : NSObject < MulleCivetWebRequestHandler>
@end

@implementation ChunkedHandler

- (MulleCivetWebResponse *) webServer:(MulleCivetWebServer *) server
             webResponseForWebRequest:(MulleCivetWebRequest *) request
                                    MULLE_OBJC_THREADSAFE_METHOD
{
   MulleCivetWebTextResponse   *response;

   response = [MulleCivetWebTextResponse webResponseForWebRequest:request];
   [response setDate:[NSDate dateWithTimeIntervalSinceReferenceDate:0]];
   [response addToTransferEncodings:MulleHTTPTransferEncodingChunked];

   if( [request method] == MulleHTTPHead)
      return( response);

   [response sendHeaderData];

   [response appendLine:@"Reply"];
   [response sendChunkedContentData];      // clears contentData

   [response appendLine:@"Second chunk"];
   [response sendChunkedContentData];

   return( nil);   // nil: handler transmitted the response itself -> 200
}

@end
```

### Example 4: Unit-testing a server with a fake request

```objc
#import <MulleCivetWeb/MulleCivetWeb.h>
#import <MulleCivetWeb/MulleCivetWebRequest+Private.h>

@interface QuietServer : MulleCivetWebServer
@end

@implementation QuietServer
@end

int   main( void)
{
   MulleCivetWebServer    *server;
   MulleCivetWebRequest   *request;
   NSData                 *contentData;
   NSUInteger             rval;
   static char            *options[] =
   {
      "listening_ports", "51296",
      NULL, NULL
   };

   server  = [[[QuietServer alloc] initWithCStringOptions:options] autorelease];
   contentData = [@"VfL Bochum 1848" dataUsingEncoding:NSUTF8StringEncoding];

   request = [MulleCivetWebRequest webRequestWithServer:server
                                                    URL:[NSURL URLWithString:@"/foo"]
                                                headers:@{
                                                            MulleHTTPContentTypeKey:   @"text/plain; charset=utf-8",
                                                            MulleHTTPContentLengthKey: [NSString stringWithFormat:@"%ld", [contentData length]]
                                                         }
                                            contentData:contentData];
   rval = [server handleWebRequest:request];
   mulle_printf( "status %lu\n", (unsigned long) rval);

   [server mullePerformFinalize];
   return( 0);
}
```

### Example 5: URL query parsing via NSURL

```objc
#import <MulleCivetWeb/MulleCivetWeb.h>

int   main( void)
{
   NSString       *query;
   NSDictionary   *params;
   NSURL          *url;

   params = @{ @"a" : @"b", @"q" : @"VfL Bochum 1848" };

   query = [params mulleURLEscapedQueryString];
   url   = [NSURL URLWithString:[NSString stringWithFormat:@"http://host/action?%@", query]];

   params = [url mulleQueryDictionary];
   mulle_printf( "%s\n", [params UTF8String]);

   return( 0);
}
```

## 7. Dependencies

Direct `mulle-sde` dependencies (from `.mulle/etc/sourcetree/config`):

- `MulleObjCHTTPFoundation` — HTTP enums (`MulleHTTPRequestMethod`), header
  keys (`MulleHTTPContentTypeKey`, `MulleHTTPAcceptEncodingKey`,
  `MulleHTTPContentLengthKey`, `MulleHTTPDateKey`, ...), transfer-encoding
  constants (`MulleHTTPTransferEncodingChunked`), date formatting, NSURL.
- `MulleFoundation` — umbrella foundation (NSString, NSData,
  NSDictionary/NSMutableDictionary, NSArray, NSDate, exceptions, threads).
- `mulle-objc-list` — build-time/runtime object list handling.
- `civetweb` — vendored C HTTP server (source-only, no build/no-link/
  no-header dependency; linked in as part of this library).
- Windows-only: `ws2_32` and `winpthread` (none-type, platform-windows).