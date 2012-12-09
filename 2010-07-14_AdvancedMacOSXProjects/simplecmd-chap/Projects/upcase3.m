// minimal 'read from stdin, process, send to stdout', using command-line
// arguments to choose between up and lower casing

#import <Foundation/Foundation.h>	// for BOOL
#import <stdlib.h>			// for EXIT_FAILURE
#import <stdio.h>			// for standard I/O stuff

#define BUFFER_SIZE (2048)

void changecaseBuffer(char buffer[], size_t length, BOOL upcase)
{
    char *scan = buffer;
    const char *stop = buffer + length;

    while (scan < stop) {
        *scan = upcase? toupper(*scan) : tolower(*scan);
        scan++;
    }
}  // changecaseBuffer



int main(int argc, char *argv[])
{
    char buffer[BUFFER_SIZE];

    BOOL upcase = YES;
    const char *envSetting = getenv("CASE_CONV");
    if (NULL != envSetting) {
        if (0 == strcmp(envSetting, "UPPER")) {
            fprintf(stderr, "upper!\n");
            upcase = YES;
        } else if (0 == strcmp(envSetting, "LOWER")) {
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

