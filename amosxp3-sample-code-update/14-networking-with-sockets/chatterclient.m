// chatterclient.m -- client side of the chatter world

// clang -g -Weverything -o chatterclient chatterclient.m

#import <stdbool.h>        // true/false
#import <stdint.h>         // UINT8_MAX
#import <stdio.h>          // fprintf()
#import <stdlib.h>         // EXIT_SUCCESS
#import <string.h>         // strerror()

#import <errno.h>          // errno
#import <fcntl.h>          // fcntl()
#import <mach/vm_param.h>  // PAGE_SIZE
#import <unistd.h>         // close()

#import <arpa/inet.h>      // inet_ntop()
#import <netdb.h>          // gethostbyname2()
#import <netinet/in.h>     // struct sockaddr_in
#import <netinet6/in6.h>   // struct sockaddr_in6
#import <sys/socket.h>     // socket(), AF_INET
#import <sys/types.h>      // random types

// --------------------------------------------------
// Message protocol

// A message is length + data. The length is a single byte.
// The first message sent by a user has a max length of 8
// and sets the user's name.

#define MAX(x, y) (((x) > (y))? (x) : (y))
#define MAX_MESSAGE_SIZE  (UINT8_MAX)
#define READ_BUFFER_SIZE  (PAGE_SIZE)

static const in_port_t kPortNumber = 2342;

// See simpleclient.m for the definition of these two functions.
static int SocketConnectedToHostNamed (const char *hostname);
static bool GetAddressAtIndex (struct hostent *host, int addressIndex,
                               struct sockaddr_storage *outServerAddress);

// Returns -1 on failure, >= 0 on success.
static ssize_t WriteMessage (int fd, const unsigned char *buffer, ssize_t length) {
    if (length > MAX_MESSAGE_SIZE) {
        fprintf (stderr, "*** Truncating message to %d bytes.\n", MAX_MESSAGE_SIZE);
        length = MAX_MESSAGE_SIZE;
    }

    // Ssend the length byte first
    uint8_t bytesLeft = (uint8_t)length;
    ssize_t nwritten = write (fd, &bytesLeft, sizeof(bytesLeft));

    if (nwritten <= 0) goto bailout;

    // Then, send the string bytes.
    while (bytesLeft > 0) {
        nwritten = write(fd, buffer, bytesLeft);
        if (nwritten <= 0) goto bailout;

        bytesLeft -= nwritten;
        buffer += nwritten;
    }
bailout:
    if (nwritten == -1) perror("write");
    return nwritten;
} // WriteMessage


int main (int argc, char *argv[]) {
    int exit_status = EXIT_FAILURE;
    int serverFd = -1;

    if (argc != 3) {
        fprintf(stderr, "Usage: chatterclient hostname username\n");
        goto bailout;
    }

    // limit username to 8 characters
    const char *name = argv[2];
    size_t namelen = strlen(name);
    if (namelen > 8) {
        fprintf (stderr, "*** Username must be 8 characters or fewer.\n");
        goto bailout;
    }

    // set stdin to non-blocking
    int err = fcntl(STDIN_FILENO, F_SETFL, O_NONBLOCK);
    if (err == -1) {
        perror ("fcntl(stdin O_NONBLOCK)");
        goto bailout;
    }

    // Get a connected socket.
    const char *hostname = argv[1];
    serverFd = SocketConnectedToHostNamed (hostname);
    if (serverFd == -1) {
        fprintf (stderr, "*** Unable to connect to %s port %d.\n",
                 hostname, (int)kPortNumber);
        return EXIT_FAILURE;
    }
    printf ("[connected to %s port %d]\n", hostname, (int)kPortNumber);
    // no need to bind() or listen()

    ssize_t nwritten = WriteMessage (serverFd, (unsigned char *)name,
                                     (ssize_t)namelen);
    if (nwritten == -1) {
        perror("*** Unable to write username");
        goto bailout;
    }

    // Now set to non-block so we can interleave stdin and messages from the server.
    err = fcntl (serverFd, F_SETFL, O_NONBLOCK);
    if (err == -1) {
        perror ("fcntl(serverFd O_NONBLOCK)");
        goto bailout;
    }

    unsigned char incomingBuffer[READ_BUFFER_SIZE];
    unsigned char messageBuffer[MAX_MESSAGE_SIZE];

    while (true) {
        fd_set readfds;
        FD_ZERO (&readfds);
        FD_SET (STDIN_FILENO, &readfds);
        FD_SET (serverFd, &readfds);
        int max_fd = MAX (STDIN_FILENO, serverFd);

        int nready = select (max_fd + 1, &readfds, NULL, NULL, NULL);

        if (nready == -1) {
            perror("select");
            continue;
        }

        // Check standard-in.
        if (FD_ISSET(STDIN_FILENO, &readfds)) {
            ssize_t nread = read (STDIN_FILENO, messageBuffer, sizeof(messageBuffer));

            if (nread == -1) {
                perror("read(stdin)");
                goto bailout;
            } else if (nread == 0) {
                // closed
                break;
            }

            nwritten = WriteMessage(serverFd, messageBuffer, nread);

            if (nwritten == -1) {
                // WriteMessage logged the error for us.
                goto bailout;
            }
        }

        // Does the server have stuff for us?
        if (FD_ISSET(serverFd, &readfds)) {
            // Read at most 1 less than the buffer size so we can
            // always null-terminate.
            ssize_t nread = read (serverFd, incomingBuffer, sizeof(incomingBuffer) - 1);

            if (nread == -1) {
                perror("read(serverFd)");
                goto bailout;

            } else if (nread == 0) {
                fprintf (stderr, "[Server closed connection.]\n");
                break;

            } else {
                incomingBuffer[nread] = '\0';
                printf ("%s", incomingBuffer);
            }
        }
    }

    exit_status = EXIT_SUCCESS;

bailout:
    if (serverFd > -1) close(serverFd);
    return (exit_status);

} // main


