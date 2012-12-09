// wire.m -- lock down a chunk of memory

// #import <Foundation/Foundation.h>
#import <sys/types.h>
#import <sys/mman.h>
#import <stdlib.h>
#import <errno.h>
#import <stdio.h>
#import <string.h>  // for memset

// clang -Weverything -g -o wire wire.m


#define VM_PAGE_SIZE ((unsigned long)4096)
#define MEM_SIZE (2 * VM_PAGE_SIZE)

int main (void) {
    void *memory;
    unsigned char *aligned;

    memory = malloc (MEM_SIZE * 2);
    aligned = (unsigned char *)((unsigned long) memory 
                                & ~(VM_PAGE_SIZE - 1)) + VM_PAGE_SIZE;
    printf ("memory is %p, aligned is %p\n", memory, aligned);
    memory = aligned;

    memset (memory, 0x55, MEM_SIZE); // make pages go from COW to PRV in vmmap
    printf ("memory is %p\n", memory);

    if (mlock (memory, MEM_SIZE) == -1) { 
	fprintf (stderr, "mlock error: %d (%s)\n", errno, strerror(errno));
	exit (0);
    }


    if (munlock (memory, 1024 * 1024) == -1) {
	fprintf (stderr, "munlock error: %d (%s)\n", errno, strerror(errno));
	exit (0);
    }

    return 0;
} // main

