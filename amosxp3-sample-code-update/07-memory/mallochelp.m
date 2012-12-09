// mallochelp.m -- try to figure out the "large" block size

/* compile with
clang -g -Weverything -o mallochelp mallochelp.m
*/

#import <sys/types.h>  // for random types
#import <unistd.h>     // for getpid(), sleep()
#import <stdlib.h>     // for malloc()
#import <stdio.h>      // for printf()

int main (void) {
    malloc (1024 * 16);
    printf ("my process ID is %d\n", getpid());
    sleep (30);
    return 0;
} // main
