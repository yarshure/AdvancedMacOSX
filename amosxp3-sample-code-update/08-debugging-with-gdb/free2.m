// free2.m -- generate a memory manager complaint

// clang -Weverything -g -o free2 free2.m

#import <stdlib.h>

int main (void) {
    char *blah;

    blah = malloc (1024);
    free (blah);
    free (blah);

    return 0;

} // main
