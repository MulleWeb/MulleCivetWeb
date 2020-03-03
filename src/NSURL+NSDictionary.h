#import "import.h"


@interface NSURL( NSDictionary)

- (NSDictionary *) mulleQueryDictionary;
- (NSDictionary *) mulleParameterDictionary;

@end


@interface NSString( NSDictionaryPercentEncodedParser)

- (NSDictionary *) mulleDictionaryByRemovingPercentEncodingWithLineSeparator:(NSString *) lineSep
                                                           keyValueSeparator:(NSString *) kvSep;
@end



@interface NSDictionary( NSDictionaryPercentEncodedPrinter)

- (NSString *) mulleURLEscapedQueryString;
- (NSString *) mulleURLEscapedParameterString;


- (NSString *) mulleStringByAddingPercentEncodingWithAllowedCharacters:(NSCharacterSet *) characterSet
                                                         lineSeparator:(NSString *) lineSep
                                                     keyValueSeparator:(NSString *) kvSep
                                                        skipEmptyValue:(BOOL) skipEmptyValue;
@end
