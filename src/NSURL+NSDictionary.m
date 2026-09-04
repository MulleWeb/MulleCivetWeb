//
//  NSURL+NSDictionary.m
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
#import "NSURL+NSDictionary.h"

#import "import-private.h"


@implementation NSString( NSDictionaryPercentEncodedParser)

- (NSDictionary *) mulleDictionaryByRemovingPercentEncodingWithLineSeparator:(NSString *) lineSep
                                                           keyValueSeparator:(NSString *) kvSep
{
   NSMutableDictionary   *dictionary;
   NSString              *s;
   NSArray               *lineComponents;
   NSArray               *keyValueComponents;
   NSString              *key;
   NSString              *value;
   NSUInteger            n;

   dictionary     = [NSMutableDictionary dictionary];
   lineComponents = [self componentsSeparatedByString:lineSep];

   for( s in lineComponents)
   {
      keyValueComponents = [s componentsSeparatedByString:kvSep];
      key                = [keyValueComponents objectAtIndex:0];
      n                  = [keyValueComponents count];

      switch( n)
      {
      case 0 :
         continue;  // keyValueComponents is nil

      case 1 :
         value = @"";
         break;

      case 2 :
         value = [keyValueComponents objectAtIndex:1];
         break;

      default :
         keyValueComponents = [keyValueComponents subarrayWithRange:NSMakeRange( 1, n - 1)];
         value              = [keyValueComponents componentsJoinedByString:kvSep];
      }

      key   = [key stringByRemovingPercentEncoding];
      value = [value stringByRemovingPercentEncoding];

      [dictionary setObject:value
                     forKey:key];
   }
   return( dictionary);
}

@end




@implementation NSDictionary( NSDictionaryPercentEncodedPrinter)

static struct
{
   mulle_atomic_pointer_t   _queryCharset;
   mulle_atomic_pointer_t   _parameterCharset;
} Self;


+ (void) unload
{
   [(id) _mulle_atomic_pointer_nonatomic_read( &Self._parameterCharset) release];
   [(id) _mulle_atomic_pointer_nonatomic_read( &Self._queryCharset) release];
}


static NSCharacterSet  *getURLParameterAllowedWithoutSemicolonAndEqualCharacterSet( void)
{
   NSMutableCharacterSet  *characterSet;

   /*
    * Cache
    */
   characterSet = (NSMutableCharacterSet *) _mulle_atomic_pointer_read( &Self._parameterCharset);
   if( ! characterSet)
   {
      characterSet = [NSMutableCharacterSet URLQueryAllowedCharacterSet];
      [characterSet removeCharactersInString:@";="];

      // if
      mulle_atomic_memory_barrier();
      if( _mulle_atomic_pointer_cas( &Self._parameterCharset, characterSet, NULL))
         [characterSet retain];
   }
   return( characterSet);
}


static NSCharacterSet  *getURLQueryAllowedWithoutAmpersandAndEqualCharacterSet( void)
{
   NSMutableCharacterSet   *characterSet;

   /*
    * Cache
    */
   characterSet = (NSMutableCharacterSet *) _mulle_atomic_pointer_read( &Self._queryCharset);
   if( ! characterSet)
   {
      characterSet = [NSMutableCharacterSet URLQueryAllowedCharacterSet];
      [characterSet removeCharactersInString:@"=&"];

      // if
      mulle_atomic_memory_barrier();
      if( _mulle_atomic_pointer_cas( &Self._queryCharset, characterSet, NULL))
         [characterSet retain];
   }
   return( characterSet);
}


- (NSString *) mulleStringByAddingPercentEncodingWithAllowedCharacters:(NSCharacterSet *) characterSet
                                                         lineSeparator:(NSString *) lineSep
                                                     keyValueSeparator:(NSString *) kvSep
                                                        skipEmptyValue:(BOOL) skipEmptyValue
{
   NSMutableString   *s;
   NSString          *key;
   NSString          *value;
   NSString          *sep;

   s   = [NSMutableString object];
   sep = @"";
   for( key in self)
   {
      value = [self objectForKey:key];

      key   = [[key description] stringByAddingPercentEncodingWithAllowedCharacters:characterSet];
      value = [[value description] stringByAddingPercentEncodingWithAllowedCharacters:characterSet];

      [s appendString:sep];
      [s appendString:key];

      if( ! skipEmptyValue || [value length])
      {
         [s appendString:kvSep];
         [s appendString:value];
      }
      sep = lineSep;
   }

   if( ! [s length])
      return( nil);
   return( s);
}



- (NSString *) mulleURLEscapedQueryString
{
   NSCharacterSet    *characterSet;

   characterSet = getURLQueryAllowedWithoutAmpersandAndEqualCharacterSet();
   assert( characterSet);

   return( [self mulleStringByAddingPercentEncodingWithAllowedCharacters:characterSet
                                                           lineSeparator:@"&"
                                                       keyValueSeparator:@"="
                                                          skipEmptyValue:NO]);
}


- (NSString *) mulleURLEscapedParameterString
{
   NSCharacterSet    *characterSet;

   characterSet = getURLParameterAllowedWithoutSemicolonAndEqualCharacterSet();
   assert( characterSet);

   return( [self mulleStringByAddingPercentEncodingWithAllowedCharacters:characterSet
                                                           lineSeparator:@";"
                                                       keyValueSeparator:@"="
                                                          skipEmptyValue:YES]);
}

@end



@implementation NSURL( NSDictionary)


- (NSDictionary *) mulleQueryDictionary
{
   NSDictionary   *dictionary;
   NSString       *query;

   query      = _escapedQuery;
   dictionary = [query mulleDictionaryByRemovingPercentEncodingWithLineSeparator:@"&"
                                                               keyValueSeparator:@"="];
   return( dictionary);
}


- (NSDictionary *) mulleParameterDictionary
{
   NSDictionary   *dictionary;
   NSString       *parameterString;

   parameterString = _escapedParameterString;
   dictionary      = [parameterString mulleDictionaryByRemovingPercentEncodingWithLineSeparator:@";"
                                                                              keyValueSeparator:@"="];
   return( dictionary);
}


@end
