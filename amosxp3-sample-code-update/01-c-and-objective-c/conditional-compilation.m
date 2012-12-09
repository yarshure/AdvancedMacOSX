// conditional-compilation.m -- look at macro expansion

// clang -g -Weverything -o conditional-compilation conditional-compilation.m

#include <stdio.h>  // for printf()

#define DEFINED_NO_VALUE
#define VERSION 10
#define ZED 0

int main (void) {

#ifdef DEFINED_NO_VALUE
    printf ("defined_no_value is defined\n");
#else
    i can has syntax error;
#endif

#ifdef ZED
    printf ("zed is defined\n");
#endif

#if ZED
    printf ("zed evaluates to true\n");
#else
    printf ("zed evaluates to false\n");
#endif

#if VERSION > 5 && VERSION < 20
    printf ("version is in the correct range.\n");
#endif

    return 0;

} // main
