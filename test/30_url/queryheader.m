#import <MulleCivetWeb/MulleCivetWeb.h>


static void   test( NSDictionary *info)
{
   NSURL          *url;
   NSDictionary   *headers;
   NSString       *s;
   NSString       *query;

   s     = @"http://127.0.0.1/action";
   query = [info mulleURLEscapedQueryString];
   if( query)
      s = [NSString stringWithFormat:@"%@?%@", s, query];
   url = [NSURL URLWithString:s];

   printf( "%s\n", [url cStringDescription]);

   headers = [url mulleQueryDictionary];
   if( info && ! [info isEqualToDictionary:headers])
      printf( "FAIL %s <> %s\n", [info cStringDescription], [headers cStringDescription]);
}


int   main( int argc, char *argv[])
{
   test( nil);
   test( @{});
   test( @{ @"a": @"b" });
   test( @{ @"=a&": @"=b&" });

   return( 0);
}
