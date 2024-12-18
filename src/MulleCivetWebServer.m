//
//  MulleCivetWebServer.h
//  MulleCivetWeb
//
//  Created by Nat! on 02.02.20.
//
//  Copyright (c) 2020 Nat! - Mulle kybernetiK
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
//  Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  Neither the name of Mulle kybernetiK nor the names of its contributors
//  may be used to endorse or promote products derived from this software
//  without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//
#import "MulleCivetWebServer.h"

#import "MulleCivetWebRequest.h"
#import "MulleCivetWebRequest+Private.h"
#import "MulleCivetWebResponse.h"
#import "MulleCivetWebResponse+Private.h"
#import "MulleCivetWebTextResponse.h"

#include "civetweb.h"


@implementation MulleCivetWebServer

#pragma mark -
#pragma mark setup


+ (void) initialize
{
   mg_init_library( 0);
}


+ (void) deinitialize
{
   mg_exit_library();
}


- (instancetype) initWithCStringOptions:(char **) options
{
   struct mg_callbacks   callbacks;

   /* Start Mongoose */
   memset( &callbacks, 0, sizeof(callbacks));

   if( ! _server_name[ 0])
      snprintf( _server_name, sizeof( _server_name), "%s (civetweb v. %.32s)",
               [NSStringFromClass( [self class]) UTF8String],
               mg_version());

   callbacks.log_message   = &log_message;
   callbacks.begin_request = mulle_mongoose_begin_request;
   callbacks.end_request   = (void *) mulle_mongoose_end_request;
   callbacks.init_thread   = mulle_mongoose_did_init_thread;
   callbacks.exit_thread   = mulle_mongoose_did_exit_thread;

   _ctx = mg_start( &callbacks, self, (void *) options);
   if( ! _ctx)
   {
      [self release];
      return( nil);
   }
   mg_set_request_handler( _ctx, "/", mulle_mongoose_handle_request, self);
   return( self);
}


- (instancetype) init
{
   return( [self initWithCStringOptions:NULL]);
}


- (void) finalize
{
   if( _ctx)
      mg_stop( _ctx);
   [super finalize];
}


- (void) mulleGainAccess
{
   [super mulleGainAccess];
   [_requestHandler mulleGainAccess];
}


- (void) mulleRelinquishAccess
{
   [_requestHandler mulleRelinquishAccess];
   [super mulleRelinquishAccess];
}


#pragma mark -
#pragma mark ObjC Interfacing


- (MulleCivetWebResponse *) webResponseForException:(NSException *) exception
                                   duringWebRequest:(MulleCivetWebRequest *) request
                                   MULLE_OBJC_THREADSAFE_METHOD
{
   NSString                    *string;
   NSMutableString             *tmp;
   MulleCivetWebTextResponse   *textResponse;

   string = [[exception description] mulleStringByEscapingHTML];
   tmp    = [NSMutableString stringWithString:string];
   [tmp replaceOccurrencesOfString:@"\n"
                        withString:@"<BR>"
                           options:NSLiteralSearch
                              range:NSMakeRange( 0, [tmp length])];

   textResponse = [MulleCivetWebTextResponse webResponseForWebRequest:request];
   [textResponse appendString:tmp];
   [textResponse setStatus:500];
   return( textResponse);
}


- (MulleCivetWebResponse *) webResponseForError:(NSUInteger) code
                               errorDescription:(NSString *) errorDescription
                                  forWebRequest:(MulleCivetWebRequest *) request
                                   MULLE_OBJC_THREADSAFE_METHOD
{
   MulleCivetWebTextResponse   *textResponse;

   textResponse = [MulleCivetWebTextResponse webResponseForWebRequest:request];
   [textResponse appendString:errorDescription];
   [textResponse setStatus:code];
   return( textResponse);
}


- (MulleCivetWebResponse *) webResponseForWebRequest:(MulleCivetWebRequest *) request
                                   MULLE_OBJC_THREADSAFE_METHOD
{
   return( [self webResponseForError:404
                    errorDescription:@"Nothing here"
                       forWebRequest:request]);
}


//
// this is running in a thread, that mongoose/civetweb started
// The request is therefore affine to that thread. The MulleCivetWebRequest
// does not need to be threadsafe, its intended to be consumed in this
// thread
//
- (NSUInteger) handleWebRequest:(MulleCivetWebRequest *) request
{
   MulleCivetWebResponse   *response;

   @try
   {
      if( _requestHandler)
      {
         response = [_requestHandler webServer:self
                      webResponseForWebRequest:request];

         // nil means the handler sent the response itself, possibly
         // chunked. So assume it went OK. If the chunking fails, the
         // handler shouldn't raise, because this would just resend the
         // header
         if( ! response)
            return( 200);
      }
      else
      {
         // you could also subclass the server and override this
         response = [self webResponseForWebRequest:request];
      }
   }
   @catch( NSException *localException)
   {
      response = [self webResponseForException:localException
                              duringWebRequest:request];
   }

   NSCParameterAssert( response);

   [response sendHeaderData];
   if( [request method] != MulleHTTPHead)
      [response sendContentData];

   return( [response status]);
}


