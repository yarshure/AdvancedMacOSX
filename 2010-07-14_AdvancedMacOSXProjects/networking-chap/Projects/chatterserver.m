// chatterserver.m -- chat server using standard sockets API

//gcc -g -Wall -std=c99 -o chatterserver chatterserver.m

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

/* Message Protocol */

// A message is length + data. The length is a single byte.
// The first message sent by a user has a max length of 8
// and sets the user's name.

#define MAX(x, y) (((x) > (y))? (x) : (y))
#define MAX_MESSAGE_SIZE  (UINT8_MAX)
#define READ_BUFFER_SIZE  (PAGE_SIZE)

// Paranoia check that the read buffer is large enough to hold a full message.
typedef uint8_t READ_BUFFER_SIZE_not_less_than_MAX_MESSAGE_SIZE
    [!(READ_BUFFER_SIZE < MAX_MESSAGE_SIZE) ? 0 : -1];

// there is one of these for each connected user
typedef struct ChatterUser_ {
    int      fd;       // zero fd == no user
    char     name[9];  // 8 character name plus trailing zero byte
    bool     gotName;  // have we gotten the username packet?

    /* incoming data workspace */
    ssize_t  bytesRead;
    char     buffer[READ_BUFFER_SIZE];
} ChatterUser;

#define MAX_USERS 50
static ChatterUser sUsers[MAX_USERS];

static const in_port_t kPortNumber = 2342;
static const int kAcceptQueueSizeHint = 8;

// Returns fd on success, -1 on error.
// (This is copied from main() in simpleserver.m.)
static int
StartListening(const bool use_ipv6) {
    // get a socket
    int fd = socket(use_ipv6? AF_INET6 : AF_INET, SOCK_STREAM, 0);
    if (-1 == fd) {
        perror("*** socket");
        goto CloseAndExit;
    }

    // reuse the address so we do not fail on program launch
    int yes = 1;
    int result = setsockopt(fd, SOL_SOCKET, SO_REUSEADDR,
                            &yes, sizeof(int));
    if (-1 == result) {
        perror("*** setsockopt(listen_fd, SO_REUSEADDR)");
        goto CloseAndExit;
    }

    // build the address.  The union lets us avoid having to
    // cast in socket calls.
    union {
        struct sockaddr sa;
        struct sockaddr_in in;  // IPv4 support
        struct sockaddr_in6 in6;  // IPv6 support
    } address;

    if (use_ipv6) {
        address.in6.sin6_len = sizeof(address.in6);
        address.in6.sin6_family = AF_INET6;
        address.in6.sin6_port = htons(kPortNumber);
        address.in6.sin6_flowinfo = 0;
        address.in6.sin6_addr = in6addr_any;
        address.in6.sin6_scope_id = 0;
    } else {
        address.in.sin_len = sizeof(address.in);
        address.in.sin_family = AF_INET;
        address.in.sin_port = htons(kPortNumber);
        address.in.sin_addr.s_addr = htonl(INADDR_ANY);
        memset(address.in.sin_zero, 0, sizeof(address.in.sin_zero));
    }

    // bind to an address and port
    result = bind(fd, &address.sa, address.sa.sa_len);
    if (-1 == result) {
        perror("*** bind(listen_fd)");
        goto CloseAndExit;
    }

    result = listen(fd, kAcceptQueueSizeHint);
    if (-1 == result) {
        perror("*** listen");
        goto CloseAndExit;
    }
    printf("listening on port %d\n", (int)kPortNumber);
    return fd;

CloseAndExit:
    if (-1 != fd) {
        close(fd);
        fd = -1;
    }
    return fd;
}  // StartListening

