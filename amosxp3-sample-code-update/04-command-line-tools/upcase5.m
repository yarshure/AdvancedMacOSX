// minimal 'read from stdin, process, send to stdout', using command-line
// arguments to choose between up and lower casing.  Some error checking using
// goto

// clang -g -Weverything -Wno-unused-parameter -o upcase5 upcase5.m


#import <Foundation/Foundation.h>	// for BOOL
#import <stdlib.h>			// for EXIT_FAILURE
#import <stdio.h>			// for standard I/O stuff

#define BUFFER_SIZE (2048)

static void changecaseBuffer(char buffer[], size_t length, BOOL upcase) {
    char *scan = buffer;
    const char *stop = buffer + length;
    
    while (scan < stop) {
        *scan = upcase ? (char)toupper(*scan) : (char)tolower(*scan);
        scan++;
    }
} // changecaseBuffer



int main (int argc, char *argv[]) {
    char buffer[BUFFER_SIZE];
    size_t length;
    BOOL upcase = YES;
    
    if (argc > 2) {
        fprintf (stderr, "bad argument count.  Must be zero or one\n");
        return (EXIT_FAILURE);
        
    } else if (argc == 2) {
        BOOL found = NO;
        
        if (strcmp(argv[1], "-u") == 0) {
            upcase = YES;
            found = YES;
        }
        if (strcmp(argv[1], "-l") == 0) {
            upcase = NO;
            found = YES;
        }
        if (!found) {
            fprintf (stderr, "bad command line argument: '%s'\n", argv[1]);
            fprintf (stderr, "expecting -u or -l\n");
            return (EXIT_FAILURE);
        }
    }
    
    while (!feof(stdin)) {
        length = fread (buffer, 1, BUFFER_SIZE, stdin);
        changecaseBuffer (buffer, length, upcase);
        fwrite (buffer, 1, length, stdout);
    }
    
    return (EXIT_SUCCESS);
    
} // main

