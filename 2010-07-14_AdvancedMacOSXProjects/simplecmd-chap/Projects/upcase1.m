// minimal 'read from stdin, process, send to stdout'

#import <Foundation/Foundation.h>	// for BOOL
#import <stdio.h>			// for standard I/O stuff
#import <stdlib.h>			// for EXIT_SUCCESS

void changecaseBuffer(char buffer[], size_t length, BOOL upcase)
{
    char *scan = buffer;
    const char *stop = buffer + length;
    
    while (scan < stop) {
        *scan = upcase? toupper(*scan) : tolower(*scan);
        scan++;
    }
}  // changecaseBuffer


#define BUFFER_SIZE 2048

int main(int argc, char *argv[])
{
    char buffer[BUFFER_SIZE];
    const BOOL upcase = YES;

    while (!feof(stdin)) {
        const size_t length = fread (buffer, 1, BUFFER_SIZE, stdin);
        changecaseBuffer(buffer, length, upcase);
        fwrite(buffer, 1, length, stdout);
    }
} // main

