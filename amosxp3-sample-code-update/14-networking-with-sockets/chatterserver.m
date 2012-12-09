// chatterserver.m -- chat server using standard sockets API

// clang -g -Weverything -o chatterserver chatterserver.m

#import <stdbool.h>        // true/false
#import <stdint.h>         // UINT8_MAX
#import <stdio.h>          // fprintf
#import <stdlib.h>         // EXIT_SUCCESS
#import <string.h>         // strerror()

#import <errno.h>          // errno
#import <fcntl.h>          // fcntl()
#import <mach/vm_param.h>  // PAGE_SIZE
#import <signal.h>         // sigaction()
#import <sys/uio.h>        // iovec
#import <syslog.h>         // syslog() and friends
#import <unistd.h>         // close()

#import <arpa/inet.h>      // inet_ntop()
#import <netinet/in.h>     // struct sockaddr_in
#import <netinet6/in6.h>   // struct sockaddr_in6
#import <sys/socket.h>     // socket(), AF_INET
#import <sys/types.h>      // random types


// --------------------------------------------------
// Message protocol

// A message is length + data. The length is a single byte.
// The first message sent by a user has a max length of 8 and sets the user's name.

#define MAX(x, y) (((x) > (y)) ? (x) : (y))
#define MAX_MESSAGE_SIZE  UINT8_MAX
#define READ_BUFFER_SIZE  PAGE_SIZE


// Paranoia check that the read buffer is large enough to hold a full message.
typedef uint8_t READ_BUFFER_SIZE_not_less_than_MAX_MESSAGE_SIZE
    [!(READ_BUFFER_SIZE < MAX_MESSAGE_SIZE) ? 1 : -1];

// There is one of these for each connected user
typedef struct ChatterUser_ {
    int      fd;       // zero fd == no user
    char     name[9];  // 8 character name plus trailing zero byte
    bool     gotName;  // have we gotten the username packet?

    short    padding;
    /* incoming data workspace */
    ssize_t  bytesRead;
    char     buffer[READ_BUFFER_SIZE];
} ChatterUser;

#define MAX_USERS 50
static ChatterUser s_Users[MAX_USERS];

static const in_port_t kPortNumber = 2342;
static const int kAcceptQueueSizeHint = 8;

// Returns fd on success, -1 on error.  Based on main() in simpleserver.m
static int StartListening (const bool useIPv6) {
    // get a socket
    int fd;
    if (useIPv6) fd = socket (AF_INET6, SOCK_STREAM, 0);
    else fd = socket (AF_INET, SOCK_STREAM, 0);

    if (fd == -1) {
        perror ("*** socket");
        goto bailout;
    }

    // Reuse the address so stale sockets won't kill us.
    int yes = 1;
    int result = setsockopt (fd, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(yes));
    if (result == -1) {
        perror("*** setsockopt(SO_REUSEADDR)");
        goto bailout;
    }

    // Bind to an address and port

    // Glom both kinds of addresses into a union to avoid casting.
    union {
        struct sockaddr sa;       // avoids casting
        struct sockaddr_in in;    // IPv4 support
        struct sockaddr_in6 in6;  // IPv6 support
    } address;

    if (useIPv6) {
        address.in6.sin6_len = sizeof (address.in6);
        address.in6.sin6_family = AF_INET6;
        address.in6.sin6_port = htons (kPortNumber);
        address.in6.sin6_flowinfo = 0;
        address.in6.sin6_addr = in6addr_any;
        address.in6.sin6_scope_id = 0;
    } else {
        address.in.sin_len = sizeof (address.in);
        address.in.sin_family = AF_INET;
        address.in.sin_port = htons (kPortNumber);
        address.in.sin_addr.s_addr = htonl (INADDR_ANY);
        memset (address.in.sin_zero, 0, sizeof (address.in.sin_zero));
    }

    result = bind (fd, &address.sa, address.sa.sa_len);
    if (result == -1) {
        perror("*** bind");
        goto bailout;
    }

    result = listen (fd, kAcceptQueueSizeHint);
    if (result == -1) {
        perror("*** listen");
        goto bailout;
    }
    printf("listening on port %d\n", (int)kPortNumber);
    return fd;

bailout:
    if (fd != -1) {
        close(fd);
        fd = -1;
    }
    return fd;
}  // StartListening

