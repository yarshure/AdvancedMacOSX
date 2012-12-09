// simpleclient.m -- read from stdin and send to the simpleserver

// clang -g -Weverything -Wno-cast-align -o simpleclient simpleclient.m

#import <arpa/inet.h>   // for inet_ntop
#import <errno.h>       // errno
#import <netdb.h>       // gethostbyname2(), h_errno, etc.
#import <netinet/in.h>  // sockaddr_in
#import <stdbool.h>     // true/false
#import <stdio.h>       // fprintf()
#import <stdlib.h>      // EXIT_SUCCESS
#import <string.h>      // strerror()
#import <sys/socket.h>  // socket(), AF_INET
#import <sys/types.h>   // random types
#import <unistd.h>      // close()

static const in_port_t kPortNumber = 2342;

static int SocketConnectedToHostNamed (const char *hostname);
static bool GetAddressAtIndex (struct hostent *host, int addressIndex,
                               struct sockaddr_storage *outServerAddress);

int main (int argc, char *argv[]) {
    int exit_code = EXIT_FAILURE;
    int sockfd = -1;

    // Get the host name.
    if (argc != 2) {
        fprintf (stderr, "Usage: %s hostname\n", argv[0]);
        goto cleanup;
    }

    const char *hostname = argv[1];

    // Get a connected socket.
    sockfd = SocketConnectedToHostNamed(hostname);
    if (sockfd == -1) {
        fprintf (stderr, "*** Unable to connect to %s port %d.\n",
                 hostname, (int)kPortNumber);
        return EXIT_FAILURE;
    }
    printf ("[connected to %s port %d]\n", hostname, (int)kPortNumber);

    // Echo lines from stdin to sockfd.

    while (true) {
        char buffer[4096];
        const char *bytes = fgets (buffer, sizeof(buffer), stdin);

        // check EOF
        if (bytes == NULL) {
            if (ferror(stdin)) {
                perror("read");
                break;
            } else if (feof(stdin)) {
                fprintf(stderr, "EOF\n");
                break;
            }
        }

        ssize_t write_count = write(sockfd, buffer, strlen(buffer));
        if (write_count == -1) {
            perror("write");
            break;
        }
    }

    puts("[connection closed]");
    exit_code = EXIT_SUCCESS;

cleanup:
    close(sockfd);
    return exit_code;
}  // main


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

    outServerAddress->ss_family = (sa_family_t)host->h_addrtype;

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
    return true;
} // GetAddressAtIndex
