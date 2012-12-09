// minimal 'read from stdin, process, send to stdout'

// clang -g -Weverything -o upcase1 upcase1.m

#import <Foundation/Foundation.h>	// for BOOL
#import <stdio.h>			// for standard I/O stuff
#import <stdlib.h>			// for EXIT_SUCCESS

static void changecaseBuffer(char buffer[], size_t length, BOOL upcase) {
    char *scan = buffer;
    const char *stop = buffer + length;
    
    while (scan < stop) {
        *scan = upcase ? (char)toupper(*scan) : (char)tolower(*scan);
        scan++;
    }
}  // changecaseBuffer


#define BUFFER_SIZE 2048

int main (void) {
    char buffer[BUFFER_SIZE];
    const BOOL upcase = YES;

    while (!feof(stdin)) {
        const size_t length = fread (buffer, 1, BUFFER_SIZE, stdin);
        changecaseBuffer(buffer, length, upcase);
        fwrite(buffer, 1, length, stdout);
    }
} // main

