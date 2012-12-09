// mutex.m -- basic thread creation, with mutexes!

// clang -g -Weverything -o mutex mutex.m

#import <pthread.h>     // for pthread_* calls
#import <stdio.h>       // for printf
#import <stdlib.h>      // for exit
#import <string.h>      // for strerror()
#import <unistd.h>      // for usleep()

#define THREAD_COUNT 6

// information to tell the thread how to behave

typedef struct ThreadInfo {
    pthread_t    threadID;
    unsigned int index;
    unsigned int numberToCountTo;
    unsigned int detachYourself;
    useconds_t   sleepTime;      // in microseconds (1/100,000,000)
} ThreadInfo;

pthread_mutex_t g_mutex = PTHREAD_MUTEX_INITIALIZER;

static void *threadFunction (void *argument) {
    ThreadInfo *info = (ThreadInfo *) argument;

    printf ("thread %d, counting to %d, detaching %s\n",
            info->index, info->numberToCountTo, 
            (info->detachYourself) ? "yes" : "no");

    if (info->detachYourself) {
        int result = pthread_detach (pthread_self());
        if (result != 0) {
            fprintf (stderr, "could not detach thread %d. Error: %d/%s\n",
                     info->index, result, strerror(result));
        }
    }

    // now to do the actual "work" of the thread
    pthread_mutex_lock (&g_mutex);

    for (unsigned int i = 0; i < info->numberToCountTo; i++) {
        printf ("  thread %d counting %d\n", info->index, i);
        usleep (info->sleepTime);
    }
    pthread_mutex_unlock (&g_mutex);

    printf ("thread %d done\n", info->index);

    return NULL;

} // threadFunction


int main (void) {
    ThreadInfo threads[THREAD_COUNT];
    int result;

    // initialize the ThreadInfos:
    for (unsigned int i = 0; i < THREAD_COUNT; i++) {
        threads[i].index = i;
        threads[i].numberToCountTo = (i + 1) * 2;
        threads[i].detachYourself = (i % 2); // detach odd threads
        threads[i].sleepTime = 500000 + 200000 * i;
        // (make subsequent threads wait longer between counts)
    }

    // create the threads
    for (unsigned int i = 0; i < THREAD_COUNT; i++) {
        result = pthread_create (&threads[i].threadID, NULL, 
                                 threadFunction, &threads[i]);
        if (result != 0) {
            fprintf (stderr, 
                     "could not pthread_create thread %d.  Error: %d/%s\n",
                     i, result, strerror(result));
            exit (EXIT_FAILURE);
        }
    }

    // now rendezvous with all the non-detached threads
    for (unsigned int i = 0; i < THREAD_COUNT; i++) {
        void *retVal;
        if (!threads[i].detachYourself) {
            result = pthread_join (threads[i].threadID, &retVal);
            if (result != 0) {
                fprintf (stderr, "error joining thread %d.  Error: %d/%s\n",
                         i, result, strerror(result));
            }
            printf ("joined with thread %d\n", i);
        }
    }

    return EXIT_SUCCESS;

} // main

