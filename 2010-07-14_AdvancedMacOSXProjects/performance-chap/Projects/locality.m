// locality.m -- time locality of reference

#include <stdio.h>      // for printf
#include <stdlib.h>     // for EXIT_SUCCESS
#include <time.h>       // for time_t, time()

//gcc -g -o locality locality.m

#define ARRAYSIZE 20000
int a[ARRAYSIZE][ARRAYSIZE]; // make a huge array

int main (int argc, char *argv[]) {
    int i, j;
    time_t starttime, endtime;

    // Walk the array in row-major order, so that once we're done
    // with a page we never bother with it again.

    starttime = time(NULL);
    for (i = 0; i < ARRAYSIZE; i++){
        for(j = 0; j < ARRAYSIZE; j++){
            a[i][j] = 1;
        }
    }

    endtime = time (NULL);

    printf("row-major: %d operations in %ld seconds.\n",
           i * j, endtime - starttime);

    // Walk the array in column-major order.  We end up touching a bunch of
    // pages multiple times.

    starttime = time(NULL);
    for (j = 0; j < ARRAYSIZE; j++){
        for(i = 0; i < ARRAYSIZE; i++){
            a[i][j] = 1;
        }
    }

    endtime = time (NULL);

    printf("column-major: %d operations in %ld seconds.\n",
           i * j, endtime - starttime);
    
    return EXIT_SUCCESS;

} // main
