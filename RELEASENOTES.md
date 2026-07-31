### 0.17.17


feature: conform MulleCivetWebServer to MulleObjCFuture protocol

* MulleCivetWebServer(Future) category now explicitly adopts \`< MulleObjCFuture \>`
* server instances can serve as futures/promises in async workflows
