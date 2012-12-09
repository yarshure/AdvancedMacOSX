// webserve.m -- a very simple web server using fork() to handle requests

// clang -g -Weverything -Wno-unused-parameter  -o webserve webserve.m

#import <arpa/inet.h>       // for inet_ntoa
#import <arpa/inet.h>       // for inet_ntoa and friends
#import <assert.h>          // for assert
#import <errno.h>           // for errno
#import <netinet/in.h>      // for sockaddr_in
#import <signal.h>	    // for signterrupt()
#import <stdio.h>           // for printf
#import <stdlib.h>          // for EXIT_SUCCESS, pipe, exec
#import <string.h>          // for strerror
#import <sys/resource.h>    // for struct rusage
#import <sys/socket.h>      // for socket(), AF_INET
#import <sys/time.h>        // for struct timeval
#import <sys/types.h>       // for pid_t, amongst others
#import <sys/wait.h>        // for wait3
#import <unistd.h>          // for close
#import <unistd.h>          // for fork

#define PORT_NUMBER 8080    // set to 80 to listen on the HTTP port

#define MAX(x,y) ((x) > (y) ? (x) : (y))
#define MIN(x,y) ((x) < (y) ? (x) : (y))

static int g_childSignaled;


// ----- child handling

// signal handler for SIGCHLD.  Just set a global value saying we've
// seen the signal.  We want to do more interesting stuff on child
// exits than are proper to do in a signal handler (runs in the
// parent)x

static void childExited (int signalNumber) {
    g_childSignaled = 1;

} // childExited


// wait for children and print out some resource usage (runs in the parent)

static void reapChildren () {
    while (1) {
        pid_t childPid;
        int status;
        struct rusage resources;

        childPid = wait3 (&status, WNOHANG, &resources);

        if (childPid < 0) {
            // even though the man page says that we shouldn't get
            // this with WNOHANG as an option to wait3, it sometimes
            // happens
            if (errno != ECHILD) {
                fprintf (stderr, "wait3 returned an error: %d/%s\n",
                         errno, strerror(errno));
            }
            break;

        } else if (childPid == 0) {
            // we've run out of children
            break;

        } else {
            // otherwise print some stuff to our log

            fprintf (stderr, "child %ld terminated %s\n",
                     (long)childPid, 
                     WIFEXITED(status) ? "normally" : "abnormally");
            fprintf (stderr, "    user time: %d seconds %d msec\n",
                     (int)resources.ru_utime.tv_sec, 
                     (int)resources.ru_utime.tv_usec);
            fprintf (stderr, "    system time: %d seconds %d msec\n",
                     (int)resources.ru_stime.tv_sec, 
                     (int)resources.ru_stime.tv_usec);
            fprintf (stderr, "    max RSS: %ld\n", resources.ru_maxrss);
        }
    }

    return;

} // reapChildren



// HTTP request handling

// these are some of the common HTTP response codes

#define HTTP_OK         200
#define HTTP_NOT_FOUND  404
#define HTTP_ERROR      500


// return a string to the browser

#define returnString(httpResult, string, channel) \
   returnBuffer((httpResult), (string), (strlen(string)), (channel))

// return a character buffer (not necessarily zero-terminated) to the
// browser (runs in the child)

static void returnBuffer (int httpResult, const char *content, 
                          size_t contentLength, FILE *commChannel)
{
    fprintf (commChannel, "HTTP/1.0 %d blah\r\n", httpResult);
    fprintf (commChannel, "Content-Type: text/html\r\n");
    fprintf (commChannel, "Content-Length: %zd\r\n", contentLength);
    fprintf (commChannel, "\r\n");

    fwrite (content, contentLength, 1, commChannel);

} // returnBuffer


// stream back to the browser numbers being counted, with a pause
// between them.  The user should see the numbers appear every couple
// of seconds (runs in the child)

static void returnNumbers (int number, FILE *commChannel) {
    int min, max;
    min = MIN (number, 1);
    max = MAX (number, 1);
    
    fprintf (commChannel, "HTTP/1.0 %d OK\r\n", HTTP_OK);
    fprintf (commChannel, "Content-Type: text/html\r\n");
    fprintf (commChannel, "\r\n"); // no content length, dynamic

    fprintf (commChannel, "<h2>The numbers from %d to %d</h2>\n", 
             min, max);

    // Blort out enough stuff so that the browser will start processing stuff
    // and actually display the numbers being updated.
    char spaces[2048];
    memset (spaces, ' ', sizeof(spaces));
    fprintf (commChannel, "%s\n", spaces);

    for (int i = min; i <= max; i++) {
        sleep (2);
        fprintf (commChannel, "%d\n", i);
        fflush (commChannel);
    }

    fprintf (commChannel, "<hr>Done\n");

} // returnNumbers


