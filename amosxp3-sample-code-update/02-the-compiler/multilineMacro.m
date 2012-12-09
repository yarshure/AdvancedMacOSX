// multilineMacro -- demonstrate hygiene for multi-line macros

/* compile with
clang -g -Weverything -Wno-unused-parameter -Wno-unused-macros -o multilineMacro multilineMacro.m
*/

#import <stdio.h> // for printf and friends

#define FOUND_AN_ERROR(desc)   \
    do {   \
        error_count++;   \
        fprintf(stderr, "found an error '%s' at file %s, line %d\n",  \
                desc, __FILE__, __LINE__); \
    } while (0)

#define FOUND_AN_ERROR2(desc)   \
    {   \
        error_count++;   \
        fprintf(stderr, "found an error '%s' at file %s, line %d\n",  \
                desc, __FILE__, __LINE__); \
    }

int error_count;

int main (int argc, char *argv[]) {
    if (argc == 2)
	FOUND_AN_ERROR2 ("something really bad happened");
    printf ("done\n");

    return (0);

} // main