// Called when select() indicates the listening socket is ready to be read,
// which means there is a connection waiting to be accepted.
static void AcceptConnection (int listen_fd) {
    struct sockaddr_storage addr;
    socklen_t addr_len = sizeof(addr);

    int clientFd = accept (listen_fd, (struct sockaddr *)&addr, &addr_len);

    if (clientFd == -1) {
        perror("*** accept");
        goto bailout;
    }

    // Set to non-blocking
    int err = fcntl (clientFd, F_SETFL, O_NONBLOCK);
    if (err == -1) {
        perror("*** fcntl(clientFd O_NONBLOCK)");
        goto bailout;
    }

    // Find the next free spot in the users array
    ChatterUser *newUser = NULL;
    for (int i = 0; i < MAX_USERS; i++) {
        if (s_Users[i].fd == 0) {
            newUser = &s_Users[i];
            break;
        }
    }

    if (newUser == NULL) {
        const char gripe[] = "Too many users - try again later.\n";
        write (clientFd, gripe, sizeof(gripe));
        goto bailout;
    }

    // ok, clear out the structure, and get it set up
    memset (newUser, 0, sizeof(ChatterUser));

    newUser->fd = clientFd;
    clientFd = -1; // Don't let function cleanup close the fd.

    // log where the connection is from
    void *net_addr = NULL;

    in_port_t port = 0;
    if (addr.ss_family == AF_INET) {
        struct sockaddr_in6 *sin6 = (struct sockaddr_in6 *)&addr;
        net_addr = &sin6->sin6_addr;
        port = sin6->sin6_port;
    } else {
        struct sockaddr_in *sin = (struct sockaddr_in *)&addr;
        net_addr = &sin->sin_addr;
        port = sin->sin_port;
    }

    // Make it somewhat human readable.
    char buffer[INET6_ADDRSTRLEN];
    const char *name = inet_ntop (addr.ss_family, net_addr,
                                  buffer, sizeof(buffer));

    syslog (LOG_NOTICE, "Accepted connection from %s port %d as fd %d.",
            name, port, clientFd);
bailout:
    if (clientFd != -1) close(clientFd);
    return;
}  // AcceptConnection


// send a message to all the signed-in users
static void BroadcastMessageFromUser (const char *message, const ChatterUser *user) {
    if (!user->gotName) return;

    static const char separator[] = ": ";

    // All messages are expected to have a terminating newline.
    printf ("Broadcast message: %s%s%s", user->name, separator, message);

    // use scattered writes just for fun. Because We Can.
    const struct iovec iovector[] = {
        { (char *)user->name, strlen(user->name)    },
        { (char *)separator,  sizeof(separator) - 1 }, // omit terminator
        { (char *)message,    strlen(message)       }
    };
    const int iovector_len = sizeof(iovector) / sizeof(*iovector);

    // Scan through the users and send the mesage.
    const ChatterUser *stop = &s_Users[MAX_USERS];
    for (ChatterUser *u = s_Users; u < stop; u++) {
        if (u->fd > 0) {
            ssize_t nwrite = writev (u->fd, iovector, iovector_len);
            if (nwrite == -1) perror ("writev");
            else fprintf(stderr, "\tSent \"%s\" %zd bytes\n", u->name, nwrite);
        }
    }
}  // BroadcastMessageFromUser

// user disconnected.  Do any mop-up
static void DisconnectUser(ChatterUser *user) {
    if (user->fd > 0) {
        close (user->fd);
        user->fd = 0;
        syslog (LOG_NOTICE, "Disconnected user \"%s\" on fd %d\n",
                user->gotName? user->name : "(unknown)", user->fd);

        // broadcast 'user disconnected' message
        if (user->gotName) BroadcastMessageFromUser("has left the channel.\n", user);
    }

    user->gotName = false;
    user->bytesRead = 0;
    user->buffer[0] = 0;

} // DisconnectUser

