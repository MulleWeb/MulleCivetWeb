//
//  MulleCivetWebRequest.m
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
#import "MulleCivetWeb.h"

#import "import-private.h"

#include "civetweb.h"

#include <signal.h>

@implementation MulleCivetWebRequest( Private)

// only to be used by the webserver

- (id) initWithRequestInfo:(struct mg_request_info *) info
{
   _info = info;
   return( self);
}

@end


@implementation MulleCivetWebRequest : NSObject

- (id) init
{
   abort();
}


- (enum MulleHTTPRequestMethod) method
{
   switch( getInfo( self)->request_method[ 0])
   {
//   case 'C' : return( MulleHTTPConnect);
   case 'D' : return( MulleHTTPDelete);
   case 'G' : return( MulleHTTPGet);
   case 'H' : return( MulleHTTPHead);
//   case 'O' : return( MulleHTTPOptions);
   case 'P' : break;
//   case 'T' : return( MulleHTTPTrace);
   default  : return( MulleHTTPOther);
   }

   switch( getInfo( self)->request_method[ 1])
   {
//   case 'A' : return( MulleHTTPPatch);
   case 'O' : return( MulleHTTPPost);
   case 'U' : return( MulleHTTPPut);
   default  : return( MulleHTTPOther);
   }
}


- (NSURL *) URL
{
   size_t                      uri_len;
   size_t                      query_len;
   struct MulleURLUTF8Parts    parts;

   if( _url)
      return( _url);

   if( ! getInfo( self)->local_uri)
   {
      // [self log:@"empty URI"];
      return( nil);
   }

   uri_len = strlen( getInfo( self)->local_uri);
   if( uri_len >= INT_MAX / 2)
   {
      // [self log:@"overlong URI"];
      return( nil);
   }

   if( getInfo( self)->is_ssl)
   {
      parts.scheme_string     = (mulle_utf8_t *) "https";
      parts.scheme_string_len = 5;
   }
   else
   {
      parts.scheme_string     = (mulle_utf8_t *) "http";
      parts.scheme_string_len = 4;
   }
   parts.uri_string        = (mulle_utf8_t *) getInfo( self)->local_uri;
   parts.uri_string_len    = uri_len;

   query_len = getInfo( self)->query_string ? strlen( getInfo( self)->query_string) : 0;
   if( query_len >= INT_MAX / 2)
   {
      // [self log:@"overlong query"];
      return( nil);
   }

   parts.query_string      = (mulle_utf8_t *)  getInfo( self)->query_string;
   parts.query_string_len  = query_len;

   _url = [[[NSURL alloc] mulleInitWithURLUTF8Parts:&parts] autorelease];
   if( ! _url)
   {
      // [self log:@"invalid URI \"%.*s\"", (int) uri_len, getInfo( self)->local_uri];
      return( 0);

   }
   return( _url);
}


static inline struct mg_request_info   *getInfo( MulleCivetWebRequest *self)
{
   return( (struct mg_request_info *) self->_info);
}


- (void *) info
{
   return( _info);
}


- (NSString *) remoteUser
{
   return( [NSString stringWithCString:(char *) getInfo( self)->remote_user]);
}


- (NSString *) remoteIP
{
   return( [NSString stringWithCString:(char *) getInfo( self)->remote_addr]);
}


- (unsigned int) remotePort
{
   return( getInfo( self)->remote_port);
}


- (NSUInteger) contentLength
{
   return( (NSUInteger) getInfo( self)->content_length);
}


- (BOOL) isSSL
{
   return( getInfo( self)->is_ssl);
}


- (NSDictionary *) headers
{
   NSMutableDictionary   *dictionary;
   int                   i, n;
   NSString              *key;
   NSString              *value;

   if( _headers)
      return( _headers);

   n = getInfo( self)->num_headers;
   if( ! n)
      return( nil);

   dictionary = [NSMutableDictionary dictionaryWithCapacity:getInfo( self)->num_headers];
   for( i = 0; i < n; i++)
   {
      key   = [NSString stringWithUTF8String:(char *) getInfo( self)->http_headers[ i].name];
      value = [NSString stringWithUTF8String:(char *) getInfo( self)->http_headers[ i].value];
      [dictionary setObject:value
                     forKey:key];
   }

   _headers = dictionary;
   return( _headers);
}


- (void *) clientCertificate
{
   return( getInfo( self)->client_cert);
}


- (NSString *) HTTPVersion
{
   return( [NSString stringWithUTF8String:(char *) getInfo( self)->http_version]);
}


#ifdef DEBUG
- (id) retain
{
   abort();
}


- (id) copy
{
   abort();
}
#endif

@end


