// pcal.m -- display a calendar using popen

/* compile with
gcc -std=c99 -g -Wall -Wextra -o pcal pcal.m
*/

#import <stdio.h>   // perror(), popen(), printf()
#import <stdlib.h>  // EXIT_SUCCESS

#define BUFFER_SIZE (4096)
static const int kLinesToPrint = 9;

int main(void)
{
    int exit_status = EXIT_FAILURE;

    // Reverse the lines just for fun.
    FILE *pipeline = popen("cal 2010 | rev", "r");
    if (!pipeline) {
        perror("popen");
        return exit_status;
    }

    char buffer[BUFFER_SIZE];
    for (int i = 0; i < kLinesToPrint; i++) {
        char *s = fgets(buffer, sizeof(buffer), pipeline);

        if (s)
            printf("%s", buffer);
        else if (feof(pipeline))
            break;
        else if (ferror(pipeline)) {
            perror("fgets");
            goto bailout;
        } else {
            fputs("fgets returned NULL without EOF or error\n", stderr);
            goto bailout;
        }
    }
    exit_status = EXIT_SUCCESS;

bailout:
    pclose(pipeline);
    return exit_status;
}  // main
