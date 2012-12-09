// tls_exercise.m - Use thread-local storage.
//clang -g -std=c99 -Wall -Wextra tls_exercise.m -o tls_exercise
/*
If nothing happens, then it works.
*/

#import <pthread.h> // pthread_*
#import <stdio.h>   // perror
#import <stdlib.h>  // EXIT_*

pthread_key_t sThreadIDKey;
void *store_it(void *);

int
main(void) {
    int err = pthread_key_create(&sThreadIDKey, NULL/*destructor*/);
    if (err) {
        perror("pthread_key_create");
        return EXIT_FAILURE;
    }
    pthread_t other;
    pthread_create(&other, NULL, store_it, NULL);
    (void)store_it(NULL);
    pthread_exit(NULL);
}

void *
store_it(void *unused __attribute__((__unused__))) {
    int err = pthread_setspecific(sThreadIDKey, (void *)pthread_self());
    if (err) perror("pthread_key_create");
    pthread_exit(NULL);
}

// vi: set ts=4 sw=4 et filetype=objc syntax=objc:
