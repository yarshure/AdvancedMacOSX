// writestring.m -- take argv[1] and write it to a file, prepending the
//                  length of the string

// gcc -g -Wall -o writestring writestring.m

#import <errno.h>       // for errno
#import <fcntl.h>       // for open()
#import <stdint.h>      // for uint32_t
#import <stdio.h>       // for printf() and friends
#import <stdlib.h>      // for EXIT_SUCCESS et. al.
#import <string.h>      // for strerror()
#import <sys/stat.h>    // for permission flags
#import <unistd.h>      // for write() / close()

int main (int argc, char *argv[]) {
    if (argc != 2) {
        fprintf (stderr, "usage:  %s string-to-log\n", argv[0]);
        return EXIT_FAILURE;
    }
    
    int fd = open ("/tmp/stringfile.txt", O_WRONLY | O_CREAT | O_TRUNC, 
                   S_IRUSR | S_IWUSR);

    if (fd == -1) {
        fprintf (stderr, "can't open file.  Error %d (%s)\n", errno, strerror(errno));
        return EXIT_FAILURE;
    }

    // Write the length of the string (four bytes).
    uint32_t stringLength = strlen (argv[1]);
    size_t result = write (fd, &stringLength, sizeof(stringLength));

    if (result == -1) {
        fprintf (stderr, "can't write to file.  Error %d (%s)\n",
                 errno, strerror(errno));
        return EXIT_FAILURE;
    }

    result = write (fd, argv[1], stringLength);

    if (result == -1) {
        fprintf (stderr, "can't write to file.  Error %d (%s)\n",
                 errno, strerror(errno));
        return EXIT_FAILURE;
    }

    result = close (fd);
    if (result == -1) {
        fprintf (stderr, "can't close the file.  Error %d (%s)\n",
                 errno, strerror(errno));
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;

} // main
