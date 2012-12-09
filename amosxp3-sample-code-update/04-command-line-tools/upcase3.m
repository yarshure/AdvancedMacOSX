// minimal 'read from stdin, process, send to stdout', using command-line
// arguments to choose between up and lower casing

// clang -g -Weverything -Wno-unused-parameter -o upcase3 upcase3.m

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



int main (void) {
    char buffer[BUFFER_SIZE];

    BOOL upcase = YES;
    const char *envSetting = getenv("CASE_CONV");

    if (envSetting != NULL) {
        if (strcmp(envSetting, "UPPER") == 0) {
            fprintf(stderr, "upper!\n");
            upcase = YES;
        } else if (strcmp(envSetting, "LOWER") == 0) {
            fprintf(stderr, "lower!\n");
            upcase = NO;
        }
    }

    while (!feof(stdin)) {
        const size_t length = fread (buffer, 1, BUFFER_SIZE, stdin);
        changecaseBuffer (buffer, length, upcase);
        fwrite (buffer, 1, length, stdout);
    }
    return EXIT_SUCCESS;
} // main

