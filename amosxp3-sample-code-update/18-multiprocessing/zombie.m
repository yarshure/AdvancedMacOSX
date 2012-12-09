// zombie.m -- make a zombie process

// clang -g -Weverything -o zombie zombie.m

#import <assert.h>    // assert()
#import <stdbool.h>   // true/false
#import <stdio.h>     // printf()
#import <stdlib.h>    // EXIT_SUCCESS, EXIT_FAILURE
#import <unistd.h>    // fork()
#import <sys/wait.h>  // wait()

int main(void) {

    // vfork() guarantees that child runs first
    pid_t child = vfork();

    if (child == -1) {
        perror ("fork");
        return EXIT_FAILURE;
    }

    const bool is_child = (child == 0);
    if (is_child) _exit(EXIT_SUCCESS);

    printf("Zombie child has pid %lu.\n", (unsigned long)child);

    sleep (10);  // take a look at ps during this time

    // now reap the child
    int status = 0;
    child = wait(&status);

    if (child == -1) {
        perror("wait");
        return EXIT_FAILURE;
    }

    assert(WIFEXITED(status));
    printf("Reaped child %lu exited with status %d.\n"
           "It should now be gone from ps.\n",
           (unsigned long) child,
           (int)WEXITSTATUS(status));

    sleep (10);

    return EXIT_SUCCESS;

} // main

