// nesting.h -- show nested, repeatedly included header files.

/* compile with
clang -H -o nesting nesting.m
*/

#include <fcntl.h>   // for opn()
#include <ulimit.h>  // for ulimit()
#include <pthread.h> // for pthread_create()
#include <dirent.h>  // for opendir()

int main (void) {
    // nobody home
    return (0);
} // main


