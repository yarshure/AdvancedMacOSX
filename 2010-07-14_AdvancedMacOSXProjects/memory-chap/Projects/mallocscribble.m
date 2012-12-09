// mallocscribble.m -- exercise MallocScribble
// Run this, then run after setting the MallocScribble environment
// variable to 1.

//gcc -o mallocscribble mallocscribble.m

#import <stdio.h>       // for printf()
#import <stdlib.h>      // for malloc()
#import <string.h>      // for strcpy()

int main (void) {
    Thingie *thing = malloc (20);
    
    strcpy (thing->string, "hello there");
    printf ("before free: %s\n", thing->string);
    free (thing);
    printf ("after free: %s\n", thing->string);

    return 0;

} // main
