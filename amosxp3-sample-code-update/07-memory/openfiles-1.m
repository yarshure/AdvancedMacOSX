// openfiles-1.m -- see what happens when we open a lot of files

/* compile with:
clang -g -Weverything -o openfiles openfiles-1.m
*/

#import <fcntl.h>  // for open()
#import <stdio.h>  // for printf()

int main (void) {
    int fd, i;

    for (i = 0; i < 260; i++) {
        fd = open ("/usr/include/stdio.h", O_RDONLY);
        printf ("%d: fd is %d\n", i, fd);
    }

    return (0);
    
} // main
