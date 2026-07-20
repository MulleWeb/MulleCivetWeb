### 0.17.16












* per-request threads now create/remove their Objective-C thread object, preventing thread-local/universe issues during request handling
* debug log prints use size-aware %tu for data lengths to avoid incorrect formatting on 64-bit platforms
* **BREAKING** rename of loader dependency category and generated include: MulleObjCDeps( MulleCivetWeb) → MulleObjCDeps( MulleCivetWeb); related headers/impl and generated inc renamed
