// simpleclient.m -- read from stdin and send to the simpleserver

//gcc -std=c99 -g -Wall -o simpleclient simpleclient.m

#import <stdio.h>       // fprintf()
#import <stdbool.h>     // true/false
#import <stdlib.h>      // EXIT_SUCCESS

#import <string.h>      // strerror()
#import <errno.h>       // errno
#import <netdb.h>       // gethostbyname2(), h_errno, etc.
#import <arpa/inet.h>   // for inet_ntop
#import <netinet/in.h>  // sockaddr_in
#import <sys/socket.h>  // socket(), AF_INET
#import <sys/types.h>   // random types
#import <unistd.h>      // close()

static const in_port_t kPortNumber = 2342;

static int SocketConnectedToHostNamed(const char *host_name);
static bool GetAddressAtIndex(struct hostent *, int, struct sockaddr_storage *);

int
main(int argc, char *argv[]) {
    int exit_code = EXIT_FAILURE;

    // Get the host name.
    if (argc != 2) {
        fprintf(stderr, "Usage: %s HOSTNAME\n", getprogname());
        goto CloseAndExit;
    }
    const char *host_name = argv[1];

    // Get a connected socket.
    int sockfd = SocketConnectedToHostNamed(host_name);
    if (-1 == sockfd) {
        fprintf(stderr, "*** Unable to connect to %s port %d.\n",
                host_name, (int)kPortNumber);
        return EXIT_FAILURE;
    }
    printf("[connected to %s port %d]\n", host_name, (int)kPortNumber);

    // Echo lines from stdin to sockfd.
    bool error_or_eof = false;
    while (!error_or_eof) {
        char buffer[4096];
        const char *bytes = fgets(buffer, 4096, stdin);
        // check EOF
        if (NULL == bytes) {
            if (ferror(stdin)) {
                perror("read");
                error_or_eof = true;
                continue;
            } else if (feof(stdin)) {
                fprintf(stderr, "EOF\n");
                error_or_eof = true;
                continue;
            }
        }

        ssize_t write_count = write(sockfd, buffer, strlen(buffer));
        if (-1 == write_count) {
            perror("write");
            error_or_eof = true;
        }
    }
    puts("[connection closed]");
    exit_code = EXIT_SUCCESS;

CloseAndExit:
    close(sockfd);
    return exit_code;
}  // main


// Returns -1 on failure, >= 0 on success.
static int
SocketConnectedToHostNamed(const char *host_name) {
    int sockfd = -1;

    // for each family: gethostbyname2
    sa_family_t family[] = {AF_INET6, AF_INET};
    int family_count = sizeof(family) / sizeof(*family);
    struct hostent *host = NULL;

    for (int i = 0; -1 == sockfd && i < family_count; ++i) {
        printf("%s:\n",
               family[i] == AF_INET6? "AF_INET6" : "AF_INET");
        // Get the host address.
        host = gethostbyname2(host_name, family[i]);
        if (NULL == host) {
            herror("gethostbyname2");
            continue;
        }

        // for each address: try to connect
        struct sockaddr_storage server_addr;
        for (int addr_ix = 0;
            -1 == sockfd && GetAddressAtIndex(host, addr_ix, &server_addr);
            ++addr_ix) {
            char buffer[INET6_ADDRSTRLEN];
            printf("    Trying %s...\n",
                   inet_ntop(host->h_addrtype, host->h_addr_list[addr_ix],
                             buffer, sizeof(buffer)));

            // Get a socket.
            sockfd = socket(server_addr.ss_family, SOCK_STREAM, 0);
            if (-1 == sockfd) {
                perror("        socket");
                continue;
            }

            // Clients call connect() instead of bind() and listen().
            int err = connect(sockfd, (struct sockaddr *)&server_addr, 
                             server_addr.ss_len);
            if (-1 == err) {
                perror("        connect");
                close(sockfd);
                sockfd = -1;
            }
            // successfully connected, so sockfd != -1
            // we will exit both loops at this point
        }
    }
    return sockfd;
} // SocketConnectedToHostNamed

// Fills |server_addr| using the |addr_ix|th address in host->h_addr_list.
// Returns true if successful, false if no such address exists.
bool
GetAddressAtIndex(struct hostent *host, int addr_ix,
                  struct sockaddr_storage *out_server_addr) {
    const bool bad_args = (NULL == out_server_addr || NULL == host);
    if (bad_args) return false;

    const bool end_of_addrs = (NULL == host->h_addr_list[addr_ix]);
    if (end_of_addrs) return false;

    out_server_addr->ss_family = host->h_addrtype;
    if (AF_INET6 == out_server_addr->ss_family) {
        struct sockaddr_in6 *addr = (struct sockaddr_in6 *)out_server_addr;
        addr->sin6_len = sizeof(*addr);
        addr->sin6_port = htons(kPortNumber);
        addr->sin6_flowinfo = 0;
        addr->sin6_addr = *(struct in6_addr *)host->h_addr_list[addr_ix];
        addr->sin6_scope_id = 0;
    } else {
        struct sockaddr_in *addr = (struct sockaddr_in *)out_server_addr;
        addr->sin_len = sizeof(*addr);
        addr->sin_port = htons(kPortNumber);
        addr->sin_addr = *(struct in_addr *)host->h_addr_list[addr_ix];
        memset(&addr->sin_zero, 0, sizeof(addr->sin_zero));
    }
    return true;
} // GetAddressAtIndex
