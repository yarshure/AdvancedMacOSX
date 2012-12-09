// wire.m -- lock down a chunk of memory

// #import <Foundation/Foundation.h>
#import <sys/types.h>
#import <sys/mman.h>
#import <stdlib.h>
#import <errno.h>
#import <stdio.h>

/* compile with
cc -framework Foundation -o wire wire.m
cc -g -o wire wire.m
*/

#define MEM_SIZE (2 * 4096)

int main (int argc, char *argv[])
{
    void *memory;
    unsigned char *aligned;


    memory = malloc (MEM_SIZE * 2);
    aligned = memory;
    aligned += 4096 - ((int)memory & 4096);
    printf ("memory is %p, aligned is %p\n", memory, aligned);
    memory = aligned;

    memset (memory, 0x55, MEM_SIZE); // make pages go from COW to PRV in vmmap
    printf ("memory is %p\n", memory);


    if (mlock (memory, MEM_SIZE) == -1) { 
	fprintf (stderr, "mlock error: %d (%s)\n", errno, strerror(errno));
	exit (0);
    }

    sleep (30);

    if (munlock (memory, 1024 * 1024) == -1) {
	fprintf (stderr, "munlock error: %d (%s)\n", errno, strerror(errno));
	exit (0);
    }

} // main

