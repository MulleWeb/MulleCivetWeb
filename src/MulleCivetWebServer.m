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

#include "civetweb.h"


@implementation MulleCivetWebServer

/* this code is just for demo purposes. */
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


- (MulleCivetWebResponse *) webResponse404ForWebRequest:(MulleCivetWebRequest *) request
{
   MulleCivetWebTextResponse   *textResponse;

   textResponse = [MulleCivetWebTextResponse webResponseForWebRequest:request];
   [textResponse appendString:@"Nothing here"];
   [textResponse setStatus:404];
   return( textResponse);
}


- (NSUInteger) handleException:(NSException *) exception
              duringWebRequest:(MulleCivetWebRequest *) request
{
   MulleCivetWebResponse   *response;

   response = nil;
   if( _requestHandler && [(id) _requestHandler respondsToSelector:_cmd])
      response = [_requestHandler webResponseForException:exception
                                         duringWebRequest:request];

   if( ! response)
      response = [self webResponseForException:exception
                              duringWebRequest:request];

   [self writeWebResponse:response
               onlyHeader:NO];

   return( [response status]);
}


- (void) writeWebResponse:(id <MulleCivetWebResponse>) response
               onlyHeader:(BOOL) onlyHeader
{
   NSData   *headerData;
   NSData   *contentData;

   headerData = [response headerDataUsingEncoding:NSUTF8StringEncoding];
   mg_write( _ctx, [headerData bytes], [headerData length]);
   if( onlyHeader)
      return;

   contentData = [response contentData];
   mg_write( _ctx, [contentData bytes], [contentData length]);
}


- (NSUInteger) handleWebRequest:(MulleCivetWebRequest *) request
{
   id <MulleCivetWebResponse>  response;

   //
   // ok so we get the URL and then peruse our dataSource
   // using valueForKeyPath:options:
   //
   if( _requestHandler)
   {
      response = [_requestHandler webResponseForWebRequest:request];
   }
   else
   {
      response = [self webResponse404ForWebRequest:request];
      // send a 404
   }

   NSCParameterAssert( response);
   [self writeWebResponse:response
               onlyHeader:[request method] == MulleHTTPHead];

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

   @autoreleasepool
   {
      request = [[[MulleCivetWebRequest alloc] initWithConnection:conn] autorelease];
      @try
      {
         rval = [server handleWebRequest:request];
      }
      @catch( NSException *localException)
      {
         rval = [server handleException:localException
                       duringWebRequest:request];
      }
   }

   assert( rval >= 0 && rval <= 999);
   return( (int) rval);
}


- (int) beginWithRequestInfo:(struct mg_request_info *) request_info
                  connection:(struct mg_connection *) conn
{
   return( 1);
}


static int   mulle_mongoose_begin_request( struct mg_connection *conn)
{
   MulleCivetWebServer     *server;
   struct mg_request_info  *info;

   info   = (void *) mg_get_request_info( conn);
   server = mg_get_user_data( (void *) conn);

   return( [server beginWithRequestInfo:info
                             connection:conn]);
}


- (void) endWithRequestInfo:(struct mg_request_info *) request_info
                 connection:(struct mg_connection *) conn
                       code:(int) code
{
}


static void   mulle_mongoose_end_request( struct mg_connection *conn, int reply_status_code)
{
   MulleCivetWebServer     *server;
   struct mg_request_info  *info;

   info   = (void *) mg_get_request_info( conn);
   server = mg_get_user_data( (void *) conn);

   [server endWithRequestInfo:info
                   connection:conn
                         code:reply_status_code];
}


#pragma mark -
#pragma mark setup


+ (void) initialize
{
   mg_init_library( 0);
}


- (instancetype) initWithOptions:(char **) options
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
   return( [self initWithOptions:NULL]);
}

- (void) finalize
{
   if( _ctx)
      mg_stop( _ctx);
   [super finalize];
}


static int   log_message( const struct mg_connection *conn, const char *message)
{
   struct mg_request_info  *info;
   MulleCivetWebServer     *server;

   info   = (struct mg_request_info *) mg_get_request_info( conn);
   server = info->user_data;
   [server log:[NSString stringWithCString:(char *) message]];
   return( 0);
}


- (void) log:(NSString *) s
{
   NSLog( @"%@", s);
}



@end

