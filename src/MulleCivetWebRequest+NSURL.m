//
//  MulleCivetWebRequest+NSURL.h
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
#import "MulleCivetWebRequest+NSURL.h"

#import "civetweb.h"

#import "NSURL+MulleCivetWeb.h"


@implementation MulleCivetWebRequest( NSURL)

// if this returns nil, then the response should be 414
// ```
// The HTTP protocol does not place any a priori limit on the length of a URI.
// Servers MUST be able to handle the URI of any resource they serve, and
// SHOULD be able to handle URIs of unbounded length if they provide
// GET-based forms that could generate such URIs. A server SHOULD return 414
// (Request-URI Too Long) status if a URI is longer than the server can
// handle (see section 10.4.15).
// ```
// I don't even know what the limit of civitweb is though...
//
static inline struct mg_request_info   *getInfo( MulleCivetWebRequest *self)
{
   return( (struct mg_request_info *) self->_info);
}



- (NSURL *) URL
{
   char                     *uri;
   size_t                   uri_len;
   char                     *query;
   size_t                   query_len;
   struct mg_request_info   *info;
   char                     *host;

   if( _url)
      return( _url);

   info = getInfo( self);
   uri  = (char *) info->local_uri;
   if( ! uri)
   {
#if DEBUG
      fprintf( stderr, "No URI in request\n");
#endif
      // [self log:@"empty URI"];
      errno = EINVAL;
      return( nil);
   }

   // 
   // https://stackoverflow.com/questions/23215227/is-it-appropriate-or-necessary-to-use-percent-encoding-with-http-headers
   //
   host = [self findHeaderValueAsCStringForKeyCString:"Host"];

   //
   // since we already have the whole string (somewhere in memory)
   // and we duplicate it with NSURL again...
   // we set an arbitrary limit of INT_MAX/4, which should leave
   // INT_MAX/2 space for whatever we want to do
   //
   uri_len = strlen( uri);
   if( uri_len > INT_MAX/4)
   {
      errno = EFBIG;
      return( nil);
   }

   query_len = 0;
   query     = (char *) info->query_string;
   if( query)
   {
      query_len = strlen( query);
      if( query_len > INT_MAX/4)
      {
         errno = EFBIG;
         return( nil);
      }
   }
   _url = [[[NSURL alloc] mulleInitHTTPWithEscapedURIUTF8Characters:uri
                                                             length:uri_len
                                         escapedQueryUTF8Characters:query
                                                             length:query_len
                                                               host:host
                                                              isSSL:info->is_ssl] autorelease];
   if( ! _url)
   {
#if DEBUG
      fprintf( stderr, "\"%.*s\" could not be parsed\n", (int) uri_len, uri);
#endif
      errno = EFAULT;
      return( nil);
   }

   return( _url);
}

@end


