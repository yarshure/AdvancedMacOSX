// fibo_exercise.m - Producer-consumer problem and C-with-Objects.
//gcc -g -std=c99 -fnested-functions -Wall -Wextra fibo_exercise.m -o fibo_exercise

#import <pthread.h> // pthread_*
#import <stdbool.h> // true/false
#import <stdio.h>   // fprintf(stderr, 
#import <stdlib.h>  // EXIT_*
#import <stdint.h>  // int_*
#import <unistd.h>  // sleep

//#define SLOW_PRODUCTION
//#define SLOW_CONSUMPTION

// There appear to be some issues with logging
// around a blocked pop. The previous value
// gets logged twice; logging item changes
// shows that the double-logged one
// was not newly extracted, but has something to do
// with the logging itself.
//#define LOG_ITEM_COUNT_CHANGES

// Intentionally low, so that we block more often.
#define QUEUE_ITEM_COUNT ((size_t)5LU)
typedef struct Queue {
    pthread_mutex_t fMutex;
    pthread_cond_t fCanPush;
    pthread_cond_t fCanPop;
    volatile size_t fItemCount;
    volatile uintmax_t fItems[QUEUE_ITEM_COUNT];
} Queue;

__attribute__((__nonnull__))
bool QueueInit(Queue *);
void QueueDispose(Queue *);

/* Push and Pop will block till they succeed. */
__attribute__((__nonnull__))
void QueuePushBack(Queue *, uintmax_t);

__attribute__((__nonnull__))
void QueuePopFront(Queue *, uintmax_t *);


void *ProduceFor(void *);
void *ConsumeFrom(void *);

int
main(void) {
    Queue queue;
    QueueInit(&queue);

    pthread_t other;
    int err = pthread_create(&other, NULL, ConsumeFrom, &queue);
    if (err) {
        fprintf(stderr, "pthread_create");
        return EXIT_FAILURE;
    }

    ProduceFor(&queue);

    QueueDispose(&queue);
    return EXIT_SUCCESS;
}

void *
ProduceFor(void *q) {
    Queue *queue = q; 
    uint_least8_t i = 0;
    uintmax_t f[2] = {1U, 1U};
    QueuePushBack(queue, f[i]);
    for (;;) {
        i = (i + 1) % 2;
        f[i] = f[0] + f[1];
        QueuePushBack(q, f[i]);
        fprintf(stderr, "pushed --> %ju\n", f[i]);
        #ifdef SLOW_PRODUCTION
        sleep((random() >> 8) % 5);
        #endif
    }
}

void *
ConsumeFrom(void *q) {
    Queue *queue = q;
    uintmax_t f = 0;
    for (;;) {
        QueuePopFront(queue, &f);
        fprintf(stderr, "           %ju --> popped\n", f);
        #ifdef SLOW_CONSUMPTION
        sleep((random() >> 8) % 5);
        #endif
    }
}

bool
QueueInit(Queue *q) {
    q->fMutex = (pthread_mutex_t)PTHREAD_MUTEX_INITIALIZER;
    q->fCanPush = q->fCanPop = (pthread_cond_t)PTHREAD_COND_INITIALIZER;
    q->fItemCount = 0UL;
    return true;
}

void
QueueDispose(Queue *q) {
    int err = pthread_mutex_destroy(&q->fMutex);
    if (err) fprintf(stderr, "pthread_mutex_destroy");

    err = pthread_cond_destroy(&q->fCanPush);
    if (err) fprintf(stderr, "pthread_cond_destroy");

    err = pthread_cond_destroy(&q->fCanPop);
    if (err) fprintf(stderr, "pthread_cond_destroy");

    q->fItemCount = 0UL;
}

// Clang doesn't support -fnested-functions,
// but it does support blocks. Go figure.
#if __clang__
typedef void (^QueueWhileLockedFunc)(void);
#else
typedef void (*QueueWhileLockedFunc)(void);
#endif

__attribute__((__nonnull__))
void QueueWhileLocked(Queue *, QueueWhileLockedFunc);

void
QueueWhileLocked(Queue *q, QueueWhileLockedFunc work) {
    int err = pthread_mutex_lock(&q->fMutex);
    if (err) {
        fprintf(stderr, "pthread_mutex_lock");
        return;
    }

    work();
    
    err = pthread_mutex_unlock(&q->fMutex);
    if (err) {
        fprintf(stderr, "pthread_mutex_unlock");
        return;
    }
}

/* Call the Locked variants ONLY while holding the lock. */
__inline
__attribute__((__nonnull__))
bool QueueCanPushLocked(Queue *);

__inline
__attribute__((__nonnull__))
bool QueueCanPopLocked(Queue *);

bool
QueueCanPushLocked(Queue *q) {
    //fprintf(stderr, "%s: %zu / %zu\n", __func__, q->fItemCount, QUEUE_ITEM_COUNT);
    return (q->fItemCount < QUEUE_ITEM_COUNT);
}

void
QueuePushBack(Queue *q, uintmax_t item) {
    #if __clang__
    QueueWhileLockedFunc push_it = ^{
    #else
    void push_it(void) {
    #endif
        while (!QueueCanPushLocked(q)) {
            fprintf(stderr, "Can't push, waiting.\n");
            int err = pthread_cond_wait(&q->fCanPush, &q->fMutex);
            if (err) fprintf(stderr, "pthread_cond_wait");
            return;
        }

        #ifdef LOG_ITEM_COUNT_CHANGES
        fprintf(stderr, "(%zu++)\n", q->fItemCount);
        #endif
        q->fItems[q->fItemCount++] = item;
        sleep(1);
        int err = pthread_cond_signal(&q->fCanPop);
        if (err) fprintf(stderr, "pthread_cond_signal");
    };

    // Pass in a nested function.
    // Okay because it does not outlive its scope.
    QueueWhileLocked(q, push_it);
}

bool
QueueCanPopLocked(Queue *q) {
    //fprintf(stderr, "%s: %zu / %zu\n", __func__, q->fItemCount, QUEUE_ITEM_COUNT);
    return (q->fItemCount > 0U);
}

void
QueuePopFront(Queue *q, uintmax_t *item) {
    #if __clang__
    QueueWhileLockedFunc pop_it = ^{
    #else
    void pop_it(void) {
    #endif
        while (!QueueCanPopLocked(q)) {
            fprintf(stderr, "Can't pop, waiting.\n");
            int err = pthread_cond_wait(&q->fCanPop, &q->fMutex);
            if (err) fprintf(stderr, "pthread_cond_wait");
            return;
        }

        #ifdef LOG_ITEM_COUNT_CHANGES
        fprintf(stderr, "(--%zu)\n", q->fItemCount);
        #endif
        *item = q->fItems[--(q->fItemCount)];
        int err = pthread_cond_signal(&q->fCanPush);
        if (err) fprintf(stderr, "pthread_cond_signal");
    };

    // Pass in a nested function.
    // Okay because it does not outlive its scope.
    QueueWhileLocked(q, pop_it);
}

// vi: set ts=4 sw=4 et filetype=objc syntax=objc:
