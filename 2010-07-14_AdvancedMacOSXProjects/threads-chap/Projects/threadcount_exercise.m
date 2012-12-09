// threadcount_exercise.m - exit() from main with threads
//clang -g -std=c99 -Wall -Wextra threadcount_exercise.m -o threadcount_exercise

#import <pthread.h> // pthread_*
#import <stdbool.h> // true/false
#import <stdio.h>   // fprintf
#import <stdlib.h>  // EXIT_*
#import <string.h>  // strerror
#import <unistd.h>  // sleep

#define THREAD_COUNT (5)
pthread_t thread[THREAD_COUNT];
static int gThreadCount;
static pthread_cond_t gThreadCountCond = PTHREAD_COND_INITIALIZER;
static pthread_mutex_t gThreadCountMutex = PTHREAD_MUTEX_INITIALIZER;

static void *log_and_die(void *);
static void log_msg(void *msg_addr);
static void log_exit(void);

int
main(void) {
    int err = pthread_mutex_lock(&gThreadCountMutex);
    if (err) {
        fprintf(stderr, "*** Can't lock mutex: %s\n",
                strerror(err));
        return EXIT_FAILURE;
    }

    gThreadCount = 0;
    // uintptr_t is the same size as a pointer.
    for (uintptr_t i = 0; i < THREAD_COUNT; ++i) {
        int err = pthread_create(&thread[i],
                                 NULL/*attr*/,
                                 log_and_die,
                                 (void *)i);
        if (err) perror("pthread_create");
        else {
            fprintf(stderr, "Created thread %lu: %p.\n",
                    (unsigned long)i, (void *)thread[i]);
            ++gThreadCount;
        }
    }

    while (gThreadCount > 0) {
        int err = pthread_cond_wait(&gThreadCountCond, &gThreadCountMutex);
        if (err) {
            char buf[64];
            buf[0] = '\0';
            strerror_r(err, buf, sizeof(buf));
            fprintf(stderr, "*** Can't cond_wait mutex: %s\n", buf);
        } 
    }

    err = pthread_mutex_unlock(&gThreadCountMutex);
    if (err) {
        char buf[64];
        buf[0] = '\0';
        strerror_r(err, buf, sizeof(buf));
        fprintf(stderr, "*** Can't lock mutex: %s\n", buf);
        return EXIT_FAILURE;
    }

    // push/pop are macros and have to be used in matched pairs.
    // Otherwise, you end up with an unclosed brace
    // and useless warnings about nested functions.
    pthread_cleanup_push(&log_msg, "(Main thread exited.)");
    atexit(log_exit);

    // Notice that exit() triggers the atexit-handler
    // but not the cleanup function.
    fprintf(stderr, "Main thread exiting!\n");
    pthread_exit(EXIT_SUCCESS);
    pthread_cleanup_pop(true);
    // Return acts like exit() in the main thread
    // and like pthread_exit() in all other threads.
    return EXIT_SUCCESS;
}

void *
log_and_die(void *threadnum) {
    fprintf(stderr, "%p: Thread %lu reporting for duty!\n",
            (void *)pthread_self(), (unsigned long)threadnum);
    sleep((random() >> 8) % 5);

    (void)pthread_mutex_lock(&gThreadCountMutex);
    --gThreadCount;
    (void)pthread_cond_signal(&gThreadCountCond);
    (void)pthread_mutex_unlock(&gThreadCountMutex);

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
