// simpleserver.m -- listen on a port and print any bytes that come through
//   Run without arguments to bind to an IPv4 address.
//   Run with any argument to bind to an IPv6 address.

// clang -g -Weverything -o simpleserver simpleserver.m

#import <arpa/inet.h>     // for inet_ntop
#import <errno.h>         // for errno
#import <netinet/in.h>    // for sockaddr_in
#import <netinet6/in6.h>  // sockaddr_in6
#import <stdbool.h>       // true/false
#import <stdio.h>         // for fprintf
#import <stdlib.h>        // for EXIT_SUCCESS
#import <string.h>        // for strerror
#import <sys/socket.h>    // socket(), AF_INET
#import <sys/types.h>     // random types
#import <unistd.h>        // close()

static const in_port_t kPortNumber = 2342;
static const int kAcceptQueueSizeHint = 8;

static void AcceptClientFromSocket (int listenFd);

int main (int argc, char *argv[]) {
    int exitCode = EXIT_FAILURE;

    const bool useIPv6 = (argc > 1);

    if (useIPv6) {
        printf ("%s: using IPv6\n", argv[0]);
    }

    // get a socket
    int fd;
    if (useIPv6) fd = socket (AF_INET6, SOCK_STREAM, 0);
    else fd = socket (AF_INET, SOCK_STREAM, 0);

    if (fd == -1) {
        perror ("*** socket");
        goto cleanup;
    }

    // Reuse the address so stale sockets won't kill us.
    int yes = 1;
    int result = setsockopt (fd, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(yes));
    if (result == -1) {
        perror("*** setsockopt(SO_REUSEADDR)");
        goto cleanup;
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
        goto cleanup;
    }

    result = listen (fd, kAcceptQueueSizeHint);
    if (result == -1) {
        perror("*** listen");
        goto cleanup;
    }
    printf("listening on port %d\n", (int)kPortNumber);

    while (true) AcceptClientFromSocket(fd);
    exitCode = EXIT_SUCCESS;

cleanup:
    close(fd);
    return exitCode;
}


static void AcceptClientFromSocket (int listenFd) {

    struct sockaddr_storage addr;
    socklen_t addr_len = sizeof(addr);

    // Accept and get the remote address
    int clientFd = accept (listenFd, (struct sockaddr *)&addr, &addr_len);

    if (clientFd == -1) {
        perror("*** accept");
        return;
    }

    // Get the port and a pointer to the network address.
    const void *net_addr = NULL;
    in_port_t port = 0;

    if (addr.ss_family == AF_INET) {
        struct sockaddr_in *addr_in = (struct sockaddr_in *)&addr;
        net_addr = &addr_in->sin_addr;
        port = addr_in->sin_port;
    } else {
        struct sockaddr_in6 *addr_in6 = (struct sockaddr_in6 *)&addr;
        net_addr = &addr_in6->sin6_addr;
        port = addr_in6->sin6_port;
    }

    // Convert address to something human readable.
    char buffer[4096];
    const char *name = inet_ntop (addr.ss_family, net_addr, buffer, sizeof(buffer));
    printf("[%s port %d connected]\n", name ? name : "(unknown)", ntohs(port));

    // drain the socket
    while (true) {
        ssize_t read_count = read (clientFd, buffer, sizeof(buffer) - 1);

        if (read_count == 0) {
            break;  // end of file
        } else if (read_count == -1) {
            perror("*** read");
            break;  // error
        } else {
            // Zero-terminate the string and print it out
            buffer[read_count] = '\0';
            printf("%s", buffer);
        }
    }

    close (clientFd);
    puts("[connection closed]");

} // AcceptClientFromSocket
