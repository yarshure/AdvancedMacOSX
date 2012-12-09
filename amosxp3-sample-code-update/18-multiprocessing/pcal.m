// pcal.m -- display a calendar using popen, with the lines reversed.

// clang -g -Weverything -o pcal pcal.m

#import <stdio.h>   // perror(), popen(), printf()
#import <stdlib.h>  // EXIT_SUCCESS

#define BUFFER_SIZE (4096)
static const int kLinesToPrint = 9;

int main (void) {
    int result = EXIT_FAILURE;

    // Reverse the lines just for fun.
    FILE *pipeline = popen("cal 2012 | rev", "r");
    if (!pipeline) {
        perror("popen");
        return result;
    }

    char buffer[BUFFER_SIZE];
    for (int i = 0; i < kLinesToPrint; i++) {
        char *line = fgets (buffer, sizeof(buffer), pipeline);

        if (line != NULL) {
            printf("%s", buffer);

        } else if (feof(pipeline)) {
            // All done
            break;

        } else if (ferror(pipeline)) {
            perror ("fgets");
            goto bailout;

        } else {
            // Shouldn't happen.
            fputs ("fgets returned NULL without EOF or error\n", stderr);
            goto bailout;
        }
    }
    result = EXIT_SUCCESS;

bailout:
    pclose (pipeline);
    return result;

}  // main
