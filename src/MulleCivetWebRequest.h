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

//
// EPHEMERAL INSTANCES, ONLY VALID IN SCOPE.DON'T COPY OR RETAIN
//
// the webrequest should not be retained or copied, it just lives during
// the lifetime of the request/response cycle. It will be created by the
// MulleCivetWebServer so don't create one yourself.
//
@interface MulleCivetWebRequest : NSObject
{
   void           *_connection;  // struct mg_connection *
   void           *_info;        // struct mg_request_info *
   id             _url;
   NSDictionary   *_headers;
   NSData         *_contentData;
}

- (enum MulleHTTPRequestMethod) method;
- (NSString *) HTTPVersion;
- (NSString *) remoteUser;
- (NSString *) remoteIP;

// waits for all data to arrive
- (NSData *) contentData;

//
// waits for up to length data to arrive (one call to mg_read)
// the data read with partialContentDataWithCapacity: will not be
// available through contentData.
// nil indicates failure
//
- (NSData *) partialContentDataWithCapacity:(NSUInteger) length;

//
// will not read more than INT_MAX bytes, if you need more
// use partialContentDatcaWithCapacity:
//
- (NSUInteger) contentLength;
- (NSDictionary *) headers;

- (NSString *) headerValueForKey:(NSString *) key;

// interface into struct mg_request_info
- (char *) URICString;
- (char *) queryCString;
- (void *) info;
- (unsigned int) remotePort;
- (BOOL) isSSL;
- (void *) clientCertificate;
- (char *) findHeaderValueAsCStringForKeyCString:(char *) key;

@end


