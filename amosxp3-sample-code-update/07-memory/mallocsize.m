// mallocsize.m -- see what kind of block sizes malloc is actually giving us

// clang -g -Weverything -o mallocsize mallocsize.m

#import <malloc/malloc.h>  // for malloc_size()
#import <stdio.h>          // for printf()
#import <stdlib.h>         // for malloc()

static void allocprint (size_t size) {
    void *memory = malloc (size);
    printf ("malloc(%ld) has a block size of %ld\n",
	    size, malloc_size(memory));
    // Intentionally leaked so we get a new block of memory

} // allocprint

int main (void) {
    allocprint (1);
    allocprint (sizeof(double));
    allocprint (14);
    allocprint (16);
    allocprint (32);
    allocprint (48);
    allocprint (64);
    allocprint (100);
    return 0;
} // main