/* * * THESE DON'T GET COPIED INTO THE BOOK AT THIS POINT * * */

/* They were already printed with simpleclient.m; we're just reusing them. */
// Returns -1 on failure, >= 0 on success.
static int SocketConnectedToHostNamed (const char *hostname) {
    int sockfd = -1;

    // For each family call gethostbyname2()
    sa_family_t family[] = { AF_INET6, AF_INET };
    int family_count = sizeof(family) / sizeof(*family);

    for (int i = 0; sockfd == -1 && i < family_count; i++) {
        printf("Looking at %s family:\n", 
               family[i] == AF_INET6 ? "AF_INET6" : "AF_INET");

        // Get the host address.
        struct hostent *host = NULL;
        host = gethostbyname2(hostname, family[i]);
        if (host == NULL) {
            herror ("gethostbyname2");
            continue;
        }

        // Try to connect with each address.
        struct sockaddr_storage server_addr;

        for (int addressIndex = 0; sockfd == -1; addressIndex++) {

            // Grab the next address.  Bail out if we've run out.
            if (!GetAddressAtIndex(host, addressIndex, &server_addr)) break;

            char buffer[INET6_ADDRSTRLEN];

            printf("    Trying %s...\n",
                   inet_ntop(host->h_addrtype, host->h_addr_list[addressIndex],
                             buffer, sizeof(buffer)));

            // Get a socket.
            sockfd = socket (server_addr.ss_family, SOCK_STREAM, 0);

            if (sockfd == -1) {
                perror ("        socket");
                continue;
            }

            // Reach out and touch someone.  Clients call connect() instead of 
            // bind() + listen().
            int err = connect (sockfd, (struct sockaddr *)&server_addr, 
                               server_addr.ss_len);
            if (err == -1) {
                perror ("        connect");
                close (sockfd);
                sockfd = -1;
            }
            // We successfully connected, so sockfd is not -1.
            // Both loops will exit at this point.
        }
    }
    return sockfd;
} // SocketConnectedToHostNamed


// Index into the hostent and get the addressIndex'th address.
// Returns true if successful, false if we've run out of addresses.
static bool GetAddressAtIndex (struct hostent *host, int addressIndex,
                               struct sockaddr_storage *outServerAddress) {
    // Bad arguments?
    if (outServerAddress == NULL || host == NULL) return false;

    // Out of addresses?
    if (host->h_addr_list[addressIndex] == NULL) return false;

    // Don't have control over these data types, and compiler complains, so quiet
    // that warning
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wconversion"
#pragma clang diagnostic ignored "-Wcast-align"
    outServerAddress->ss_family = host->h_addrtype;

    if (outServerAddress->ss_family == AF_INET6) {
        struct sockaddr_in6 *addr = (struct sockaddr_in6 *)outServerAddress;
        addr->sin6_len = sizeof(*addr);
        addr->sin6_port = htons(kPortNumber);
        addr->sin6_flowinfo = 0;
        addr->sin6_addr = *(struct in6_addr *)host->h_addr_list[addressIndex];
        addr->sin6_scope_id = 0;
    } else {
        struct sockaddr_in *addr = (struct sockaddr_in *)outServerAddress;
        addr->sin_len = sizeof(*addr);
        addr->sin_port = htons(kPortNumber);
        addr->sin_addr = *(struct in_addr *)host->h_addr_list[addressIndex];
        memset(&addr->sin_zero, 0, sizeof(addr->sin_zero));
    }
#pragma clang diagnostic pop

    return true;
} // GetAddressAtIndex
