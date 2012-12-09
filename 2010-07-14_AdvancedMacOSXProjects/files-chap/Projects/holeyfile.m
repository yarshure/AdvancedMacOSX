// holeyfile.m -- make a file with a large hole in it

/* compile with
cc -g -o holeyfile holeyfile.m
*/

#import <unistd.h>	// for lseek
#import <fcntl.h>	// for open()
#include <sys/stat.h>	// for permission flags
#import <stdlib.h>	// for EXIT_SUCCESS et. al.
#import <stdio.h>	// for printf() and friends
#import <errno.h>	// for errno and strerror()

int main (int argc, char *argv[])
{
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

