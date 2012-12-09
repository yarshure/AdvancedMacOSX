// status.m -- play with various child exiting status values

/* compile with
gcc -std=c99 -g -Wall -Wextra -o status status.m
*/

#import <errno.h>     // errno
#import <stdbool.h>   // true/false
#import <stdio.h>     // printf(), perror()
#import <stdlib.h>    // EXIT_SUCCESS
#import <string.h>    // strsignal()
#import <unistd.h>    // fork(), pid_t
#import <sys/wait.h>  // wait()

typedef void (*child_func)(void);
void fork_and(child_func f);
void reap_child(void);

void print_status(pid_t pid, int status) {
    printf("Child %lu ", (unsigned long)pid);
    if (WIFEXITED(status))
        printf("exited normally with status %d.\n",
               (int)WEXITSTATUS(status));

    else if (WIFSIGNALED(status))
        printf("exited due to signal: %s%s.\n",
               strsignal(WTERMSIG(status)),
               WCOREDUMP(status)? " (core dumped)" : "");

    else if (WIFSTOPPED(status))
        printf("stopped due to signal %s.\n",
               strsignal(WTERMSIG(status)));

    else printf("yielded uninterpretable status 0x%X.\n",
                status);
}

void exit_normally(void) {
    _exit(23);
}

void die_by_signal(void) {
    abort();  // raises SIGABRT
}

void die_by_crash(void) {
    bool *is_dead = NULL;
    *is_dead = true;
}

void drop_core(void) {
    // Increase the CORE resource limit.
    struct rlimit rl;
    rl.rlim_cur = RLIM_INFINITY;
    rl.rlim_max = RLIM_INFINITY;

    int err = setrlimit(RLIMIT_CORE, &rl);
    if (err)
        perror("setrlimit(RLIMIT_CORE)");

    abort();  // raises SIGABRT
}

int main(void) {
    fork_and(exit_normally);
    fork_and(die_by_signal);
    fork_and(die_by_crash);
    fork_and(drop_core);
    return EXIT_SUCCESS;
}

void fork_and(child_func f) {
    pid_t child = fork();
    if (-1 == child) {
        perror("fork");
        exit(EXIT_FAILURE);
    }

    bool is_child = (0 == child);
    if (is_child) {
        (*f)();
        return;
    }

    reap_child();
}

void reap_child(void) {
    int status = 0;
    pid_t child = wait(&status);
    if (-1 == child) {
        perror("wait");
        exit(EXIT_FAILURE);
    }

    print_status(child, status);
}
