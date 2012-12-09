// mallocalign.m -- see how malloc aligns its pointers

// clang -Weverything -g -o mallocalign mallocalign.m

#import <stdio.h>   // for printf()
#import <stdlib.h>  // for malloc()

static void allocprint (size_t size) {
    void *memory = malloc (size);
    printf ("malloc(%ld) == %p\n", size, memory);
    // Intentionally leaked so we get a new block of memory
} // allocprint

int main (void) {
    allocprint (1);
    allocprint (2);
    allocprint (sizeof(double));
    allocprint (1024 * 1024);
    allocprint (1);
    allocprint (1);

    return 0;
} // main
