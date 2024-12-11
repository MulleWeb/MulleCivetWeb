//
//  MulleCivetWebServer.m
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


@class MulleCivetWebResponse;
@class MulleCivetWebRequest;
@class MulleCivetWebResponse;
@class MulleCivetWebServer;


@protocol MulleCivetWebRequestHandler

// maybe too much web here ? :)

 - (MulleCivetWebResponse *) webServer:(MulleCivetWebServer *) server
              webResponseForWebRequest:(MulleCivetWebRequest *) request
                                             MULLE_OBJC_THREADSAFE_METHOD;

 @optional
 - (MulleCivetWebResponse *) webServer:(MulleCivetWebServer *) server
               webResponseForException:(NSException *) exception
                      duringWebRequest:(MulleCivetWebRequest *) request
                                             MULLE_OBJC_THREADSAFE_METHOD;

@end

//
// the webserver gets requests via civetweb, usually it dispatches them
// to the requestHandler which should fill in the response.
// The server runs as soon as you init it. If you use MULLE_OBJC_PEDANTIC_EXIT
// you must mullePerformFinalize the server, so that the threads release
// the universe.
// We can't make this autolocking, as multiple threads from mongoose/civetweb
// would block each other, somewhat defeating the purpose.
//
@interface MulleCivetWebServer : MulleObject
{
   void   *_ctx;
   char   _server_name[ 256];
   char   _isReady;
}

// TODO: implement shareRecursiveLock with requestHandler and require it to
//       be a MulleObject ?
@property( assign) id <NSObject, MulleCivetWebRequestHandler>   requestHandler;

// options passed through to mg_start options
- (instancetype) initWithCStringOptions:(char **) options;

// if the server is listening
- (volatile BOOL) isReady  MULLE_OBJC_THREADSAFE_METHOD;

// you can override this, or plop in a requestHandler
- (MulleCivetWebResponse *) webResponseForWebRequest:(MulleCivetWebRequest *) request MULLE_OBJC_THREADSAFE_METHOD;

// for more control, override this
- (NSUInteger) handleWebRequest:(MulleCivetWebRequest *) request  MULLE_OBJC_THREADSAFE_METHOD;

// gives you an array of dictionaries, or nil if the information
// can't be obtained
- (NSArray *) openPortInfos;

- (NSString *) optionForKey:(NSString *) key;
- (char *) optionCStringForKeyCString:(char *) key;

// the way to create http errors like 404 or so
- (MulleCivetWebResponse *) webResponseForError:(NSUInteger) code
                               errorDescription:(NSString *) errorDescription
                                  forWebRequest:(MulleCivetWebRequest *) request
                                  MULLE_OBJC_THREADSAFE_METHOD;
@end



@interface MulleCivetWebServer(Future)

- (void) log:(NSString *) format, ...     MULLE_OBJC_THREADSAFE_METHOD;

@end



