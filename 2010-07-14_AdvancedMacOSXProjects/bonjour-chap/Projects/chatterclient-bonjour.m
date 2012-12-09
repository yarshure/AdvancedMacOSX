// chatterclient.m -- client side of the chatter world

/* compile with:
gcc -g -Wall -std=c99 -framework Foundation -o chatterclient-bonjour chatterclient-bonjour.m
*/

#import <stdbool.h>  // true/false
#import <stdint.h>   // UINT8_MAX
#import <stdio.h>    // fprintf()
#import <stdlib.h>   // EXIT_SUCCESS
#import <string.h>   // strerror()

#import <errno.h>   // errno
#import <fcntl.h>   // fcntl()
#import <mach/vm_param.h>  // PAGE_SIZE
#import <unistd.h>  // close()

#import <arpa/inet.h>     // inet_ntop()
#import <netdb.h>         // gethostbyname2()
#import <netinet/in.h>    // struct sockaddr_in
#import <netinet6/in6.h>  // struct sockaddr_in6
#import <sys/socket.h>    // socket(), AF_INET
#import <sys/types.h>     // random types

#import <Foundation/Foundation.h>
@interface ChatterFinder : NSObject {
 @public
    NSNetServiceBrowser *browser;
    NSMutableArray *services;
    BOOL moreComing;

    NSNetService *service;
    BOOL resolved;
    BOOL failed;
}
- (BOOL)discover;  // blocking
- (BOOL)resolve;
- (NSMutableData *)address;
@end

/* Message Protocol */
/*
 A message is length + data. The length is a single byte.
 The first message sent by a user has a max length of 8
 and sets the user's name.
 */
#ifndef MAX
#   define MAX(x, y) (((x) > (y))? (x) : (y))
#endif
#define MAX_MESSAGE_SIZE  (UINT8_MAX)
#define READ_BUFFER_SIZE  (PAGE_SIZE)
static const in_port_t kPortNumber = 2342;

// See simpleclient.m for the definition of these two functions.
int SocketConnectedToHostNamed(const char *host_name);
bool GetAddressAtIndex(struct hostent *, int, struct sockaddr_storage *);

// Returns -1 on failure, >= 0 on success.
static int
WriteMessage(int fd, const void *buffer, size_t length) {
    if (length > MAX_MESSAGE_SIZE) {
        fprintf(stderr, "*** Truncating message to %d bytes.\n",
                MAX_MESSAGE_SIZE);
        length = MAX_MESSAGE_SIZE;
    }

    // First, send the length byte.
    uint8_t nleft = (uint8_t)length;
    ssize_t nwritten = write(fd, &nleft,
                             sizeof(nleft));
    if (nwritten <= 0) {
        goto CantWrite;
    }

    // Then, send the string bytes.
    while(nleft > 0) {
        nwritten = write(fd, buffer, nleft);
        if (nwritten <= 0) goto CantWrite;

        nleft  -= nwritten;
        buffer += nwritten;
    }

CantWrite:
    if (-1 == nwritten) perror("write");
    return nwritten;
} // WriteMessage

int
main(int argc, char *argv[]) {
    int exit_status = EXIT_FAILURE;

    if (argc != 3) {
        fprintf(stderr, "Usage: chatterclient hostname username\n");
        goto BailOut;
    }

    // limit username to 8 characters
    const char *name = argv[2];
    size_t namelen = strlen(name);
    if (namelen > 8) {
        fprintf (stderr, "*** Username must be 8 characters or fewer.\n");
        goto BailOut;
    }

    // set stdin to non-blocking
    int err = fcntl(STDIN_FILENO, F_SETFL, O_NONBLOCK);
    if (-1 == err) {
        perror("fcntl(stdin O_NONBLOCK)");
        goto BailOut;
    }

#if 0
    // Get a connected socket.
    const char *host_name = argv[1];
    int server_fd = SocketConnectedToHostNamed(host_name);
    if (-1 == server_fd) {
        fprintf(stderr, "*** Unable to connect to %s port %d.\n",
                host_name, (int)kPortNumber);
        return EXIT_FAILURE;
    }
    printf("[connected to %s port %d]\n", host_name, (int)kPortNumber);
    // no need to bind() or listen()
#endif
    id pool = [[NSAutoreleasePool alloc] init];
    ChatterFinder *finder = [[ChatterFinder alloc] init];
    BOOL found = [finder discover];
    if (!found) {
        NSLog(@"*** No services found. Exiting.");
        return EXIT_FAILURE;
    }

    BOOL resolved = [finder resolve];
    if (!resolved) {
        NSLog(@"*** Resolution failed. Exiting.");
        return EXIT_FAILURE;
    }

    NSMutableData *d = [finder address];
    if (!d) return -1;

    struct sockaddr *gen = [d mutableBytes];
    NSLog(@"family: %d", gen->sa_family);
    int server_fd = socket(gen->sa_family, SOCK_STREAM, 0);
    if (-1 == server_fd) return -1;

    NSLog(@"%s: Connecting...", __func__);
    err = connect(server_fd, (struct sockaddr *)[d mutableBytes], [d length]);
    if (-1 == err) perror("connect");
    NSLog(@"%s: Connected!", __func__);

    [finder release], finder = nil;
    [pool drain];

    int nwritten = WriteMessage(server_fd, name, namelen);
    if (-1 == nwritten) {
        perror("*** Unable to write username");
        goto BailOut;
    }

    // now set to non-block
    err = fcntl(server_fd, F_SETFL, O_NONBLOCK);
    if (-1 == err) {
        perror("fcntl(server_fd O_NONBLOCK)");
        goto BailOut;
    }

    char server_buffer[READ_BUFFER_SIZE];
    char msgbuf[MAX_MESSAGE_SIZE];
    while(true) {

        fd_set readfds;
        FD_ZERO(&readfds);
        FD_SET(STDIN_FILENO, &readfds);
        FD_SET(server_fd, &readfds);
        int max_fd = MAX(STDIN_FILENO, server_fd);

        int nready = select(max_fd + 1, &readfds, NULL, NULL, NULL);

        if (-1 == nready) {
            perror("select");
            continue;
        }

        const bool stdin_ready = FD_ISSET(STDIN_FILENO, &readfds);
        if (stdin_ready) {
            int nread = read(STDIN_FILENO, msgbuf, sizeof(msgbuf));
            if (-1 == nread) {
                perror("read(stdin)");
                goto BailOut;
            } else if (0 == nread) {
                // closed
                break;
            }

#if 0
            // Drop any final newline or carriage return.
            while ('\n' == msgbuf[nread - 1]
                   || '\r' == msgbuf[nread - 1]) {
                nread -= 1;
            }
#endif

            nwritten = WriteMessage(server_fd, msgbuf, nread);
            if (-1 == nwritten) {
                // WriteMessage logged the error for us.
                goto BailOut;
            }
        }

        const bool server_ready = FD_ISSET(server_fd, &readfds);
        if (server_ready) {
            // Read at most 1 less than the buffer size so we can
            // always null-terminate.
            int nread = read(server_fd, server_buffer,
                             sizeof(server_buffer) - 1);
            if (-1 == nread) {
                perror("read(server_fd)");
                goto BailOut;
            } else if (0 == nread) {
                fprintf(stderr, "[Server closed connection.]\n");
                break;
            } else {
                server_buffer[nread] = '\0';
                printf("%s", server_buffer);
            }
        }
    }

    exit_status = EXIT_SUCCESS;

BailOut:
    if (server_fd > -1) close(server_fd);
    return (exit_status);

} // main

