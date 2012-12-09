// deadly_embrace_exercise.m - Observe a deadly embrace.
//clang -g -std=c99 -Wall -Wextra deadly_embrace_exercise.m -o deadly_embrace_exercise

#import <pthread.h> // pthread_*
#import <stdio.h>   // fprintf
#import <stdlib.h>  // EXIT_*
#import <unistd.h>  // sleep

static pthread_mutex_t m1 = PTHREAD_MUTEX_INITIALIZER;
static pthread_mutex_t m2 = PTHREAD_MUTEX_INITIALIZER;

static void *lets_hug(void *);

int
main(void) {
    pthread_mutex_lock(&m1);
    pthread_t other;
    int err = pthread_create(&other, NULL, lets_hug, NULL);
    if (err) perror("pthread_create");

    sleep(1);
    err = pthread_mutex_lock(&m2);
    if (err) perror("pthread_mutex_lock");
    fprintf(stderr, "Not gonna see this.\n");

    err = pthread_mutex_unlock(&m2);
    if (err) perror("pthread_mutex_unlock");
    err = pthread_mutex_unlock(&m1);
    if (err) perror("pthread_mutex_unlock");
    return EXIT_SUCCESS;
}

void *
lets_hug(void *unused __attribute__((__unused__))) {
    int err = pthread_mutex_lock(&m2);
    if (err) perror("pthread_mutex_lock");
    err = pthread_mutex_lock(&m1);
    if (err) perror("pthread_mutex_lock");
    fprintf(stderr, "Not gonna see this.\n");
    err = pthread_mutex_unlock(&m1);
    if (err) perror("pthread_mutex_unlock");
    err = pthread_mutex_unlock(&m2);
    if (err) perror("pthread_mutex_unlock");
    return NULL;
}

// vi: set ts=4 sw=4 et filetype=objc syntax=objc:
