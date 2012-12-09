// openfiles.m -- Exhaust open-files resource limit.

// clang -Weverything -std=c99 -o openfiles openfiles.m
#import <errno.h>  // for errno
#import <fcntl.h>  // for O_RDONLY
#import <stdio.h>  // for fprintf()
#import <stdlib.h> // for exit, open
#import <string.h> // for strerror

int main (int argc, char *argv[]) {
    if (argc > 2) {
        fprintf (stderr, "usage:  %s [open-file-rlimit]\n", argv[0]);
        return 1;
    }

    if (argc == 2) {
        struct rlimit rl = { .rlim_cur = (rlim_t) atoi (argv[1]),
                             .rlim_max = RLIM_INFINITY };
        
        if (setrlimit(RLIMIT_NOFILE, &rl) == -1) {
            fprintf (stderr, "error in setrlimit for RLIM_NOFILE: %d/%s\n",
                     errno, strerror(errno));
            exit (1);
        }
    }

    for (int i = 0; i < 99999; i++) {
        int fd = open ("/usr/include/stdio.h", O_RDONLY);
        printf ("%d: fd is %d\n", i, fd);
        if (fd < 0) break;
    }

    return 0;
    
} // main