// return a file from the file system, relative to where the webserve
// is running.  Note that this doesn't look for any nasty characters
// like '..', so this function is a pretty big security hole
// (runs in the child)

static void returnFile (const char *filename, FILE *commChannel) {
    const char *mimetype = NULL;

    // try to guess the mime type.  IE assumes all non-graphic files
    // are HTML
    if (strstr(filename, ".m") != NULL) {
        mimetype = "text/plain";
    } else if (strstr(filename, ".txt") != NULL) {
        mimetype = "text/plain";
    } else if (strstr(filename, ".tgz") != NULL) {
        mimetype = "application/x-compressed";
    } else if (strstr(filename, ".html") != NULL) {
        mimetype = "text/html";
    } else if (strstr(filename, ".htm") != NULL) {
        mimetype = "text/html";
    } else if (strstr(filename, ".h") != NULL) {
        mimetype = "text/plain";
    } else if (strstr(filename, ".mp3") != NULL) {
        mimetype = "audio/mpeg";
    }

    FILE *file;
    file = fopen (filename, "r");

    if (file == NULL) {
        returnString (HTTP_NOT_FOUND, 
                      "could not find your file.  Sorry\n.", 
                      commChannel);
    } else {
        fprintf (commChannel, "HTTP/1.0 %d blah\r\n", HTTP_OK);
        if (mimetype != NULL) {
            fprintf (commChannel, "Content-Type: %s\r\n", mimetype);
        }
        fprintf (commChannel, "\r\n");

#define BUFFER_SIZE (8 * 1024)
        char *buffer[BUFFER_SIZE];
        size_t result;

        while ((result = fread (buffer, 1, BUFFER_SIZE, file)) > 0) {
            fwrite (buffer, 1, result, commChannel);
        }
#undef BUFFER_SIZE
    }

} // returnFile


// using the method and the request (the path part of the url),
// generate the data for the user and send it back. (runs in the
// child)

static void handleRequest (const char *method, 
                           const char *originalRequest, FILE *commChannel) {
    char *request = strdup (originalRequest);

    // we'll use strsep to split this
    if (strcmp(method, "GET") != 0) {
        returnString (HTTP_ERROR, 
                      "only GETs are supported", commChannel);
        goto bailout;
    }
    
    char *chunk, *nextString;
    nextString = request;

    chunk = strsep (&nextString, "/");
    // urls start with slashes, so chunk is ""

    chunk = strsep (&nextString, "/");  // the leading part of the url

    if (strcmp(chunk, "numbers") == 0) {
        int number;

        // url of the form /numbers/5 to print numbers from 1 to 5
        chunk = strsep (&nextString, "/");
        number = atoi(chunk);
        returnNumbers (number, commChannel);

    } else if (strcmp(chunk, "file") == 0) {
        chunk = strsep (&nextString, ""); // get the rest of the string
        returnFile (chunk, commChannel);
    } else {
        returnString (HTTP_NOT_FOUND, 
                      "could not handle your request.  Sorry\n.",
                      commChannel);
    }

bailout:
    fprintf (stderr, "child %ld handled request '%s'\n", 
             (long)getpid(), originalRequest);

    free (request);

} // handleRequest



// read the request from the browser, pull apart the elements of the
// request, and then dispatch it.  (runs in the child)

__attribute__((noreturn))
static void dispatchRequest (int fd, struct sockaddr_in *address) {
#define LINEBUFFER_SIZE 8192
    char linebuffer[LINEBUFFER_SIZE];
    FILE *commChannel;

    commChannel = fdopen (fd, "r+");
    if (commChannel == NULL) {
        fprintf (stderr, 
                 "could not open commChannel.  Error is %d/%s\n",
                 errno, strerror(errno));
    }

    // this is pretty lame in that it only reads the first line and 
    // assumes that's the request, subsequently ignoring any headers
    // that might be sent.

    if (fgets(linebuffer, LINEBUFFER_SIZE, commChannel) != NULL) {
        // ok, now figure out what they wanted
        char *requestElements[3], *nextString, *chunk;
        int i = 0;
        nextString = linebuffer;
        while ((chunk = strsep (&nextString, " "))) {
            requestElements[i] = chunk;
            i++;
        }
        if (i != 3) {
            returnString (HTTP_ERROR, "malformed request", commChannel);
            goto bailout;
        }
        
        handleRequest (requestElements[0], requestElements[1], 
                       commChannel);
    } else {
        fprintf (stderr, "read an empty request.  exiting\n");
    }

bailout:
    fclose (commChannel);
    fflush (stderr);

    _exit (EXIT_SUCCESS);

} // dispatchRequest



