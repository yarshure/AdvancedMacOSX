// readvecstring.m -- open /tmp/stringfile.txt and write out its contents
//                    using scatter/gather reads

// clang -g -Weverything -o readvecstring readvecstring.m

#import <errno.h>       // for errno and strerror()
#import <fcntl.h>       // for open()
#import <stdint.h>      // for uint32_t
#import <stdio.h>       // for printf() and friends
#import <stdlib.h>      // for EXIT_SUCCESS et. al.
#import <string.h>      // for strerror()
#import <sys/stat.h>    // for permission flags
#import <sys/types.h>   // for ssize_t
#import <sys/uio.h>     // for readv() and struct iovec
#import <unistd.h>      // for close()

int main (void) {
    int fd = open ("/tmp/stringfile.txt", O_RDONLY);

    if (fd == -1) {
        fprintf (stderr, "can't open file.  Error %d (%s)\n",
                 errno, strerror(errno));
        return EXIT_FAILURE;
    }

    uint32_t stringLength;
    char buffer[4096];
    struct iovec vector[2];

    vector[0].iov_base = &stringLength;
    vector[0].iov_len = sizeof(stringLength);
    vector[1].iov_base = buffer;
    vector[1].iov_len = sizeof(buffer) - 1;

    ssize_t result = readv (fd, vector, 2);

    if (result == -1) {
        fprintf (stderr, "can't read file.  Error %d (%s)\n",
                 errno, strerror(errno));
        return EXIT_FAILURE;
    }

    buffer[stringLength] = '\000'; // need to zero-terminate it

    close (fd);

    printf ("our string is '%s'\n", buffer);

    return EXIT_SUCCESS;

} // main
