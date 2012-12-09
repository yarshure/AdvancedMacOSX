// assert2.m -- make a false assertion, thereby dumping core

// clang -g -Weverything -Wno-unused-parameter -o assert2 assert2.m

#import <assert.h>        // for assert
#import <stdio.h>         // for printf
#import <string.h>        // for strlen
#import <stdlib.h>        // for EXIT_SUCCESS
#import <sys/resource.h>  // for setrlimit
#import <errno.h>         // for errno

static void anotherFunction (const char *ook) {
    assert (strlen(ook) > 0);
    printf ("wheeee! Got string %s\n", ook);
}  // anotherFunction

static void someFunction (const char *blah) {
    anotherFunction (blah);
}  // someFunction

static void enableCoreDumps (void) {
    struct rlimit rl = {
        .rlim_cur = RLIM_INFINITY,
        .rlim_max = RLIM_INFINITY
    };

    if (setrlimit(RLIMIT_CORE, &rl) == -1) {
        fprintf(stderr, "error in setrlimit for RLIMIT_CORE: %d (%s)\n",
                errno, strerror(errno));
    }
}  // enableCoreDumps


int main (int argc, const char *argv[]) {
    enableCoreDumps();
    someFunction(argv[1]);
    return EXIT_SUCCESS;
}  // main
