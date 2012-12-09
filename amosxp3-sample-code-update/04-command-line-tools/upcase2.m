// minimal 'read from stdin, process, send to stdout', using the program
// name to distinguish between whether to upper or lower case

// clang -g -Weverything -Wno-unused-parameter -o upcase2 upcase2.m

#import <Foundation/Foundation.h>	// for BOOL
#import <stdlib.h>			// for EXIT_FAILURE
#import <stdio.h>			// for standard I/O stuff
#import <fnmatch.h>			// for fnmatch()

#define BUFFER_SIZE (2048)

static void changecaseBuffer(char buffer[], size_t length, BOOL upcase) {
    char *scan = buffer;
    const char *stop = buffer + length;
    
    while (scan < stop) {
        *scan = upcase ? (char)toupper(*scan) : (char)tolower(*scan);
        scan++;
    }
}  // changecaseBuffer



int main(int argc, char *argv[]) {
    char buffer[BUFFER_SIZE];

    /*const*/ BOOL upcase = YES;
    if (0 == fnmatch("*upcase", argv[0], 0)) {
        fprintf(stderr, "upcase!\n");
        upcase = YES;
    } else if (0 == fnmatch("*downcase", argv[0], 0)) {
        fprintf(stderr, "downcase!\n");
        upcase = NO;
    }

    while (!feof(stdin)) {
        const size_t length = fread(buffer, 1, BUFFER_SIZE, stdin);
        changecaseBuffer (buffer, length, upcase);
        fwrite(buffer, 1, length, stdout);
    }
}  // main

