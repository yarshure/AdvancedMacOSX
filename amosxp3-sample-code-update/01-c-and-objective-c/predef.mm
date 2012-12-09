// predef.mm -- play with predefined macros

// g++ -g -Wall -o predef -framework Foundation predef.mm

#import <Foundation/Foundation.h>
#import <stdio.h>  // for printf()

void someFunc (void) {
    printf ("file %s, line %d\n", __FILE__, __LINE__);
    printf ("  function: %s\n", __FUNCTION__);
    printf ("  pretty function: %s\n", __PRETTY_FUNCTION__);
} // someFunc

@interface SomeClass : NSObject
+ (void) someMethod;
+ (void) someMethod: (int) num  withArguments: (NSString *) arg;
@end

@implementation SomeClass
+ (void) someMethod {
    printf ("file %s, line %d\n", __FILE__, __LINE__);
    printf ("  function: %s\n", __FUNCTION__);
    printf ("  pretty function: %s\n", __PRETTY_FUNCTION__);
} // someMethod

+ (void) someMethod: (int) num  withArguments: (NSString *) arg {
    printf ("file %s, line %d\n", __FILE__, __LINE__);
    printf ("  function: %s\n", __FUNCTION__);
    printf ("  pretty function: %s\n", __PRETTY_FUNCTION__);
} // someMethod:withArguments

@end

class SomeOtherClass {
public:
    void SomeMemberFunction (int arg1, const char *arg2) {
        printf ("file %s, line %d\n", __FILE__, __LINE__);
        printf ("  function: %s\n", __FUNCTION__);
        printf ("  pretty function: %s\n", __PRETTY_FUNCTION__);
    }
};

int main (int argc, char *argv[]) {
    printf ("__APPLE__: %d\n", __APPLE__);
    printf ("today is %s, the time is %s\n",
            __DATE__, __TIME__);

    printf ("file %s, line %d\n", __FILE__, __LINE__);
    printf ("  function: %s\n", __FUNCTION__);
    printf ("  pretty function: %s\n", __PRETTY_FUNCTION__);

    someFunc ();

    [SomeClass someMethod];
    [SomeClass someMethod: 23  withArguments: @"snork"];

    SomeOtherClass something;
    something.SomeMemberFunction (23, "hi");

#if __LITTLE_ENDIAN__
    printf ("My integers have their least significant bytes first!\n");
#endif
#if __BIG_ENDIAN__
    printf ("My integers have their most significant bytes first!\n");
#endif

    return 0;
} // main
