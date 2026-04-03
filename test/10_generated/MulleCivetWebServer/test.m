#ifdef __MULLE_OBJC__
# import <MulleCivetWeb/MulleCivetWeb.h>
# include <mulle-testallocator/mulle-testallocator.h>
#else
# import <Foundation/Foundation.h>
#endif
#include <stdio.h>
#include <stdlib.h>
#if defined(__unix__) || defined(__unix) || (defined(__APPLE__) && defined(__MACH__))
# include <unistd.h>
#endif




@interface DebugServer : MulleCivetWebServer
@end

@implementation DebugServer

- (void) dealloc
{
   mulle_fprintf( stderr, "dealloc: before [super dealloc]\n");
   [super dealloc];
}

@end


static char  *options[] =
{
   "num_threads", "1",
   "listening_ports", "51294", // random ...
   NULL, NULL
};


//
// noleak checks for alloc/dealloc/finalize
// and also load/unload initialize/deinitialize
// if the test environment sets MULLE_OBJC_PEDANTIC_EXIT
//
static void   test_noleak( void)
{
   MulleCivetWebServer  *obj;

   @autoreleasepool
   {
      @try
      {
         obj = [[[DebugServer alloc] initWithCStringOptions:options] autorelease];
         if( ! obj)
         {
            mulle_fprintf( stderr, "failed to allocate\n");
            _exit( 1);
         }
      }
      @catch( NSException *localException)
      {
         mulle_fprintf( stderr, "Threw a %s exception\n", [[localException name] UTF8String]);
         _exit( 1);
      }
   }
}


static void   test_end( void)
{
   mulle_fprintf( stderr, "test is done\n");
}


int   main( int argc, char *argv[])
{
#ifdef __MULLE_OBJC__
   // check that no classes are "stuck"
   if( mulle_objc_global_check_universe( __MULLE_OBJC_UNIVERSENAME__) !=
         mulle_objc_universe_is_ok)
      _exit( 1);
#endif

   test_noleak();
   test_end();
   return( 0);
}
