// access.m -- use the access() call to check permissions
//             run this as normal person, then make suid-root and try again

/* to compile:
   gcc -g -Wall -o access access.m
*/

#import <unistd.h>      // for access()
#import <stdio.h>       // for printf
#import <stdlib.h>      // for EXIT_SUCCESS
#import <errno.h>       // for errno and strerror
#import <string.h>      // for strerr()

int main (int argc, char *argv[]) {
    int result = access ("/mach_kernel", R_OK);

    if (result == 0) {
        printf ("read access to /mach_kernel\n");
    } else {
        printf ("no read access to /mach_kernel: %d (%s)\n",
                errno, strerror(errno));
    }

    result = access ("/mach_kernel", W_OK);

    if (result == 0) {
        printf ("write access to /mach_kernel\n");
    } else {
        printf ("no write access to /mach_kernel: %d (%s)\n",
                errno, strerror(errno));
    }

    return (EXIT_SUCCESS);

} // main
