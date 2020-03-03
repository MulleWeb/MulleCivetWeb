#import "import.h"

#include <stdint.h>


/*
 *  (c) 2020 nat ORGANIZATION
 *
 *  version:  major, minor, patch
 */
#define MULLE_CIVET_WEB_VERSION  ((0 << 20) | (7 << 8) | 56)


static inline unsigned int   MulleCivetWeb_get_version_major( void)
{
   return( MULLE_CIVET_WEB_VERSION >> 20);
}


static inline unsigned int   MulleCivetWeb_get_version_minor( void)
{
   return( (MULLE_CIVET_WEB_VERSION >> 8) & 0xFFF);
}


static inline unsigned int   MulleCivetWeb_get_version_patch( void)
{
   return( MULLE_CIVET_WEB_VERSION & 0xFF);
}


extern uint32_t   MulleCivetWeb_get_version( void);


#import "MulleHTTP.h"
#import "NSDate+MulleHTTP.h"
#import "NSDate+MulleHTTP.h"
#import "NSString+ListComponents.h"
#import "NSURL+MulleCivetWeb.h"
#import "NSURL+NSDictionary.h"

#import "MulleCivetWebRequest.h"
#import "MulleCivetWebResponse.h"
#import "MulleCivetWebServer.h"

