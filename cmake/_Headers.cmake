#
# cmake/_Headers.cmake is generated by `mulle-sde`. Edits will be lost.
#
if( MULLE_TRACE_INCLUDE)
   MESSAGE( STATUS "# Include \"${CMAKE_CURRENT_LIST_FILE}\"" )
endif()

set( INCLUDE_DIRS
src
src/civetweb/include
)

set( PRIVATE_HEADERS
src/MulleCivetWebRequest+Private.h
src/MulleCivetWebResponse+Private.h
src/import-private.h
)

set( PUBLIC_HEADERS
src/MulleCivetWebRequest.h
src/MulleCivetWebResponse.h
src/MulleCivetWebServer.h
src/MulleCivetWeb.h
src/MulleHTTP.h
src/MulleObjCLoader+MulleCivetWeb.h
src/NSDate+MulleHTTP.h
src/NSString+ListComponents.h
src/NSURL+MulleCivetWeb.h
src/NSURL+NSDictionary.h
src/civetweb/include/civetweb.h
src/import.h
)

