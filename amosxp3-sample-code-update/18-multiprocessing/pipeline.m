// pipeline.m -- manually create a pipeline to run the command
//               grep -i mail /usr/share/dict/words | tr '[:lower:]' '[:upper:]'

// clang -g -Weverything -o pipeline pipeline.m

#import <sys/types.h>   // for pid_t
#import <sys/wait.h>    // for waitpid
#import <unistd.h>      // for fork
#import <stdlib.h>      // for EXIT_SUCCESS, pipe, exec
#import <stdio.h>       // for printf
#import <errno.h>       // for errno
#import <string.h>      // for strerror

#define BUFSIZE 4096

int main (void) {
    int status = EXIT_FAILURE;
    
    int pipeline1[2];    // write on 1, read on zero    
    int result = pipe (pipeline1);

    if (result == -1) {
        fprintf (stderr, "could not open pipe 1\n");
        goto bailout;
    }

    // start the grep
    
    pid_t grep_pid = 0;
    if ((grep_pid = fork())) {
        // parent

        if (grep_pid == -1) {
            fprintf (stderr, "fork failed.  Error is %d/%s\n",
                     errno, strerror(errno));
            goto bailout;
        }
        close (pipeline1[1]); // we're not planning on writing

    } else {
        // child

        char *arguments[] = { "grep", "-i", "mail", "/usr/share/dict/words", NULL };

        close (pipeline1[0]); // we're not planning on reading
                                     
        // set the standard out to be the write-side of the pipeline1
                                     
        result = dup2 (pipeline1[1], STDOUT_FILENO);
        if (result == -1) {
            fprintf (stderr, "dup2 failed.  Error is %d/%s\n",
                     errno, strerror(errno));
            goto bailout;
        }
        // The file is open on STDOUT_FILENO, so we don't need this fd anymore.
        close (pipeline1[1]);

        // exec the child
        result = execvp ("grep", arguments);
        if (result == -1) {
            fprintf (stderr, "could not exec grep.  Error is %d/%s\n",
                     errno, strerror(errno));
            goto bailout;
        }
    }

    // start the tr
    
    int pipeline2[2];
    result = pipe (pipeline2);
    if (result == -1) {
        fprintf (stderr, "could not open pipe\n");
        goto bailout;
    }

    pid_t tr_pid = 0;
    if ((tr_pid = fork())) {
        // parent

        if (tr_pid == -1) {
            fprintf (stderr, "fork failed.  Error is %d/%s\n",
                     errno, strerror(errno));
            goto bailout;
        }
        close (pipeline2[1]); // we're not planning on writing

    } else {
        // child

        close (pipeline2[0]); // we're not planning on reading
                                     
        // set the standard out to be the write-side of the pipeline2
                                     
        result = dup2 (pipeline1[0], STDIN_FILENO);
        if (result == -1) {
            fprintf (stderr, "dup2 failed.  Error is %d/%s\n",
                     errno, strerror(errno));
            goto bailout;
        }
        close (pipeline1[1]);

        result = dup2 (pipeline2[1], STDOUT_FILENO);
        if (result == -1) {
            fprintf (stderr, "dup2 failed.  Error is %d/%s\n",
                     errno, strerror(errno));
            goto bailout;
        }
        close (pipeline2[1]);

        // exec the child

        result = execlp ("tr", "tr", "[:lower:]", "[:upper:]", NULL);
        if (result == -1) {
            fprintf (stderr, "could not exec tr.  Error is %d/%s\n",
                     errno, strerror(errno));
            goto bailout;
        }
    }


    // this is only in the parent.  read the results
    FILE *blarg;
    char buffer[BUFSIZE];
    
    blarg = fdopen (pipeline2[0], "r");
    
    while (fgets(buffer, BUFSIZE, blarg)) {
        printf ("%s", buffer);
    }

    // and wait
    int childStatus;
    waitpid (grep_pid, &childStatus, 0);
    waitpid (tr_pid, &childStatus, 0);
    
    // whew!  All done.

    status = EXIT_SUCCESS;

bailout:

    return (status);

} // main
