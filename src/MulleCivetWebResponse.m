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
#import "MulleCivetWebResponse.h"

#import "MulleCivetWebRequest.h"

#include "civetweb.h"


NSString  *MulleCivetWebDateKey          = @"Date";
NSString  *MulleCivetWebContentTypeKey   = @"Content-Type";
NSString  *MulleCivetWebContentLengthKey = @"Content-Length";


@implementation MulleCivetWebResponse

- (instancetype) initWithHTTPVersion:(NSString *) s
{
   if( ! s)
      s = @"1.1";

   _httpVersion       = [s copy];
   _headers           = [NSMutableDictionary new];
   _orderedHeaderKeys = [NSMutableArray new];
   _status            = 200;
   _statusText        = @"OK";

   return( self);
}


- (instancetype) init
{
   return( [self initWithHTTPVersion:nil]);
}


+ (instancetype) webResponseForWebRequest:(MulleCivetWebRequest *) request
{
   return( [[[self alloc] initWithHTTPVersion:[request HTTPVersion]] autorelease]);
}


- (void) dealloc
{
   [_httpVersion release];
   [_headers release];
   [_orderedHeaderKeys release];

   [super dealloc];
}


- (void) setObject:(NSString *) value
            forKey:(NSString *) key
{
   assert( ! [key hasSuffix:@":"]);

   if( ! [_headers objectForKey:key])
      [_orderedHeaderKeys addObject:key];
   [_headers setObject:value
                forKey:key];
}


static void   appendHTTPHeaderToDataUsingEncoding( NSMutableData *data,
                                                   NSString *key,
                                                   NSString *value,
                                                   NSStringEncoding encoding)
{
   [data appendData:[key dataUsingEncoding:encoding]];
   [data appendBytes:": "
              length:2];
   [data appendData:[value dataUsingEncoding:encoding]];
   [data appendBytes:"\r\n"
              length:2];
}


- (NSData *) headerDataUsingEncoding:(NSStringEncoding) encoding
{
   NSMutableData   *data;
   NSUInteger      contentLength;
   NSString        *key;
   NSString        *value;
   NSData          *contentData;
   NSDate          *date;
   NSString        *s;

   contentLength = [[self contentData] length];

   data = [NSMutableData dataWithCapacity:contentLength+2048];

   assert( _status);
   assert( _statusText);

   s = [NSString stringWithFormat:@"HTTP/%@ %lu %@\r\n",
         _httpVersion, (unsigned long) _status, _statusText];
   [data appendData:[s dataUsingEncoding:encoding]];


   // do some standard headers
   key   = MulleCivetWebDateKey;
   value = [_headers objectForKey:key];
   if( ! value)
   {
      date  = _date ? _date : [NSDate date];
      value = [date description];
   }
   [_orderedHeaderKeys removeObject:key];
   appendHTTPHeaderToDataUsingEncoding( data, key, value, encoding);

   key   = MulleCivetWebContentTypeKey;
   value = [_headers objectForKey:key];
   if( ! value)
      value = @"text/plain; charset=utf-8";
   [_orderedHeaderKeys removeObject:key];
   appendHTTPHeaderToDataUsingEncoding( data, key, value, encoding);

   key   = MulleCivetWebContentLengthKey;
   value = [_headers objectForKey:key];
   if( ! value)
      value = [NSString stringWithFormat:@"%lu", (unsigned long) contentLength];
   [_orderedHeaderKeys removeObject:key];
   appendHTTPHeaderToDataUsingEncoding( data, key, value, encoding);

   for( key in _orderedHeaderKeys)
   {
      value = [_headers objectForKey:key];
      appendHTTPHeaderToDataUsingEncoding( data, key, value, encoding);
   }
   [data appendBytes:"\r\n"
              length:2];

   return( data);
}

@end


// something that returns text, like HTML or TXT or so
@implementation MulleCivetWebTextResponse

- (instancetype) initWithHTTPVersion:(NSString *) s
{
   self = [super initWithHTTPVersion:s];
   if( self)
   {
      _content = [NSMutableString new];
      _encoding = NSUTF8StringEncoding;
   }
   return( self);
}


- (void) dealloc
{
   [_content release];

   [super dealloc];
}

- (void) appendString:(NSString *) s
{
   [_content appendString:s];
}


- (void) appendLine:(NSString *) s
{
   [_content appendString:s];
   [_content appendString:@"\r\n"];
}


- (NSData *) contentData
{
   NSData   *data;

   data = _contentData;
   if( ! data)
   {
      data = [_content dataUsingEncoding:_encoding];
      [self setContentData:data];
   }
   return( data);
}

@end
