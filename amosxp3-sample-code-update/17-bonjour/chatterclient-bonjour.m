// chatterclient-bonjour.m -- client side of the chatter world

// clang -g -Weverything -Wno-unused-parameter -Wno-gnu -framework Foundation -o chatterclient-bonjour chatterclient-bonjour.m


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

@interface ChatterFinder : NSObject <NSNetServiceDelegate, NSNetServiceBrowserDelegate> {
    NSNetServiceBrowser *_browser;
    NSMutableArray *_services;
    BOOL _moreComing;

    NSNetService *_service;
    BOOL _resolved;
    BOOL _failed;
}
- (BOOL) discover;  // blocks
- (BOOL) resolve;   // blocks

- (NSMutableData *) address;

@end // ChatterFinder


/* Message Protocol */

// A message is length + data. The length is a single byte.
// The first message sent by a user has a max length of 8
// and sets the user's name.
#define MAX_MESSAGE_SIZE  UINT8_MAX
#define READ_BUFFER_SIZE  PAGE_SIZE

static const in_port_t kPortNumber = 2342;

// See simpleclient.m for the definition of these two functions.
int SocketConnectedToHostNamed(const char *host_name);
static bool GetAddressAtIndex(struct hostent *, int, struct sockaddr_storage *);

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
    int server_fd = -1;

    if (argc != 3) {
        fprintf(stderr, "Usage: chatterclient hostname(ignored) username\n");
        goto bailout;
    }

    // limit username to 8 characters
    const char *name = argv[2];
    ssize_t namelen = (ssize_t)strlen(name);
    if (namelen > 8) {
        fprintf (stderr, "*** Username must be 8 characters or fewer.\n");
        goto bailout;
    }

    // set stdin to non-blocking
    int err = fcntl(STDIN_FILENO, F_SETFL, O_NONBLOCK);
    if (err == -1) {
        perror("fcntl(stdin O_NONBLOCK)");
        goto bailout;
    }