/* * * THESE DON'T GET COPIED INTO THE BOOK AT THIS POINT * * */
/* They were already printed with simpleclient.m; we're just reusing them. */
// Returns -1 on failure, >= 0 on success.
int
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
}  // SocketConnectedToHostNamed

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
}  // GetAddressAtIndex

@implementation ChatterFinder
- (id)init {
    self = [super init];
    if (!self) return nil;
    services = [[NSMutableArray alloc] init];
    return self;
}

- (void)dealloc {
    [services release], services = nil;
    [browser release], browser = nil;
    [super dealloc];
}

- (BOOL)discover {
    browser = [[NSNetServiceBrowser alloc] init];
    [browser setDelegate:self];
    moreComing = YES;
    NSLog(@"%s: discovering...", __func__);
    [browser searchForServicesOfType:@"_chatter._tcp."
                            inDomain:@"local."];
    while (moreComing)
        [[NSRunLoop currentRunLoop] runUntilDate:
         [NSDate dateWithTimeIntervalSinceNow:0.5]];
    return ([services count] > 0);
}

- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)b {
    NSLog(@"%s: %@ will search.", __func__, b);
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)b didFindService:(NSNetService *)s moreComing:(BOOL)c {
    moreComing = c;
    NSLog(@"%s: %@: %@ (%d)", __func__, b, s, (int)c);
    [services addObject:s];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)b didRemoveService:(NSNetService *)s moreComing:(BOOL)c {
    NSLog(@"%s: %@: %@ (%d)", __func__, b, s, (int)c);
    moreComing = c;
    [services removeObject:s];
}

- (BOOL)resolve {
    if (![services count]) return NO;
    resolved = NO;
    failed = NO;
    service = [services objectAtIndex:0];
    [service setDelegate:self];
    NSLog(@"%s: resolving %@...", __func__, service);
    [service resolveWithTimeout:5];
    while (!resolved && !failed)
        [[NSRunLoop currentRunLoop] runUntilDate:
         [NSDate dateWithTimeIntervalSinceNow:0.5]];
    NSLog(@"%s: resolved? %d failed? %d", __func__, (int)resolved, (int)failed);
    return resolved;
}

- (void)netServiceWillResolve:(NSNetService *)s {
    NSLog(@"%s: %@", __func__, s);
}

- (void)netService:(NSNetService *)s didNotResolve:(NSDictionary *)d {
    NSLog(@"%s: *** %@: %@", __func__, s, d);
    failed = YES;
}

- (void)netServiceDidResolveAddress:(NSNetService *)s {
    NSLog(@"%s: %@", __func__, s);
    resolved = YES;
}

- (NSMutableData *)address {
    if (failed) return nil;
    if (!resolved && ![self resolve]) return nil;

    NSData *d = nil;
    NSArray *a = [service addresses];
    for (NSData *data in a) {
        const struct sockaddr *gen = [data bytes];
        int fam = gen->sa_family;
        NSLog(@"%s: family %d", __func__, fam);
        if (AF_INET == fam) {
            d = data;
            break;
        }
    }

    if (!d) return nil;

    return [NSMutableData dataWithData:d];
}
@end
// vi: set et ts=4 sw=4:
