// fopen.m -- use gdb to poke around in a FILE handle

// clang -g -Weverything -o fopen fopen.m

#import <stdlib.h>
#import <stdio.h>

int main (void) {
    FILE *file;
    file = fopen ("/tmp/nork", "w+");

    fclose (file);

    exit (EXIT_SUCCESS);

} // main

