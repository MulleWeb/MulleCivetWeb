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
#import "MulleHTTP.h"

#include "civetweb.h"


@implementation MulleCivetWebServer

#pragma mark -
#pragma mark setup


+ (void) initialize
{
   mg_init_library( 0);
}


- (instancetype) initWithCStringOptions:(char **) options
{
   struct mg_callbacks   callbacks;
   NSString              *dir;
   char                  **p;

   /* Start Mongoose */
   memset( &callbacks, 0, sizeof(callbacks));

   snprintf( _server_name, sizeof( _server_name), "MulleCivetWeb (civetweb v. %.32s)",
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



#pragma mark -
#pragma mark ObjC Interfacing


- (MulleCivetWebResponse *) webResponseForException:(NSException *) exception
                                   duringWebRequest:(MulleCivetWebRequest *) request
{
   NSAutoreleasePool           *pool;
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
{
   MulleCivetWebTextResponse   *textResponse;

   textResponse = [MulleCivetWebTextResponse webResponseForWebRequest:request];
   [textResponse appendString:errorDescription];
   [textResponse setStatus:code];
   return( textResponse);
}


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
         response = [self webResponseForError:404
                             errorDescription:@"Nothing here"
                                forWebRequest:request];
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
static int   mulle_mongoose_handle_request( struct mg_connection *conn, void *p_server)
{
   MulleCivetWebServer     *server;
   MulleCivetWebRequest    *request;
   NSAutoreleasePool       *pool;
   NSUInteger              rval;
   NSData                  *utf8Data;
   NSString                *string;
   NSMutableString         *tmp;
   struct mg_request_info  *info;

   info   = (void *) mg_get_request_info( conn);
   server = p_server;

   // need to use this instead of @autoreleasepool, since
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
{
   struct mg_request_info   *info;

   info = (void *) mg_get_request_info( conn);

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
{
   struct mg_request_info   *info;

   info = (void *) mg_get_request_info( conn);
}


static void   mulle_mongoose_end_request( struct mg_connection *conn, int reply_status_code)
{
   MulleCivetWebServer      *server;

   server = mg_get_user_context_data( conn);
   [server endRequestWithConnection:conn
                               code:reply_status_code];
}


- (volatile BOOL) isReady
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
   mulle_mongoose_did_exit_thread( const struct mg_context *ctx, int thread_type, void *pool)
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

   [server log:[NSString stringWithCString:(char *) message]];
   return( 1);
}


- (void) log:(NSString *) s
{
   NSLog( @"%@", s);
}


- (NSArray *) openPortInfos
{
   int                     n;
   NSMutableArray          *array;
   struct mg_server_port   *ports;
   struct mg_server_port   *sentinel;
   NSNumber                *yes;
   NSNumber                *no;
   NSDictionary            *info;

   if( ! _ctx)
      return( nil);

   n = mg_get_server_ports( _ctx, 0, NULL);
   if( n < 0)
      return( nil);

   if( ! n)
      return( [NSArray array]);

   ports = MulleObjCCallocAutoreleased( n, sizeof( struct mg_server_port));
   n     = mg_get_server_ports( _ctx, n, ports);
   if( n < 0)
      return( nil);

   yes   = @(YES);
   no    = @(NO);

   array = [NSMutableArray arrayWithCapacity:n];
   sentinel = &ports[ n];
   while( ports < sentinel)
   {
      info = @{
               @"isSSL":      ports->is_ssl ? yes : no,
               @"isRedirect": ports->is_redirect ? yes : no,
               @"protocol":   ports->protocol == 3
                                 ? @"IPV6"
                                 : (ports->protocol == 2)
                                    ? @"???"
                                    : @"IPv4",
               @"port":      @(ports->port)
               };
      [array addObject:info];
      ++ports;
   }

   return( array);
}

@end

