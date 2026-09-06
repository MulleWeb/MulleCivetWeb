### 0.17.18



* Responses to a vanished client are now dropped silently instead of aborting the process during buffer flush/teardown
* failed writes now invalidate the connection so subsequent writes are harmless no-ops
* no crash for dead peers during autorelease pool drain

### 0.17.17


feature: conform MulleCivetWebServer to MulleObjCFuture protocol

* MulleCivetWebServer(Future) category now explicitly adopts \`< MulleObjCFuture \>`
* server instances can serve as futures/promises in async workflows
