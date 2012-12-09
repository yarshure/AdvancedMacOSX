// cheapls.m -- a featureless ls program using the directory iteration
//              functions

// clang -g -Weverything -o cheapls cheapls.m

#import <dirent.h>      // for opendir and friends
#import <errno.h>       // for errno
#import <stdio.h>       // for printf
#import <stdlib.h>      // for EXIT_SUCCESS
#import <string.h>      // for strerror
#import <sys/dirent.h>  // for struct dirent
#import <sys/types.h>   // for random type definition

int main (int argc, char *argv[]) {
    if (argc != 2) {
        fprintf (stderr, "usage:  %s /path/to/directory\n", argv[0]);
        return EXIT_FAILURE;
    }

    DIR *directory = opendir (argv[1]);
    if (directory == NULL) {
        fprintf (stderr, "could not open directory '%s'\n", argv[1]);
        fprintf (stderr, "error is is useful: %d (%s)\n", errno, strerror(errno));
        return EXIT_FAILURE;
    }

    struct dirent *entry;
    while ((entry = readdir(directory)) != NULL) {
        long position = telldir (directory);
        printf ("%3ld: %s\n", position, entry->d_name);
    }

    int result = closedir (directory);
    if (result == -1) {
        fprintf (stderr, "error closing directory: %d (%s)\n",
                 errno, strerror(errno));
        return EXIT_FAILURE;
    }
    return EXIT_SUCCESS;

} // main
