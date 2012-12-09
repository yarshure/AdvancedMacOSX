// malloccheckstart.m -- play with MallocCheckHeapStart

/* compile wth:
clang -g -Weverything -o malloccheckstart malloccheckstart.m
*/

#import <stdlib.h>   // for malloc()
#import <string.h>   // for memset()

int main (void) {
    int i;
    unsigned char *memory;

    for (i = 0; i < 10000; i++) {
        memory = malloc (10);

        if (i == 3783) {
            // smash some memory
            memset (memory-128, 0x55, 256);
        }
    }
    return 0;
} // main
