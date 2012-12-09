// resolve.m -- resolve an address using gethostbyname2()

// clang -g -Weverything -o resolve resolve.m

#import <arpa/inet.h>   // for inet_ntop
#import <netdb.h>       // for gethostbyname
#import <netinet/in.h>  // constants and types
#import <stdio.h>       // for fprintf
#import <stdlib.h>      // for EXIT_SUCCESS
#import <sys/socket.h>  // for AF_INET
#import <sys/types.h>   // random types
    
static void PrintHostEnt (const struct hostent *host) {
    // First the name.
    printf("    official name: %s\n", host->h_name);

    // Then any aliases.
    if (host->h_aliases[0] == NULL) printf ("    no aliases\n");
    else printf ("    has aliases\n");

    for (char **scan = host->h_aliases; *scan != NULL; ++scan) {
        printf ("        %s\n", *scan);
    }

    // The address type.
    const char *addressType = "UNKNOWN";
    if (host->h_addrtype == AF_INET) addressType = "AF_INET";
    else if (host->h_addrtype == AF_INET6) addressType = "AF_INET6";

    printf ("    addrtype: %d (%s)\n", host->h_addrtype, addressType);

    // Walk h_addr_list and print the addresses
    if (host->h_addr == NULL) printf ("    no addresses\n");
    else printf ("    addresses:\n");

    for (char **scan = host->h_addr_list; *scan != NULL; scan++) {
        char addr_name[INET_ADDRSTRLEN];
        if (inet_ntop(host->h_addrtype, *scan, addr_name, sizeof(addr_name))) {
            printf ("        %s\n", addr_name);
        }
    }

} // PrintHostEnt

int main(int argc, char *argv[]) {
    const char *hostname;
    if (argc == 1) hostname = "www.apple.com";
    else           hostname = argv[1];

    struct hostent *hostinfo = gethostbyname2 (hostname, AF_INET);

    if (hostinfo == NULL) {
        fprintf (stderr, "gethostbyname2(%s): *** error %s\n",
                 hostname, hstrerror(h_errno));
        return EXIT_FAILURE;
    }

    printf ("gethostbyname2: %s\n", hostname);
    PrintHostEnt (hostinfo);

    return EXIT_SUCCESS;

} // main



