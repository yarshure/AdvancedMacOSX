// basics.m -- basic thread creation

/* compile with
cc -g -Wmost -o basics basics.m
*/

#import <stdio.h>	// for printf
#import <pthread.h>	// for pthread_* calls
#import <string.h>	// for strerror()
#import <unistd.h>	// for usleep()
#import <stdlib.h>	// for exit

#define THREAD_COUNT 6

// information to tell the thread how to behave

typedef struct ThreadInfo {
    pthread_t	threadID;
    int		index;
    int		numberToCountTo;
    int		detachYourself;
    int		sleepTime;	// in microseconds (1/100,000,000)
} ThreadInfo;


void *threadFunction (void *argument)
{
    ThreadInfo *info = (ThreadInfo *) argument;
    int result, i;

    printf ("thread %d, counting to %d, detaching %s\n",
	    info->index, info->numberToCountTo, 
	    (info->detachYourself) ? "yes" : "no");

    if (info->detachYourself) {
	result = pthread_detach (pthread_self());
	if (result != 0) {
	    fprintf (stderr, "could not detach thread %d. Error: %d/%s\n",
		     info->index, result, strerror(result));
	}
    }

    // now to do the actual "work" of the thread

    for (i = 0; i < info->numberToCountTo; i++) {
	printf ("  thread %d counting %d\n", info->index, i);
	usleep (info->sleepTime);
    }

    printf ("thread %d done\n", info->index);

    return (NULL);

} // threadFunction


int main (int argc, char *argv[])
{
    ThreadInfo threads[THREAD_COUNT];
    int result, i;

    // initialize the ThreadInfos:
    for (i = 0; i < THREAD_COUNT; i++) {
	threads[i].index = i;
	threads[i].numberToCountTo = (i + 1) * 2;
	threads[i].detachYourself = (i % 2); // detach odd threads
	threads[i].sleepTime = 500000 + 200000 * i;
	// (make subseuqent threads wait longer between counts)
    }

    // create the threads
    for (i = 0; i < THREAD_COUNT; i++) {
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
    for (i = 0; i < THREAD_COUNT; i++) {
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

    exit (EXIT_SUCCESS);

} // main