// sit blocking on accept until either it breaks out with a signal
// (like SIGCHLD) or a new connection comes in.  If it's a new
// connection, fork off a child to process the request

static void acceptRequest (int listenSocket) {
    struct sockaddr_in address;
    socklen_t addressLength = sizeof(address);

    int result;
    result = accept (listenSocket, (struct sockaddr *)&address, 
                     &addressLength);

    if (result == -1) {
        if (errno == EINTR) {
            // system call interrupted by a signal.  maybe by SIGCHLD?
            if (g_childSignaled) {
                // yes, we had gotten a SIGCHLD.  clean up after the
                // kids
                g_childSignaled = 0;
                reapChildren();

                // note that g_childSignaled is cleared before
                // reapChildren is called, in case another sigchld
                // happened during reapChildren, we won't lose it
                goto bailout;
            }
        } else {
            fprintf (stderr, "accept failed.  error: %d/%s\n",
                     errno, strerror(errno));
        }
        goto bailout;
    }

    int fd;
    fd = result;

    // fork off a child to do the work

    // child sends output to stderr, so make sure it's drained before
    // moving on
    fflush (stderr); 
    
    pid_t childPid;
    if ((childPid = fork())) {
        // parent
        if (childPid == -1) {
            fprintf (stderr, "fork failed.  Error: %d/%s\n",
                     errno, strerror(errno));
            goto bailout;
        }
        // close the new connection since the parent doesn't care
        // if we don't do this, the connection to the browser will
        close (fd); 

    } else {
        // child
        printf ("in child");
        dispatchRequest (fd, &address);
    }

bailout:
    return;

} // acceptRequest


// ----- network stuff


// this is 100% stolen from chatterserver.m
// start listening on our server port (runs in parent)

static int startListening () {
    int fd = -1, success = 0;
    int result;

    result = socket (AF_INET, SOCK_STREAM, 0);
    
    if (result == -1) {
        fprintf (stderr, "could not make a scoket.  error: %d / %s\n",
                 errno, strerror(errno));
        goto bailout;
    }
    fd = result;

    int yes = 1;
    result = setsockopt (fd, SOL_SOCKET, SO_REUSEADDR, 
                         &yes, sizeof(int));
    if (result == -1) {
        fprintf (stderr, 
                 "could not setsockopt to reuse address. %d / %s\n",
                 errno, strerror(errno));
        goto bailout;
    }

    // bind to an address and port
    struct sockaddr_in address;
    address.sin_len = sizeof (struct sockaddr_in);
    address.sin_family = AF_INET;
    address.sin_port = htons (PORT_NUMBER);
    address.sin_addr.s_addr = htonl (INADDR_ANY);
    memset (address.sin_zero, 0, sizeof(address.sin_zero));
    
    result = bind (fd, (struct sockaddr *)&address, sizeof(address));
    if (result == -1) {
        fprintf (stderr, "could not bind socket.  error: %d / %s\n",
                 errno, strerror(errno));
        goto bailout;
    }
    
    result = listen (fd, 8);

    if (result == -1) {
        fprintf (stderr, "listen failed.  error: %d /  %s\n",
                 errno, strerror(errno));
        goto bailout;
    }

    success = 1;

bailout:
    if (!success) {
        close (fd);
        fd = -1;
    }
    return (fd);

} // startListening


int main (void) {
    int listenSocket;

    // install a signal handler to reap any children that have exited
    (void) signal (SIGCHLD, childExited);

    // Don't let children-exiting signals interrupt system calls.
    siginterrupt (SIGCHLD, 1);

    listenSocket = startListening ();

    printf ("listening to http://localhost:%d\n", PORT_NUMBER);
    printf ("some things to try:\n");
    printf ("http://localhost:%d/file/webserve.m\n", PORT_NUMBER);
    printf ("http://localhost:%d/file/sample.html\n", PORT_NUMBER);
    printf ("http://localhost:%d/numbers/32\n", PORT_NUMBER);

    while (1) {
        acceptRequest (listenSocket);
    }

    return (EXIT_SUCCESS);

} // main


