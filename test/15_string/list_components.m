#import <MulleCivetWeb/MulleCivetWeb.h>


void test( NSString *s, NSString *component, NSString *separator)
{
   NSRange    range;
   NSString   *added;
   NSString   *removed;

   if( s)
      printf( "s=%s ", [s UTF8String]);
   else
      printf( "s=nil ");
   if( component)
      printf( "component=%s ", [component UTF8String]);
   else
      printf( "component=nil ");
   if( separator)
      printf( "separator=%s ", [separator UTF8String]);
   else
      printf( "separator=nil ");


   range = [s mulleRangeOfListComponent:component
                              separator:separator];
   if( range.length)
      printf( "range = { %lu, %lu } ", (unsigned long) range.location,
                                      (unsigned long) range.length);
   else
      printf( "range = { NSNotFound, 0 } ");

   added = [s mulleStringByAddingListComponent:component
                                     separator:separator];
   if( added)
      printf( "added=%s ", [added UTF8String]);
   else
      printf( "added=nil ");

   removed = [s mulleStringByRemovingListComponent:component
                                         separator:separator];

   if( removed)
      printf( "removed=%s ", [removed UTF8String]);
   else
      printf( "removed=nil ");
   printf( "\n");
}

void  test_separator_empty( NSString *separator)
{
   test( @"", nil, separator);
   test( @"", @"", separator);

   printf( "\n");
}


void  test_separator_comma( NSString *separator)
{
   test( @"", @"a", separator);
   test( @"a", @"", separator);
   test( @"a", @"a", separator);
   test( @"a", @"b", separator);
   test( @"a,b", @"c", separator);

   test( @"a,b,c", @"", separator);
   test( @"a,b,c", @"a", separator);
   test( @"a,b,c", @"b", separator);
   test( @"a,b,c", @"c", separator);
   test( @"a,b,c", @"d", separator);

   printf( "\n");
}


void  test_separator_minusminus( NSString *separator)
{
   test( @"a--b", @"c", separator);

   test( @"a--b--c", @"", separator);
   test( @"a--b--c", @"a", separator);
   test( @"a--b--c", @"b", separator);
   test( @"a--b--c", @"c", separator);
   test( @"a--b--c", @"d", separator);

   printf( "\n");
}


int   main( int argc, char *argv[])
{
   test_separator_empty( nil);
   test_separator_empty( @"");
   test_separator_empty( @",");

   test_separator_comma( @",");
   test_separator_minusminus( @"--");

   return( 0);
}
