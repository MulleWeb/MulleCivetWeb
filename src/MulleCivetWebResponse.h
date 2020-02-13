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


@protocol MulleCivetWebResponse

- (NSData *) headerDataUsingEncoding:(NSStringEncoding) encoding;
- (NSData *) contentData;
- (NSUInteger) status;
- (NSDate *) date;  // return nil
@end
@class MulleCivetWebResponse;



// move elsewhere
extern NSString  *MulleCivetWebDateKey;          // @"Date"
extern NSString  *MulleCivetWebContentTypeKey;   // @"Content-Type"
extern NSString  *MulleCivetWebContentLengthKey; // @"Content-Length
extern NSString  *MulleCivetWebTransferEncodingKey; // @"Transfer-Encoding


//
// abstract class: use a subclass that implements contentData
//
@interface MulleCivetWebResponse : NSObject <MulleCivetWebResponse>
{
   NSString              *_httpVersion;
   NSMutableArray        *_orderedHeaderKeys;
   NSMutableDictionary   *_headers;
}

@property( assign) NSUInteger  status;
@property( retain) NSString    *statusText;
@property( retain) NSData      *contentData;
@property( retain) NSDate      *date;  // useful for testing (usually nil)

// use this to create a reponse
+ (instancetype) webResponseForWebRequest:(MulleCivetWebRequest *) request;

// designated initializer
- (instancetype) initWithHTTPVersion:(NSString *) s;

- (NSData *) headerDataUsingEncoding:(NSStringEncoding) encoding;

@end

// something that returns text, like HTML or TXT or so
@interface MulleCivetWebTextResponse : MulleCivetWebResponse
{
   NSMutableString   *_content;
}

@property( assign) NSStringEncoding   encoding;

- (void) appendString:(NSString *) s;
- (void) appendLine:(NSString *) s;  // adds CR/LF

@end
