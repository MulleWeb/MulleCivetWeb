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

#import "NSURL+MulleCivetWeb.h"

#include "civetweb.h"

#include <signal.h>


@implementation MulleCivetWebRequest( Private)

// only to be used by the webserver

- (id) initWithConnection:(struct mg_connection *) connection
{
   struct mg_request_info   *info;

   assert( connection);
   _connection = connection;

   _info = (void *) mg_get_request_info( _connection);
   assert( _info);

   return( self);
}


- (id) initWithRequestInfo:(struct mg_request_info *) info
{
   _connection = (void *) 0xDEADBEEF;
   _info       = (void *) info;
   assert( _info);

   return( self);
}


+ (instancetype) webRequestWithServer:(MulleCivetWebServer *) server
                                  URL:(NSURL *) url
                              headers:(NSDictionary *) headers
                          contentData:(NSData *) data
{
   // fake a request manually
   MulleCivetWebRequest     *request;
   struct mg_request_info   *info;

   request = [NSAllocateObject( self, sizeof( struct mg_request_info), NULL) autorelease];
   info    = MulleObjCInstanceGetExtraBytes( request);

   info->request_method  = "GET";
   info->http_version    = "1.1";
   info->request_uri     = [[url description] UTF8String];
   info->content_length  = -1;
   info->remote_port     = 1848;
   info->user_data       = server;

   request->_info        = info;
   request->_url         = url;
   request->_headers     = headers;
   request->_contentData = data;
   request->_connection  = (void *) 0xBEEFDEAD;

   return( request);
}


@end


@implementation MulleCivetWebRequest : NSObject

- (id) init
{
   abort();
}


// struct mg_connection
- (struct mg_connection *) connection
{
   return( _connection);
}


static inline struct mg_request_info   *getInfo( MulleCivetWebRequest *self)
{
   return( (struct mg_request_info *) self->_info);
}


- (enum MulleHTTPRequestMethod) method
{
   struct mg_request_info   *info;

   info = getInfo( self);
   switch( info->request_method[ 0])
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

   switch( info->request_method[ 1])
   {
//   case 'A' : return( MulleHTTPPatch);
   case 'O' : return( MulleHTTPPost);
   case 'U' : return( MulleHTTPPut);
   default  : return( MulleHTTPOther);
   }
}


- (char *) URICString
{
   return( (char *) getInfo( self)->local_uri);
}


- (char *) queryCString
{
   return( (char *) getInfo( self)->query_string);
}


static char   *find_header_value_in_request_info( struct mg_request_info *info, char *key)
{
   struct mg_header   *header;
   struct mg_header   *sentinel;

   header   = &info->http_headers[ 0];
   sentinel = &info->http_headers[ info->num_headers];

   while( header < sentinel)
   {
      if( ! strcmp( key, header->name))
         return( (char *) header->value);
      ++header;
   }
   return( NULL);
}


- (char *) findHeaderCStringForKeyCString:(char *) key
{
   struct mg_request_info   *info;

   info = getInfo( self);
   return( find_header_value_in_request_info( info, key));
}


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
- (NSURL *) URL
{
   mulle_utf8_t             *uri;
   size_t                   uri_len;
   NSString                 *scheme;
   NSString                 *resourceSpecifier;
   struct mg_request_info   *info;
   char                     *host;

   if( _url)
      return( _url);

   info = getInfo( self);
   uri  = (mulle_utf8_t *) info->local_uri;
   if( ! uri)
   {
#if DEBUG
      fprintf( stderr, "No URI in request\n");
#endif
      // [self log:@"empty URI"];
      errno = EINVAL;
      return( nil);
   }

   host = find_header_value_in_request_info( info, "Host");

   //
   // since we already have the whole string (somewhere in memory)
   // and we duplicate it with NSURL again...
   // we set an arbitrary limit of INT_MAX/4, which should leave
   // INT_MAX/2 space for whatever we want to do
   //
   uri_len = mulle_utf8_strlen( uri);
   if( uri_len > INT_MAX/4)
   {
      errno = EFBIG;
      return( nil);
   }

   _url = [[[NSURL alloc] mulleInitHTTPWithEscapedURIUTF8Characters:uri
                                                             length:uri_len
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


- (void *) info
{
   return( _info);
}


- (NSString *) remoteUser
{
   return( [NSString stringWithUTF8String:(char *) getInfo( self)->remote_user]);
}


- (NSString *) remoteIP
{
   return( [NSString stringWithUTF8String:(char *) getInfo( self)->remote_addr]);
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
   NSMutableDictionary      *dictionary;
   int                      i, n;
   NSString                 *key;
   NSString                 *value;
   struct mg_request_info   *info;

   info = getInfo( self);

   if( _headers)
      return( _headers);

   n = info->num_headers;
   if( ! n)
      return( nil);

   dictionary = [NSMutableDictionary dictionaryWithCapacity:info->num_headers];
   for( i = 0; i < n; i++)
   {
      key   = [NSString stringWithUTF8String:(char *) info->http_headers[ i].name];
      value = [NSString stringWithUTF8String:(char *) info->http_headers[ i].value];
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


// TODO: use a mulle_buffer instead for partial read/writes ?
- (NSData *) contentData
{
   NSMutableData   *data;
   NSUInteger      length;
   uint8_t         *buf;
   int             read_len;
   BOOL            haveContentLength;
   NSUInteger      offset;

   if( _contentData)
      return( _contentData);

   //
   // if we get a contentLength we read up till it,
   // otherwise we read as much as we can
   //
   length            = [self contentLength];
   haveContentLength = (length != (NSUInteger) -1);
   if( ! haveContentLength)
      length = 0x1000;

   if( length > INT_MAX)
      return( nil);
   if( ! length)
      return( [NSData data]);

   data   = [NSMutableData mulleNonZeroedDataWithLength:length];
   offset = 0;

   for(;;)
   {
      //
      //    0     connection has been closed by peer. No more data could be read.
      //   <0   read error. No more data could be read from the connection.
      //   > 0   number of bytes read into the buffer.
      // mg_read does the chunking for us
      //
      buf      = [data mutableBytes];
      read_len = mg_read( _connection, &buf[ offset], length);
      if( read_len < 0)
         return( nil);

      if( read_len == length)
      {
         if( haveContentLength)
         {
            _contentData = data;
            return( data);
         }
      }
      else
      {
         if( haveContentLength)  // did not match expectation
            return( nil);

         if( read_len == 0)
         {
            // reduce our buffer
            [data mulleSetLengthDontZero:[data length] - length];
            _contentData = data;
            return( data);
         }
      }

      // adjust data so we can read "length" bytes again
      [data mulleSetLengthDontZero:[data length] + read_len];
      offset += read_len;
   }
}


- (NSData *) partialContentDataWithCapacity:(NSUInteger) length
{
   NSMutableData   *data;
   int             read_len;

   if( length > INT_MAX)
      return( nil);

   data = [NSMutableData mulleNonZeroedDataWithLength:length];

   //
   //    0     connection has been closed by peer. No more data could be read.
   //   <0   read error. No more data could be read from the connection.
   //   > 0   number of bytes read into the buffer.
   // mg_read does the chunking for us
   //
   read_len = mg_read( _connection, [data mutableBytes], length);
   if( read_len < 0)
      return( nil);

   [data mulleSetLengthDontZero:read_len];
   return( data);
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


