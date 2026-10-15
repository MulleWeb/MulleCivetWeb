### 0.17.19



* document replacement of MulleObjCHTTPFoundation and MulleFoundation with the unified MulleWebFoundation dependency
* clarify that MulleWebFoundation bundles the foundation classes alongside HTTP enums, header keys, status text, and NSURL support
* note current API version is 0.17.19




* replace the MulleObjCHTTPFoundation and MulleFoundation requirements with the amalgamated MulleWebFoundation
* rename the mulle-objc-list build dependency to mulle-objc-tools

### 0.17.18



* Responses to a vanished client are now dropped silently instead of aborting the process during buffer flush/teardown
* failed writes now invalidate the connection so subsequent writes are harmless no-ops
* no crash for dead peers during autorelease pool drain

### 0.17.17


feature: conform MulleCivetWebServer to MulleObjCFuture protocol

* MulleCivetWebServer(Future) category now explicitly adopts \`< MulleObjCFuture \>`
* server instances can serve as futures/promises in async workflows
