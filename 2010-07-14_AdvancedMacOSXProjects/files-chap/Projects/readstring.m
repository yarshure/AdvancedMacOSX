// readstring.m -- open /tmp/stringfile.txt and write out its contents

/* compile with
gcc -g -Wall -o readstring readstring.m
*/

#import <errno.h>       // for errno and strerror()
#import <fcntl.h>       // for open()
#import <stdint.h>      // for uint32_t
#import <stdio.h>       // for printf() and friends
#import <stdlib.h>      // for EXIT_SUCCESS et. al.
#import <string.h>      // for strerror()
#import <unistd.h>      // for read()

int main (int argc, char *argv[]) {
    int fd = open ("/tmp/stringfile.txt", O_RDONLY);

    if (fd == -1) {
        fprintf (stderr, "can't open file.  Error %d (%s)\n",
                 errno, strerror(errno));
        exit (EXIT_FAILURE);
    }

    uint32_t stringLength;
    ssize_t result = read (fd, &stringLength, sizeof(stringLength));

    if (result == -1) {
        fprintf (stderr, "can't read file.  Error %d (%s)\n",
                 errno, strerror(errno));
        exit (EXIT_FAILURE);
    }

    // +1 accounts for the trailing zero byte we'll be adding.
    char *buffer = malloc (stringLength + 1);

    result = read (fd, buffer, stringLength);

    if (result == -1) {
        fprintf (stderr, "can't read file.  Error %d (%s)\n",
                 errno, strerror(errno));
        exit (EXIT_FAILURE);
    }

    buffer[stringLength] = '\000';

    close (fd);

    printf ("our string is '%s'\n", buffer);

    free (buffer); // clean up our mess

    exit (EXIT_SUCCESS);

} // main

