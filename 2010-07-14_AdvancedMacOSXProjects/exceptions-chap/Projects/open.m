// open.m -- try opening files and getting different errors.


/* compile with
cc -g -Wmost -o open open.m
*/

#import <fcntl.h>       // for open()
#import <unistd.h>      // for close()
#import <sys/stat.h>    // for permission flags
#import <stdlib.h>      // for EXIT_SUCCESS, etc
#import <stdio.h>       // for printf() and friends
#import <errno.h>       // for errno
#import <string.h>      // for strerror()

// given a path and access flags, try to open the file.
// if an error happens, write it out to standard error.

void tryOpen (const char *path, int flags)
{
    int result;

    result = open (path, flags, S_IRUSR | S_IWUSR | S_IRGRP  | S_IWGRP);

    if (result == -1) {
        fprintf (stderr, "an error happened opening %s\n", path);

        switch (errno) {

          case ENOTDIR:
            fprintf (stderr, "    part of the path is not a directory\n");
            break;

          case ENOENT:
            fprintf (stderr, "    something doesn't exist, like part of a path, "
                     "or O_CREAT is not set and the file doesn't exist\n");
            break;

          case EISDIR:
            fprintf (stderr, "    tried to open a directory for writing\n");
            break;

          default:
            fprintf (stderr, "    another error happened:  errno %d, strerror: %s\n",
                     errno, strerror(errno));
        }

    } else {
        close (result);
    }

    fprintf (stderr, "\n");

} // tryOpen



int main (int argc, char *argv[])
{
    // trigger ENOTDIR
    tryOpen ("/mach.sym/blah/blah", O_RDONLY);

    // trigger ENOENT, part of the path doesn't exist
    tryOpen ("/System/Frameworks/bork/my-file", O_RDONLY);

    // trigger ENOENT, O_CREAT not set and file doesn't exist
    tryOpen ("/tmp/my-file", O_RDONLY);

    // trigger EISDIR
    tryOpen ("/dev", O_WRONLY);

    // trigger EEXIST
    tryOpen ("/private/var/log/system.log", O_CREAT | O_EXCL);

    return (EXIT_SUCCESS);

} // main
