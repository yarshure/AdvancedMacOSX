// mutex_errorcheck_exercise.m - Use mutex attributes, see deadlock avoided.
//clang -g -std=c99 -Wall -Wextra mutex_errorcheck_exercise.m -o mutex_errorcheck_exercise
/*
NOTE: You are advised to always use a mutexattr to set the mutex type.
The default mutex type could be any type, and it might not be the one you want.
Also, check the return values of all pthreads calls - if you ignored them here,
you'd be ignoring the fact that you did NOT acquire the mutexes you thought you had.
*/

#import <pthread.h> // pthread_*
#import <stdio.h>   // fprintf
#import <stdlib.h>  // EXIT_*
#import <string.h>  // strerror

int
main(void) {
    pthread_mutexattr_t attr;
    int err = pthread_mutexattr_init(&attr);
    if (err) {
        fprintf(stderr, "pthread_mutexattr_init: %s\n", strerror(err));
        return EXIT_FAILURE;
    }

    err = pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_ERRORCHECK);
    if (err) {
        fprintf(stderr, "pthread_mutexattr_settype: %s\n", strerror(err));
        return EXIT_FAILURE;
    }

    pthread_mutex_t m;
    err = pthread_mutex_init(&m, &attr);
    if (err) {
        fprintf(stderr, "pthread_mutex_init: %s\n", strerror(err));
        return EXIT_FAILURE;
    }

    err = pthread_mutexattr_destroy(&attr);
    if (err) {
        fprintf(stderr, "pthread_mutexattr_destroy: %s\n", strerror(err));
        return EXIT_FAILURE;
    }

    err = pthread_mutex_lock(&m);
    if (err) {
        // YOU DO NOT HAVE THE MUTEX!
        // At least not twice, you don't.
        fprintf(stderr, "pthread_mutex_lock: %s\n", strerror(err));
        return EXIT_FAILURE;
    }

    err = pthread_mutex_lock(&m);
    if (err) {
        fprintf(stderr, "pthread_mutex_lock: %s\n", strerror(err));
        return EXIT_FAILURE;
    }

    fprintf(stderr, "All's well what ends well.\n");

    err = pthread_mutex_unlock(&m);
    if (err) {
        fprintf(stderr, "pthread_mutex_unlock: %s\n", strerror(err));
        return EXIT_FAILURE;
    }

    err = pthread_mutex_unlock(&m);
    if (err) {
        fprintf(stderr, "pthread_mutex_unlock: %s\n", strerror(err));
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}

// vi: set ts=4 sw=4 et filetype=objc syntax=objc:
