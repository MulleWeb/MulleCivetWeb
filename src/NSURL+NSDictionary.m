#import "NSURL+NSDictionary.h"

#import "import-private.h"


@implementation NSString( NSDictionaryPercentEncodedParser)

- (NSDictionary *) mulleDictionaryByRemovingPercentEncodingWithLineSeparator:(NSString *) lineSep
                                                           keyValueSeparator:(NSString *) kvSep
{
   NSMutableDictionary   *dictionary;
   NSString              *s;
   NSString              *query;
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
   NSCharacterSet    *characterSet;

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