// Called when select() indicates the listening socket is ready to be read,
// which means there is a connection waiting to be accepted.
static void
AcceptConnection(int listen_fd) {
    struct sockaddr_storage addr;
    socklen_t addr_len = sizeof(addr);
    int client_fd = accept(listen_fd, (struct sockaddr *)&addr, &addr_len);
    if (-1 == client_fd) {
        perror("*** accept");
        goto BailOut;
    }

    // set to non-blocking
    int err = fcntl(client_fd, F_SETFL, O_NONBLOCK);
    if (-1 == err) {
        perror("*** fcntl(client_fd O_NONBLOCK)");
        goto BailOut;
    }

    // find the next free spot in the users array
    ChatterUser *new_user = NULL;
    for (int i = 0; NULL == new_user && i < MAX_USERS; i++) {
        const bool is_free = sUsers[i].fd < 0;
        if (is_free) new_user = &sUsers[i];
    }

    if (NULL == new_user) {
        const char gripe[] = "Too many users - try again later.\n";
        write(client_fd, gripe, sizeof(gripe));
        goto BailOut;
    }

    // ok, clear out the structure, and get it set up
    memset(new_user, 0, sizeof(ChatterUser));

    new_user->fd = client_fd;
    client_fd = -1;

    // log where the connection is from
    void *net_addr = NULL;
    in_port_t port = 0;
    if (AF_INET == addr.ss_family) {
        struct sockaddr_in6 *sin6 = (struct sockaddr_in6 *)&addr;
        net_addr = &sin6->sin6_addr;
        port = sin6->sin6_port;
    } else {
        struct sockaddr_in *sin = (struct sockaddr_in *)&addr;
        net_addr = &sin->sin_addr;
        port = sin->sin_port;
    }
    char buffer[INET6_ADDRSTRLEN];
    const char *name = inet_ntop(addr.ss_family, net_addr,
                                 buffer, sizeof(buffer));
    syslog(LOG_NOTICE, "Accepted connection from %s port %d as fd %d.",
           name, port, client_fd);
BailOut:
    if (-1 != client_fd) close(client_fd);
    return;
}  // AcceptConnection


// send a message to all the signed-in users
static void
BroadcastMessageFromUser(const char *message, const ChatterUser *user) {
    static const char separator[] = ": ";
    if (!user->gotName) return;

    // All messages are expected to have a terminating newline.
    printf("Broadcast message: %s%s%s", user->name, separator, message);

    // use scattered writes just for fun
    const struct iovec iovector[] = {
        {(char *)user->name, strlen(user->name)},
        {(char *)separator, sizeof(separator) - 1}, // omit terminator
        {(char *)message, strlen(message)}
    };
    const int iovector_len = sizeof(iovector) / sizeof(*iovector);

    // use a pointer chase for fun
    const ChatterUser *stop = &sUsers[MAX_USERS];
    for (ChatterUser *u = sUsers; u < stop; ++u) {
        if (u->fd > -1) {
            ssize_t err = writev(u->fd, iovector, iovector_len);
            if (-1 == err) perror("writev");
            else fprintf(stderr, "\tSent \"%s\" %zd bytes\n", u->name, err);
        }
    }
}  // BroadcastMessageFromUser

// user disconnected.  Do any mop-up
static void
DisconnectUser(ChatterUser *user) {
    if (user->fd > -1) {
        close(user->fd), user->fd = -1;
        syslog(LOG_NOTICE, "Disconnected user \"%s\" on fd %d\n",
               user->gotName? user->name : "(unknown)", user->fd);

        // broadcast 'user disconnected' message
        if (user->gotName)
            BroadcastMessageFromUser("has left the channel.\n", user);
    }

    user->gotName = false;
    user->bytesRead = 0;
    user->buffer[0] = 0;
}  // DisconnectUser

// the first packet is the user's name.  Get it
static void
ReadUsername(ChatterUser *user) {
    // see if we have read anything yet
    const bool need_namelen = (0 == user->bytesRead);
    if (need_namelen) {
        // Read the length byte.
        const size_t toread = sizeof(user->buffer[0]);
        ssize_t nread = read(user->fd, user->buffer, toread);

        if (toread == nread) {
            // we got our length byte
            user->bytesRead += nread;
            const size_t namelen = (uint8_t)user->buffer[0];
            if (namelen >= sizeof(user->name)) {
                static const char
                bad_name_msg[] = "Error: Username must be 8 "
                                 "characters or fewer.\n";
                write(user->fd, bad_name_msg, sizeof(bad_name_msg));
                DisconnectUser(user);
            }

        } else if (0 == nread) {
            // end of file
            DisconnectUser(user);

        } else if (-1 == nread) {
            perror("read");
            DisconnectUser(user);
        }

    } else {
        // ok, try to read just the rest of the username
        const uint8_t namelen = (uint8_t)user->buffer[0];
        const size_t packetlen = sizeof(namelen) + namelen;
        const size_t nleft = packetlen - user->bytesRead;
        ssize_t nread = read(user->fd, user->buffer + user->bytesRead,
                             nleft);
        switch (nread) {
           default:
               user->bytesRead += nread; break;

           case 0:  // peer closed the connection
               DisconnectUser(user); break;

           case -1:
               perror("ReadName: read");
               DisconnectUser(user); break;
        }

        const bool have_name = (user->bytesRead > namelen);
        if (have_name) {
            user->gotName = true;
            memcpy(user->name, &user->buffer[1], namelen);
            user->name[namelen] = '\0';
            printf("Received username: %s\n", user->name);

            // no current message, so clear it out
            user->buffer[0] = 0;
            user->bytesRead -= packetlen;

            syslog(LOG_NOTICE, "Username for fd %d is %s.",
                   user->fd, user->name);
            BroadcastMessageFromUser("has joined the channel.\n", user);

        }
    }
}  // ReadUsername

