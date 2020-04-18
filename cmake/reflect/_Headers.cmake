#
# cmake/reflect/_Headers.cmake is generated by `mulle-sde reflect`. Edits will be lost.
#
if( MULLE_TRACE_INCLUDE)
   MESSAGE( STATUS "# Include \"${CMAKE_CURRENT_LIST_FILE}\"" )
endif()

set( INCLUDE_DIRS
src
src/civetweb/include
src/reflect
)

set( PRIVATE_GENERATED_HEADERS
src/reflect/_MulleCivetWeb-import-private.h
src/reflect/_MulleCivetWeb-include-private.h
)

set( PRIVATE_HEADERS
src/MulleCivetWebRequest+Private.h
src/MulleCivetWebResponse+Private.h
src/import-private.h
)

set( PUBLIC_GENERATED_HEADERS
src/reflect/_MulleCivetWeb-import.h
src/reflect/_MulleCivetWeb-include.h
)

set( PUBLIC_HEADERS
src/MulleCivetWebRequest+NSURL.h
src/MulleCivetWebRequest.h
src/MulleCivetWebResponse.h
src/MulleCivetWebServer.h
src/MulleCivetWebTextResponse.h
src/MulleCivetWeb.h
src/MulleObjCLoader+MulleCivetWeb.h
src/NSURL+MulleCivetWeb.h
src/NSURL+NSDictionary.h
src/civetweb/include/civetweb.h
src/import.h
)