//
// civetweb request handling by URI is fairly limited, its better to implement
// subhandlers in Objective-C later
//
static int   mulle_mongoose_handle_request( struct mg_connection *conn,
                                            void *p_server)
{
   MulleCivetWebServer      *server;
   MulleCivetWebRequest     *request;
   NSUInteger               rval;
   struct mg_request_info   *info;

   // TODO: comment what the point of this is
   info   = (void *) mg_get_request_info( conn);
   MULLE_C_UNUSED( info);

   server = p_server;

   // need to use an @autoreleasepool here, since
   // this thread may not have been setup for Objective-C yet

   @autoreleasepool
   {
      request = [[[MulleCivetWebRequest alloc] initWithConnection:conn] autorelease];
      rval    = [server handleWebRequest:request];
   }

   assert( rval >= 0 && rval <= 999);
   return( (int) rval);
}


- (int) beginRequestWithConnection:(struct mg_connection *) conn
                                             MULLE_OBJC_THREADSAFE_METHOD
{
   struct mg_request_info   *info;

   // TODO: comment what's the point of this is ?
   info = (void *) mg_get_request_info( conn);
   MULLE_C_UNUSED( info);
   return( 0); 
}


static int   mulle_mongoose_begin_request( struct mg_connection *conn)
{
   MulleCivetWebServer     *server;

   server = mg_get_user_context_data( conn);
   // should check that the current thread is a mulle-objc thread,
   // if not make it one (create a NSThread object for it ?)
   return( [server beginRequestWithConnection:conn]);
}


- (void) endRequestWithConnection:(struct mg_connection *) conn
                             code:(int) code
                                         MULLE_OBJC_THREADSAFE_METHOD
{
   struct mg_request_info   *info;

   // TODO: comment what the point of this is
   info = (void *) mg_get_request_info( conn);
   MULLE_C_UNUSED( info);
}


static void   mulle_mongoose_end_request( struct mg_connection *conn,
                                          int reply_status_code)
{
   MulleCivetWebServer      *server;

   server = mg_get_user_context_data( conn);
   [server endRequestWithConnection:conn
                               code:reply_status_code];
}


- (volatile BOOL) isReady MULLE_OBJC_THREADSAFE_METHOD

{
   return( _isReady);
}


static void  *
   mulle_mongoose_did_init_thread( const struct mg_context *ctx, int thread_type )
{
   MulleCivetWebServer   *server;
   void                  *pool;

   if( thread_type == 0)
   {
      server = mg_get_user_data( ctx);
      server->_isReady = YES;
   }

   pool = MulleAutoreleasePoolPush();
   return( pool);  // could store something in TLS here
}


static void
   mulle_mongoose_did_exit_thread( const struct mg_context *ctx,
                                   int thread_type,
                                   void *pool)
{
   MulleCivetWebServer   *server;

   MulleAutoreleasePoolPop( pool);
   if( thread_type == 0)
   {
      server = mg_get_user_data( ctx);
      server->_isReady = NO;
   }
}


static int   log_message( const struct mg_connection *conn, const char *message)
{
   MulleCivetWebServer     *server;

   server = mg_get_user_context_data( conn);
   if( ! server)
      return( 0);  // use default logger

   [server log:@"%s", message];
   return( 1);
}


- (NSArray *) openPortInfos
{
   int                     n;
   NSDictionary            *info;
   NSMutableArray          *array;
   NSNumber                *no;
   NSNumber                *yes;
   struct mg_server_port   *p;
   struct mg_server_port   *ports;
   struct mg_server_port   *sentinel;
   int                     max;

   if( ! _ctx)
      return( nil);

   // stupid code
   for( n = max = 16; n == max; max *= 2)
   {
      ports = MulleObjCCallocAutoreleased( max, sizeof( struct mg_server_port));

      n = mg_get_server_ports( _ctx, max, ports);
      if( n == -1)
         return( nil);
   }

   yes      = @(YES);
   no       = @(NO);

   array    = [NSMutableArray arrayWithCapacity:n];
   p        = ports;
   sentinel = &p[ n];
   while( p < sentinel)
   {
      info = @{
               @"isSSL":      p->is_ssl ? yes : no,
               @"isRedirect": p->is_redirect ? yes : no,
               @"protocol":   p->protocol == 3
                                 ? @"IPV6"
                                 : (p->protocol == 2)
                                    ? @"???"
                                    : @"IPv4",
               @"port":      @(p->port)
               };
      [array addObject:info];
      ++p;
   }

   return( array);
}


- (NSString *) optionForKey:(NSString *) key
{
   char  *s;

   s = (char *) mg_get_option( _ctx, [key UTF8String]);
   if( ! s)
      return( nil);

   return( [NSString stringWithUTF8String:s]);
}


- (char *) optionCStringForKeyCString:(char *) key
{
   return( (char *) mg_get_option( _ctx, key));
}



// will be overridden later, just used by tests
- (void) log:(NSString *) format, ...   MULLE_OBJC_THREADSAFE_METHOD
{
   mulle_vararg_list  args;

   mulle_vararg_start( args, format);
   mulle_mvfprintf( stderr, [format UTF8String], args);
   mulle_vararg_end( args);
}

@end