// get message data from the given user
static void
ReadMessage(ChatterUser *user) {
    // read as much as we can into the buffer
    const size_t toread = sizeof(user->buffer) - user->bytesRead;
    ssize_t nread = read(user->fd,
                         user->buffer + user->bytesRead, toread);

    switch (nread) {
       default:
           user->bytesRead += nread; break;
       case 0:
           DisconnectUser(user); break;
       case -1:
           perror("ReadMessage: read"); return;
    }

    // Send any complete messages.
    // The first byte in the buffer is always the length byte.
    char msgbuf[MAX_MESSAGE_SIZE + 1];
    while (user->bytesRead > 0) {
        const uint8_t msglen = (uint8_t)user->buffer[0];
        const bool have_msg = user->bytesRead > msglen;
        if (!have_msg) break;

        // copy message to buffer and null-terminate
        char *msg = &user->buffer[1];
        memcpy(msgbuf, msg, msglen);
        msgbuf[msglen] = '\0';
        BroadcastMessageFromUser(msgbuf, user);

        // slide the rest of the data over
        const size_t packetlen = sizeof(msglen) + msglen;
        user->bytesRead -= packetlen;
        memmove(user->buffer, msg + msglen, user->bytesRead);
    }
}  // ReadMessage

// we got read activity for a user
static void
HandleRead(ChatterUser *user) {
    if (!user->gotName) ReadUsername(user);
    else ReadMessage(user);
}  // HandleRead

int
main(int argc, char *argv[]) {
    int exit_status = EXIT_FAILURE;
    const bool use_ipv6 = (argc > 1);
    int listen_fd = StartListening(use_ipv6);

    if (-1 == listen_fd) {
        fprintf (stderr, "*** Could not open listening socket.\n");
        goto CantListen;
    }

    // block SIGPIPE so a dropped connection won't signal us
    struct sigaction act;
    act.sa_handler = SIG_IGN;
    struct sigaction oact;
    int err = sigaction(SIGPIPE, &act, &oact);
    if (-1 == err) perror("sigaction(SIGPIPE, SIG_IGN)");

    // set all users disconnected
    for (int i = 0; i < MAX_USERS; ++i) {
        sUsers[i].fd = -1;
        DisconnectUser(&sUsers[i]);
    }

    // wait for activity
    while (true) {
        fd_set readfds;
        FD_ZERO(&readfds);

        // add our listen socket
        FD_SET(listen_fd, &readfds);
        int max_fd = MAX(max_fd, listen_fd);

        // add our users;
        for (int i = 0; i < MAX_USERS; i++) {
            const int user_fd = sUsers[i].fd;
            if (user_fd <= 0) continue;

            FD_SET(user_fd, &readfds);
            max_fd = MAX(max_fd, user_fd);
        }

        // wait until something interesting happens
        int nready = select(max_fd + 1, &readfds, NULL, NULL, NULL);

        if (-1 == nready) {
            perror("select");
            continue;
        }

        // see if we have a new user
        if (FD_ISSET(listen_fd, &readfds)) {
            AcceptConnection(listen_fd);
        }

        // handle any new incoming data from the users.
        // closes appear here too.
        for (int i = 0; i < MAX_USERS; i++) {
            ChatterUser *const user = &sUsers[i];
            const bool has_fd = user->fd >= 0;
            if (has_fd && FD_ISSET(user->fd, &readfds)) {
                HandleRead(user);
            }
        }
    }

    exit_status = EXIT_SUCCESS;

CantListen:
    return exit_status;
}  // main