// the first packet is the user's name.  Get it.
static void ReadUsername(ChatterUser *user) {
    // see if we have read anything yet
    if (user->bytesRead == 0) {
        // Read the length byte.
        const size_t toread = sizeof (user->buffer[0]);
        ssize_t nread = read (user->fd, user->buffer, toread);

        if (nread == toread) {
            // we got our length byte
            user->bytesRead += nread;
            const size_t namelen = (uint8_t)user->buffer[0];
            if (namelen >= sizeof(user->name)) {
                static const char badNameMessage[] 
                    = "Error: Username must be 8 characters or fewer.\n";
                write (user->fd, badNameMessage, sizeof(badNameMessage));
                DisconnectUser (user);
            }

        } else if (nread == 0) {
            // end of file
            DisconnectUser (user);

        } else if (nread == -1) {
            perror("read");
            DisconnectUser (user);

        } else {
            fprintf (stderr, 
                     "Should not have reached line %d.  nread: %zu toread: %zu\n",
                     __LINE__, nread, toread);
        }

    } else {
        // ok, try to read just the rest of the username
        const uint8_t namelen = (uint8_t)user->buffer[0];
        const size_t packetlen = sizeof(namelen) + namelen;
        const size_t nleft = packetlen - (size_t)user->bytesRead;
        ssize_t nread = read (user->fd, user->buffer + user->bytesRead, nleft);

        switch (nread) {
           default:
               user->bytesRead += nread;
               break;

           case 0:  // peer closed the connection
               DisconnectUser (user);
               break;

           case -1:
               perror ("ReadName: read");
               DisconnectUser (user);
               break;
        }

        // Do we have the name?
        if (user->bytesRead > namelen) {
            user->gotName = true;

            // Copy username into the User structure.
            memcpy (user->name, &user->buffer[1], namelen);
            user->name[namelen] = '\0';
            printf("Received username: %s\n", user->name);

            // no current message, so clear it out
            user->buffer[0] = 0;
            user->bytesRead -= packetlen;

            syslog(LOG_NOTICE, "Username for fd %d is %s.", user->fd, user->name);
            BroadcastMessageFromUser("has joined the channel.\n", user);
        }
    }
}  // ReadUsername

// Get message data from the given user
static void ReadMessage (ChatterUser *user) {
    // read as much as we can into the buffer
    const size_t toread = sizeof(user->buffer) - (size_t)user->bytesRead;
    ssize_t nread = read (user->fd, user->buffer + user->bytesRead, toread);

    switch (nread) {
       default:
           user->bytesRead += nread;
           break;
       case 0:
           DisconnectUser (user);
           break;
       case -1:
           perror ("ReadMessage: read"); 
           return;
    }

    // Send any complete messages. The first byte in the buffer is
    // always the length byte.
    char msgbuf[MAX_MESSAGE_SIZE + 1];

    while (user->bytesRead > 0) {
        const uint8_t msglen = (uint8_t)user->buffer[0];
        // Only a partial message left?
        if (user->bytesRead <= msglen) break;

        // copy message to buffer and null-terminate
        char *msg = &user->buffer[1];
        memcpy (msgbuf, msg, msglen);
        msgbuf[msglen] = '\0';
        BroadcastMessageFromUser (msgbuf, user);

        // Slide the rest of the data over
        const size_t packetlen = sizeof(msglen) + msglen;
        user->bytesRead -= packetlen;
        memmove (user->buffer, msg + msglen, user->bytesRead);
    }

}  // ReadMessage

// we got read activity for a user
static void HandleRead (ChatterUser *user) {
    if (!user->gotName) ReadUsername(user);
    else ReadMessage(user);
}  // HandleRead

int main (int argc, char *argv[]) {
    int exit_status = EXIT_FAILURE;
    const bool useIPv6 = (argc > 1);
    int listenFd = StartListening (useIPv6);

    if (listenFd == -1) {
        fprintf (stderr, "%s: *** Could not open listening socket.\n", argv[0]);
        goto bailout;
    }

    // Block SIGPIPE so a dropped connection won't signal us.
    struct sigaction act;
    act.sa_handler = SIG_IGN;
    struct sigaction oact;
    int err = sigaction (SIGPIPE, &act, &oact);
    if (err == -1) perror ("sigaction(SIGPIPE, SIG_IGN)");

    // wait for activity
    int max_fd = 0;

    while (true) {
        fd_set readfds;
        FD_ZERO(&readfds);

        // Add the listen socket
        FD_SET(listenFd, &readfds);
        max_fd = MAX(max_fd, listenFd);

        // Add the users.
        for (int i = 0; i < MAX_USERS; i++) {
            const int user_fd = s_Users[i].fd;
            if (user_fd <= 0) continue;

            FD_SET (user_fd, &readfds);
            max_fd = MAX (max_fd, user_fd);
        }

        // Wait until something interesting happens.
        int nready = select (max_fd + 1, &readfds, NULL, NULL, NULL);

        if (nready == -1) {
            perror("select");
            continue;
        }

        // See if a new user is knocking on our door.
        if (FD_ISSET(listenFd, &readfds)) {
            AcceptConnection (listenFd);
        }

        // Handle any new incoming data from the users.
        // Closes appear here too.
        for (int i = 0; i < MAX_USERS; i++) {
            ChatterUser *const user = &s_Users[i];
            if (user->fd >= 0 && FD_ISSET(user->fd, &readfds)) {
                HandleRead (user);
            }
        }
    }
    exit_status = EXIT_SUCCESS;

bailout:
    return exit_status;
}  // main
