// debuglog-macro.m -- a macro for conditional logging

/* compile with
gcc -g -Wall -o debuglog-macro debuglog-macro.m
*/

#import <stdio.h>
#import <stdarg.h>

int globalLevel = 50;

#define DEBUG_LOG(logLevel, format, ...) \
do {  \
    if ((logLevel) > globalLevel) printf(format, ##__VA_ARGS__);  \
} while (0)

int main (int argc, char *argv[])
{
    DEBUG_LOG (10, "this will not be seen: %d, %s, %d\n", 10, "hello", 23);
    
    DEBUG_LOG (87, "this should be seen: %s, %d\n", "bork", 42);

    DEBUG_LOG (87, "bork");

    return (0);

} // main