#if 0
    // Get a connected socket.
    const char *host_name = argv[1];
    int server_fd = SocketConnectedToHostNamed(host_name);
    if (server_fd == -1) {
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

    NSMutableData *data = [finder address];
    if (!data) return -1;

    struct sockaddr *gen = [data mutableBytes];
    NSLog(@"family: %d", gen->sa_family);
    server_fd = socket(gen->sa_family, SOCK_STREAM, 0);
    if (server_fd == -1) return -1;

    NSLog(@"%s: Connecting...", __func__);
    err = connect(server_fd, (struct sockaddr *)[data mutableBytes],
                  (socklen_t)[data length]);
    if (err == -1) perror("connect");
    NSLog(@"%s: Connected!", __func__);

    [finder release], finder = nil;
    [pool drain];

    ssize_t nwritten = WriteMessage(server_fd, (const unsigned char *)name, namelen);
    if (nwritten == -1) {
        perror("*** Unable to write username");
        goto bailout;
    }

    // now set to non-block
    err = fcntl(server_fd, F_SETFL, O_NONBLOCK);
    if (err == -1) {
        perror("fcntl(server_fd O_NONBLOCK)");
        goto bailout;
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

        if (nready == -1) {
            perror("select");
            continue;
        }

        const bool stdin_ready = FD_ISSET(STDIN_FILENO, &readfds);
        if (stdin_ready) {
            ssize_t nread = read(STDIN_FILENO, msgbuf, sizeof(msgbuf));
            if (nread == -1) {
                perror("read(stdin)");
                goto bailout;
            } else if (nread == 0) {
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

            nwritten = WriteMessage(server_fd, (unsigned char *)msgbuf, nread);
            if (nwritten == -1) {
                // WriteMessage logged the error for us.
                goto bailout;
            }
        }

        const bool server_ready = FD_ISSET(server_fd, &readfds);
        if (server_ready) {
            // Read at most 1 less than the buffer size so we can
            // always null-terminate.
            ssize_t nread = read(server_fd, server_buffer,
                                 sizeof(server_buffer) - 1);
            if (nread == -1) {
                perror("read(server_fd)");
                goto bailout;
            } else if (nread == 0) {
                fprintf(stderr, "[Server closed connection.]\n");
                break;
            } else {
                server_buffer[nread] = '\0';
                printf("%s", server_buffer);
            }
        }
    }

    exit_status = EXIT_SUCCESS;

bailout:
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


@implementation ChatterFinder

- (id) init {
    if ((self = [super init])) {
        _services = [[NSMutableArray alloc] init];
    }
    return self;
} // init


- (void) dealloc {
    [_services release];
    _services = nil;
    [_browser release];
    _browser = nil;

    [super dealloc];

} // dealloc


- (BOOL)discover {
    _browser = [[NSNetServiceBrowser alloc] init];
    [_browser setDelegate:self];

    _moreComing = YES;

    NSLog(@"%s: discovering...", __func__);

    [_browser searchForServicesOfType:@"_chatter._tcp."
             inDomain:@"local."];

    while (_moreComing) {
        [[NSRunLoop currentRunLoop]
            runUntilDate: [NSDate dateWithTimeIntervalSinceNow:0.5]];
    }

    BOOL foundSome = [_services count] > 0;
    return foundSome;

} // discover

- (void)netServiceBrowserWillSearch: (NSNetServiceBrowser *) browser {
    NSLog(@"%s: %@ will search.", __func__, browser);
} // willSearch


- (void)netServiceBrowser: (NSNetServiceBrowser *) browser
           didFindService: (NSNetService *) service
               moreComing: (BOOL) moreComing {
    NSLog(@"%s: %@: %@ (%d)", __func__, browser, service, (int)moreComing);
    _moreComing = moreComing;
    [_services addObject: service];

} // didFindService


- (void)netServiceBrowser: (NSNetServiceBrowser *) browser
         didRemoveService: (NSNetService *) service
               moreComing: (BOOL) moreComing {
    NSLog(@"%s: %@: %@ (%d)", __func__, browser, service, (int)moreComing);
    _moreComing = moreComing;
    [_services removeObject: service];

} // didRemoveService


- (BOOL)resolve {
    if (![_services count]) return NO;

    _resolved = NO;
    _failed = NO;

    _service = [_services objectAtIndex:0];
    [_service setDelegate:self];

    NSLog(@"%s: resolving %@...", __func__, _service);

    [_service resolveWithTimeout:5];

    while (!_resolved && !_failed) {
        [[NSRunLoop currentRunLoop]
            runUntilDate: [NSDate dateWithTimeIntervalSinceNow:0.5]];
    }
    NSLog(@"%s: resolved? %d failed? %d", __func__, (int)_resolved, (int)_failed);

    return _resolved;
} // resolve


- (void) netServiceWillResolve: (NSNetService *) service {
    NSLog (@"%s: %@", __func__, service);
} // willResolve


- (void) netService: (NSNetService *) service  didNotResolve: (NSDictionary *) data {
    NSLog (@"%s: *** %@: %@", __func__, service, data);
    _failed = YES;
}// didNotResolve


- (void) netServiceDidResolveAddress: (NSNetService *) service {
    NSLog (@"%s: %@", __func__, service);
    _resolved = YES;
} // netServiceDidResolveAddress


- (NSMutableData *) address {
    if (_failed) return nil;
    if (!_resolved && ![self resolve]) return nil;

    NSData *foundData = nil;
    NSArray *array = [_service addresses];

    for (NSData *data in array) {
        const struct sockaddr *gen = [data bytes];
        int fam = gen->sa_family;
        NSLog(@"%s: family %d", __func__, fam);
        if (AF_INET == fam) {
            foundData = data;
            break;
        }
    }

    if (!foundData) return nil;

    return [NSMutableData dataWithData: foundData];
} // address

@end // ChatterFinder
