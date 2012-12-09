// fork.m -- show simple use of fork()

// clang -g -Weverything -o fork fork.m

#import <unistd.h>	// fork(), pid_t, sleep()
#import <stdlib.h>	// EXIT_SUCCESS, EXIT_FAILURE
#import <stdio.h>	// printf()

int main(void) {
    fputs ("Hello there!", stdout);  // no newline

    pid_t child = fork();

    switch (child) {
       case -1:
           perror ("fork");
           exit (EXIT_FAILURE);

       case 0:
           printf ("\nChild: My parent is %lu.\n", (unsigned long)getppid());
           _exit (EXIT_SUCCESS);

       default:
           printf ("\nParent: My child is %lu.\n", (unsigned long)child);

           // Delay a bit to improve the odds that the child will log before
           // the parent exits.
           sleep (2);
           exit (EXIT_SUCCESS);
    }

    // not reached
    return EXIT_FAILURE;
}  // main
