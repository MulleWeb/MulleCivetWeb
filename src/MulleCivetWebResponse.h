//
//  MulleCivetWebResponse.h
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


@class MulleCivetWebRequest;


//
// abstract class: use a subclass that implements contentData
// The WebResponse has the connection of the WebServer, it sends
// its contents and header back. You cant't copy or retain a WebResponse, since
// the _connection is gone after the response is through
// Default header values:
//    Date: <now>
//    Content-Type: text/plain; charset=utf-8
//
@interface MulleCivetWebResponse : NSObject <MulleObjCOutputStream>
{
   NSString                        *_httpVersion;
   NSMutableArray                  *_orderedHeaderKeys;
   NSMutableDictionary             *_headers;
   void                            *_connection;
}

@property( readonly) BOOL      hasSentHeader;
@property( readonly) BOOL      hasCreatedStream;
@property( assign) NSUInteger  status;
@property( retain) NSString    *statusText;
@property( retain) NSData      *contentData;
@property( retain) NSDate      *date;  // useful for testing (usually nil)

// use this to create a response, request can't be nil
// if you subclass this you probably need the designated initialize
// which is in MulleCivetWebResponse+Private.h
+ (instancetype) webResponseForWebRequest:(MulleCivetWebRequest *) request;


// set header values
- (void) setHeaderValue:(NSString *) value
                 forKey:(NSString *) key;
- (NSString *) headerValueForKey:(NSString *) key;

// sending the response back
- (BOOL) sendHeaderData;
// sending the content back
- (BOOL) sendContentData;

// sendChunkedContentData will clear contentData, you can fill up again
// and call this again (be sure to add "chunked" to the TransferEncodings
// before sending the header
- (BOOL) sendChunkedContentData;

- (NSData *) headerDataUsingEncoding:(NSStringEncoding) encoding;

- (void) addToTransferEncodings:(NSString *) s;
- (BOOL) containsTransferEncoding:(NSString *) s;

- (void) clearContentData;

//
// Stream interface, sends chunkedContentData:, you must call
// sendHeaderData before writing it for the first time and you
// must add MulleHTTPTransferEncodingChunked to the transferEncodings;
//
// or use -createStreamAndSendHeaderData which does this for you.
//
// You must not create multiple streams!
//
- (MulleObjCBufferedOutputStream *) createStream;

- (MulleObjCBufferedOutputStream *) createStreamAndSendHeaderData;

@end

