//
//  NSURL+MulleCivetWeb.m
//  MulleCivetWeb
//
//  Copyright (c) 2020 Nat! - Mulle kybernetiK.
//  All rights reserved.
//
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
#import "NSURL+MulleCivetWeb.h"

#import "import-private.h"


@implementation NSURL( MulleCivetWeb)

- (instancetype) mulleInitHTTPWithEscapedURIUTF8Characters:(char *) uri
                                                    length:(NSUInteger) uri_len
                                escapedQueryUTF8Characters:(char *) query
                                                    length:(NSUInteger) query_len
                                                      host:(char *) host
                                                     isSSL:(BOOL) isSSL
{
   struct MulleEscapedURLPartsUTF8    parts;
   char                               *parameter;

   memset( &parts, 0, sizeof( parts));

   parts.scheme.characters = (isSSL ? "http" : "https");
   parts.scheme.length     = -1;

   parts.escaped_host.characters = host;
   parts.escaped_host.length     = -1;

   parts.escaped_path.characters = uri;
   parts.escaped_path.length     = uri_len;

   parameter = mulle_utf8_strnchr( uri, uri_len, ';');
   if( parameter)
   {
      parts.escaped_path.length = parameter - uri;

      parts.escaped_parameter.characters = parameter + 1;
      parts.escaped_parameter.length     = uri_len - (parts.escaped_path.length + 1);
   }

   parts.escaped_query.characters = query;
   parts.escaped_query.length     = query_len;

   return( [self mulleInitWithEscapedURLPartsUTF8:&parts
                           allowedURICharacterSet:nil]);
}

@end
