// sentinel.m -- Show __attribute__((sentinel)) in action

#import <stdio.h>  // for printf()
#import <stdarg.h> // for va_start() and friends

// clang -g -Weverything -o sentinel sentinel.m

void printStrings(char *first, ...) __attribute__((sentinel));

void printStrings(char *first, ...) {
    va_list args;
    va_start (args, first);
    char *string = first;

    while (string != NULL) {
        printf ("%s", string);
        string = va_arg (args, char *);
    }
    va_end (args);
    printf ("\n");
} // printStrings


int main (void) {
    printStrings ("spicy", "pony", "head", NULL);
    printStrings ("machine", "tool"); // should warn

    return 0;
} // main
