// simpleserver.m -- listen on a port, and print any bytes 
//                   that come through

//gcc -std=c99 -g -Wall -o simpleserver simpleserver.m


#import <stdlib.h>        // for EXIT_SUCCESS
#import <stdbool.h>       // true/false
#import <stdio.h>         // for fprintf

#import <arpa/inet.h>     // for inet_ntop
#import <errno.h>         // for errno
#import <netinet/in.h>    // for sockaddr_in
#import <netinet6/in6.h>  // sockaddr_in6
#import <string.h>        // for strerror
#import <sys/socket.h>    // socket(), AF_INET
#import <sys/types.h>     // random types
#import <unistd.h>        // close()

static const in_port_t kPortNumber = 2342;
static const int kAcceptQueueSizeHint = 8;

static void AcceptClientFromSocket(int);

int
main(int argc, char *argv[]) {
    int exit_code = EXIT_FAILURE;

    // get a socket
    const bool useIPv6 = (argc > 1);
    int fd = socket(useIPv6? AF_INET6 : AF_INET, SOCK_STREAM, 0);
    if (-1 == fd) {
        perror("*** socket");
        goto CloseAndExit;
    }

    // reuse the address so we do not fail on program launch
    int yes = 1;
    int result = setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, 
                            &yes, sizeof(yes));
    if (-1 == result) {
        perror("*** setsockopt(SO_REUSEADDR)");
        goto CloseAndExit;
    }

    // bind to an address and port
    union {
        struct sockaddr sa;  // avoids casting
        struct sockaddr_in in;  // IPv4 support
        struct sockaddr_in6 in6;  // IPv6 support
    } address;

    if (useIPv6) {
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

    result = bind(fd, &address.sa, address.sa.sa_len);
    if (-1 == result) {
        perror("*** bind");
        goto CloseAndExit;
    }

    result = listen(fd, kAcceptQueueSizeHint);
    if (-1 == result) {
        perror("*** listen");
        goto CloseAndExit;
    }
    printf("listening on port %d\n", (int)kPortNumber);

    while (true) AcceptClientFromSocket(fd);
    exit_code = EXIT_SUCCESS;

CloseAndExit:
    close(fd);
    return exit_code;
}

static void
AcceptClientFromSocket(int listen_fd) {
    struct sockaddr_storage addr;
    socklen_t addr_len = sizeof(addr);
    int client_fd = accept(listen_fd, (struct sockaddr *)&addr, &addr_len);
    if (-1 == client_fd) {
        perror("*** accept");
        return;
    }

    // get the port and a pointer to the network address
    const void *net_addr = NULL;
    in_port_t port = 0;
    if (AF_INET == addr.ss_family) {
        struct sockaddr_in *addr_in = (struct sockaddr_in *)&addr;
        net_addr = &addr_in->sin_addr;
        port = addr_in->sin_port;
    } else {
        struct sockaddr_in6 *addr_in6 = (struct sockaddr_in6 *)&addr;
        net_addr = &addr_in6->sin6_addr;
        port = addr_in6->sin6_port;
    }

    char buffer[4096];
    const char *name = inet_ntop(addr.ss_family, net_addr,
                                 buffer, sizeof(buffer));
    printf("[%s port %d connected]\n", name? name : "(unknown)", ntohs(port));

    // drain the socket
    bool error_or_eof = false;
    while (!error_or_eof) {
        ssize_t read_count = read(client_fd, buffer, sizeof(buffer) - 1);

        if (0 == read_count) error_or_eof = true;  // EOF
        else if (-1 == read_count) {
            perror("*** read");
            error_or_eof = true;  // error
        } else {
            // null-terminate the string and print it out
            buffer[read_count] = '\0';
            printf("%s", buffer);
        }
    }

    close(client_fd);
    puts("[connection closed]");

} // AcceptClientFromSocket
