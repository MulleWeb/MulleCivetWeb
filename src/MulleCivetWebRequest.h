//
//  MulleCivetWebRequest.h
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
#import "import.h"


enum MulleHTTPRequestMethod
{
   MulleHTTPOther = -1,

   MulleHTTPGet   = 0,
   MulleHTTPPost  = 1,
   MulleHTTPPut,
   MulleHTTPDelete,
   MulleHTTPHead

   // there are quite a few more defined in WEBDAV and others
   // (see MulleObjCInetFoundation/http_parser.h)
   // should move these there
};


//
// EPHEMERAL INSTANCES, ONLY VALID IN SCOPE.DON'T COPY OR RETAIN
//
// the webrequest should not be retained or copied, it just lives during
// the lifetime of the request/response cycle. It will be created by the
// MulleCivetWebServer so don't create one.
//
@interface MulleCivetWebRequest : NSObject
{
   void           *_conn;  // struct mg_connection *
   void           *_info;  // struct mg_request_info *
   NSURL          *_url;
   NSDictionary   *_headers;
   NSData         *_contentData;
}

- (enum MulleHTTPRequestMethod) method;
- (NSURL *) URL;
- (NSString *) HTTPVersion;
- (NSString *) remoteUser;
- (NSString *) remoteIP;
- (NSData *) contentData;
- (NSUInteger) contentLength;
- (NSDictionary *) headers;

// interface into struct mg_request_info
- (char *) URICString;
- (char *) queryCString;
- (void *) info;
- (unsigned int) remotePort;
- (BOOL) isSSL;
- (void *) clientCertificate;

@end


