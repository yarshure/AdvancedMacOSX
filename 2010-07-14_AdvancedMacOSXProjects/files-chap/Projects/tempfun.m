// tempfun.m -- see how different temp file names are generated

/* compile with
gcc -Wall -g -o tempfun tempfun.m
 */

#import <stdio.h>       // for the temp name functions
#import <stdlib.h>      // for EXIT_SUCCESS, etc
#import <string.h>      // for strcpy()
#import <unistd.h>      // for mk[s]temp

int main (int argc, char *argv[]) {
    char *name;
    char buffer[1024];

    printf ("my process ID is %d\n", getpid());

    name = tmpnam (NULL); 
    printf ("tmpnam(NULL) is '%s'\n", name);

    name = tmpnam (buffer);
    printf ("tmpnam(buffer) is '%s'\n", buffer);

    name = tempnam ("/System/Library", "my_prefix");
    printf ("tempname(/System/Library, my_prefix) is '%s'\n", name);
    free (name);

    name = tempnam ("/does/not/exist", "my_prefix");
    printf ("tempname(/does/not/exist, my_prefix) is '%s'\n", name);
    free (name);

    strcpy (buffer, "templateXXXXXX");
    name = mktemp (buffer);
    printf ("mktemp(templateXXXXXX) is '%s'\n", name);

    return (EXIT_SUCCESS);

} // main
