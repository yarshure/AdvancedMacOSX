// pipeline.m -- manually create a pipeline to run the command
//     grep -i mail /usr/share/dict/words | tr '[:lower:]' '[:upper:]'
/* compile with
gcc -std=c99 -g -Wall -Wextra -o pipeline pipeline.m
 */

#import <errno.h>     // errno
#import <stdbool.h>   // bool
#import <stdio.h>     // printf(), perror()
#import <stdlib.h>    // EXIT_SUCCESS, pipe(), exec()
#import <unistd.h>    // fork()
#import <sys/wait.h>  // waitpid()

#define BUFSIZE 4096
enum {READ, WRITE};

// The plumbing implemented is:
// grep -(grep_pipe)-> tr -(tr_pipe)-> parent
int main(void) {
    /* grep */
    // grep writes, tr reads
    int grep_pipe[2];
    int err = pipe(grep_pipe);
    if (err) {
        perror("pipe(grep)");
        exit(EXIT_FAILURE);
    }

    pid_t grep = fork();
    if (-1 == grep) {
        perror("fork(grep)");
        exit(EXIT_FAILURE);
    }

    bool is_child = (0 == grep);
    if (is_child) {
        // grep writes grep_pipe
        (void)close(grep_pipe[READ]);
        int fd = dup2(grep_pipe[WRITE], STDOUT_FILENO);
        if (-1 == fd) {
            perror("dup2(grep)");
            _exit(EXIT_FAILURE);
        }
        (void)close(grep_pipe[WRITE]);
        // STDOUT_FILENO remains open

        // exec grep
        char *argv[] = {"grep", "-i", "mail",
                        "/usr/share/dict/words", NULL};
        int err = execvp("grep", argv);
        if (err) {
            perror("exec(grep)");
            _exit(EXIT_FAILURE);
        }
    }
    // neither parent nor tr write to grep_pipe
    (void)close(grep_pipe[WRITE]);

    /* tr */
    // tr writes, parent reads
    int tr_pipe[2];
    err = pipe(tr_pipe);
    if (err) {
        perror("pipe(tr)");
        exit(EXIT_FAILURE);
    }

    pid_t tr = fork();
    if (-1 == tr) {
        perror("fork(tr)");
        exit(EXIT_FAILURE);
    }

    is_child = (0 == tr);
    if (is_child) {
        // tr reads grep_pipe
        int fd = dup2(grep_pipe[READ], STDIN_FILENO);
        if (-1 == fd) {
            perror("dup2(tr stdin)");
            _exit(EXIT_FAILURE);
        }
        close(grep_pipe[READ]);

        // tr writes tr_pipe
        (void)close(tr_pipe[READ]);
        fd = dup2(tr_pipe[WRITE], STDOUT_FILENO);
        if (-1 == fd) {
            perror("dup2(tr stdout)");
            _exit(EXIT_FAILURE);
        }
        close(tr_pipe[WRITE]);

        // exec tr
        int err = execlp("tr", "tr", "[:lower:]",
                         "[:upper:]", NULL);
        if (err) {
            perror("exec(tr)");
            _exit(EXIT_FAILURE);
        }
    }
    // tr writes, parent reads
    (void)close(tr_pipe[WRITE]);

    /* output */
    FILE *tr_output = fdopen(tr_pipe[READ], "r");
    if (!tr_output) {
        perror("fdopen");
        exit(EXIT_FAILURE);
    }

    char buffer[BUFSIZE];
    while (fgets(buffer, BUFSIZE, tr_output))
        printf("%s", buffer);

    if (ferror(tr_output))
        perror("fgets(tr_output)");

    /* cleanup */
    int st;
    (void)waitpid(grep, &st, 0);
    (void)waitpid(tr, &st, 0);

    return EXIT_SUCCESS;
} // main
