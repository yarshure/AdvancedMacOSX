// pthread_exit_exercise.m - pthread_exit() from main with threads
//clang -g -std=c99 -Wall -Wextra pthread_exit_exercise.m -o pthread_exit_exercise

#import <pthread.h> // pthread_*
#import <stdbool.h> // true/false
#import <stdio.h>   // fprintf
#import <stdlib.h>  // EXIT_*
#import <unistd.h>  // sleep

#define THREAD_COUNT (5)
pthread_t thread[THREAD_COUNT];

static void *log_and_die(void *);
static void log_msg(void *msg_addr);
static void log_exit(void);

int
main(void) {
    // uintptr_t is the same size as a pointer.
    for (uintptr_t i = 0; i < THREAD_COUNT; ++i) {
        int err = pthread_create(&thread[i],
                                 NULL/*attr*/,
                                 log_and_die,
                                 (void *)i);
        if (err) perror("pthread_create");
        else fprintf(stderr, "Created thread %lu: %p.\n",
                     (unsigned long)i, (void *)thread[i]);
    }

    // push/pop are macros and have to be used in matched pairs.
    // Otherwise, you end up with an unclosed brace
    // and useless warnings about nested functions.
    pthread_cleanup_push(&log_msg, "(Main thread exited.)");
    atexit(log_exit);

    // Note that the cleanup function
    // is called after pthread_exit(),
    // while the atexit-handler
    // is called once the last thread exits.
    fprintf(stderr, "Main thread exiting!\n");
    pthread_exit((void *)EXIT_SUCCESS);
    pthread_cleanup_pop(true);
    return EXIT_SUCCESS;
}

void *
log_and_die(void *threadnum) {
    fprintf(stderr, "%p: Thread %lu reporting for duty!\n",
            (void *)pthread_self(), (unsigned long)threadnum);
    sleep((random() >> 8) % 5);
    // Can't return the address of any local variable -
    // our stack will be gone after this!
    fprintf(stderr, "%p: Thread %lu exiting.\n",
            (void *)pthread_self(), (unsigned long)threadnum);
    return thread[(uintptr_t)threadnum];
}

void
log_msg(void *msg_addr) {
    fprintf(stderr, "%s\n", (const char *)msg_addr);
}

void
log_exit(void) {
    fputs("(Application terminated.)\n", stderr);
}

// vi: set ts=4 sw=4 et filetype=objc syntax=objc:
