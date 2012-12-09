// mmap-rot13.m -- use memory mapped I/O to apply the rot 13 'encryption'
//                 algorithm to a file.

// clang -g -Weverything -o mmap-rot13 mmap-rot13.m

#import <ctype.h>       // for isalpha(), etc
#import <errno.h>       // for errno
#import <stdio.h>       // for printf, etc
#import <stdlib.h>      // for EXIT_SUCCESS, etc
#import <string.h>      // for strerror()
#import <sys/fcntl.h>   // for O_RDWR and open()
#import <sys/mman.h>    // for mmap, etc
#import <sys/stat.h>    // for fstat() and struct stat
#import <sys/types.h>   // for caddr_t
#import <unistd.h>      // for close()

// walk the buffer shifting alphabetic characters 13 places
static void rot13 (caddr_t base, size_t length) {
    char *scan = base;
    char *stop = scan + length;

    while (scan < stop) {
        // there are tons of implementations of rot13 out on the net
        // much more compact than this
        if (isalpha(*scan)) {
            if ((*scan >= 'A' && *scan <= 'M') || (*scan >= 'a' && *scan <= 'm')) {
                *scan += 13;
            } else if ((*scan >= 'N' && *scan <= 'Z')
                       || (*scan >= 'n' && *scan <= 'z')) {
                *scan -= 13;
            }
        }
        scan++;
    }

} // rot13

static void processFile (const char *filename) {
    size_t length = 0;
    caddr_t base = NULL;

    // open the file first
    int fd = open (filename, O_RDWR);
    if (fd == -1) {
        fprintf (stderr, "could not open %s: error %d (%s)\n",
                 filename, errno, strerror(errno));
        goto bailout;
    }

    // figure out how big it is
    struct stat statbuf;
    int result = fstat (fd, &statbuf);
    if (result == -1) {
        fprintf (stderr, "fstat of %s failed: error %d (%s)\n",
                 filename, errno, strerror(errno));
        goto bailout;
    }
    length = (size_t)statbuf.st_size;

    // mmap it
    base = mmap (NULL, length, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (base == (caddr_t) -1) {
        fprintf (stderr, "could not mmap %s: error %d (%s)\n",
                 filename, errno, strerror(errno));
        goto bailout;
    }

    // bitrot it.
    rot13 (base, length);

    // flush the results
    result = msync (base, length, MS_SYNC);
    if (result == -1) {
        fprintf (stderr, "msync failed for %s: error %d (%s)\n",
                 filename, errno, strerror(errno));
        goto bailout;
    }

bailout:
    // clean up any messes we've made
    if (base != (caddr_t) -1) munmap (base, length);
    if (fd != -1) close (fd);
    
} // processFile

int main (int argc, char *argv[]) {
    if (argc == 1) {
        fprintf (stderr, "usage: %s /path/to/file ... \n"
                 "rot-13s files in-place using memory mapped i/o\n", argv[0]);
        exit (EXIT_FAILURE);
    }

    for (int i = 1; i < argc; i++) {
        processFile (argv[i]);
    }

    exit (EXIT_SUCCESS);

} // main
