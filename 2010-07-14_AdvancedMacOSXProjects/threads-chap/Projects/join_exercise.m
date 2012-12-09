// join_exercise.m - Create 5 threads and join with them.
//clang -g -std=c99 -Wall -Wextra join_exercise.m -o join_exercise

#import <pthread.h> // pthread_*
#import <stdio.h>   // fprintf
#import <stdlib.h>  // EXIT_*
#import <unistd.h>  // sleep

#define THREAD_COUNT (5)
pthread_t thread[THREAD_COUNT];

static void *log_and_die(void *);

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

    for (uintptr_t i = 0; i < THREAD_COUNT; ++i) {
        void *result = NULL;
        int err = pthread_join(thread[i], &result);
        if (err) perror("pthread_join");
        else fprintf(stderr, "Joined with thread %lu: %p -> %p.\n",
                     (unsigned long)i, (void *)thread[i], result);
    }
    return EXIT_SUCCESS;
}

void *
log_and_die(void *threadnum) {
    fprintf(stderr, "%p: Thread %lu reporting for duty!\n",
            (void *)pthread_self(), (unsigned long)threadnum);
    sleep((random() >> 8) % 5);
    // Can't return the address of any local variable -
    // our stack will be gone after this!
    return thread[(uintptr_t)threadnum];
}

// vi: set ts=4 sw=4 et filetype=objc syntax=objc:
