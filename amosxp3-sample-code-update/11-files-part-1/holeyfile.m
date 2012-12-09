// holeyfile.m -- make a file with a large hole in it

// clang -g -Weverything -o holeyfile holeyfile.m

#import <errno.h>       // for errno and strerror()
#import <fcntl.h>       // for open()
#import <stdio.h>       // for printf() and friends
#import <stdlib.h>      // for EXIT_SUCCESS et. al.
#import <string.h>      // for strerror()
#import <sys/stat.h>    // for permission flags
#import <unistd.h>      // for lseek

int main (void) {
    int fd;
    off_t offset;

    fd = open ("/tmp/holeyfile", O_WRONLY | O_CREAT | O_TRUNC, 
               S_IRUSR | S_IWUSR);
    
    if (fd == -1) {
        fprintf (stderr, "can't open file.  Error %d (%s)\n",
                 errno, strerror(errno));
        exit (EXIT_FAILURE);
    }

    write (fd, "hello", 5); // write a little bit
    offset = lseek (fd, 50 * 1024 * 1024, SEEK_SET); // seek out to 50 megs

    write (fd, "goodbye", 7); // write a little more

    close (fd);

} // main

