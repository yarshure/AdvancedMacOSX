// locality.m -- time locality of reference

#include <stdio.h>      // for printf
#include <stdlib.h>     // for EXIT_SUCCESS
#include <time.h>       // for time_t, time()

// clang -g -Weverything -o locality locality.m

#define ARRAYSIZE 20000
int a[ARRAYSIZE][ARRAYSIZE]; // make a huge array

int main (void) {
    // Walk the array in row-major order, so that once we're done
    // with a page we never bother with it again.

    time_t starttime = time(NULL);
    for (int i = 0; i < ARRAYSIZE; i++){
        for(int j = 0; j < ARRAYSIZE; j++){
            a[i][j] = 1;
        }
    }

    time_t endtime = time (NULL);

    printf("row-major: %d operations in %ld seconds.\n", 
           ARRAYSIZE * ARRAYSIZE, endtime - starttime);

    // Walk the array in column-major order.  It ends up touching a bunch of
    // pages multiple times.

    starttime = time(NULL);
    for (int j = 0; j < ARRAYSIZE; j++){
        for(int i = 0; i < ARRAYSIZE; i++){
            a[i][j] = 1;
        }
    }

    endtime = time (NULL);

    printf("column-major: %d operations in %ld seconds.\n",
           ARRAYSIZE * ARRAYSIZE, endtime - starttime);
    
    return EXIT_SUCCESS;

} // main
