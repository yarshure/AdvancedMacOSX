// resolve.m -- resolve an address using gethostbyname2()

//gcc -std=c99 -g -Wall -o resolve resolve.m


#import <stdio.h>       // for fprintf
#import <stdlib.h>      // for EXIT_SUCCESS
#import <stdbool.h>     // true/false

#import <arpa/inet.h>   // for inet_ntop
#import <netinet/in.h>  // constants and types
#import <netdb.h>       // for gethostbyname
#import <sys/types.h>   // random types
#import <sys/socket.h>  // for AF_INET

static void PrintHostEnt(const struct hostent *);

int
main(int argc, char *argv[]) {
    const char *host_name = ((argc > 1)? argv[1] : "www.apple.com");

    struct hostent *host_info = gethostbyname2(host_name, AF_INET);

    if (NULL == host_info) {
        fprintf (stderr, "gethostbyname2(%s): *** error %s\n",
                 host_name, hstrerror(h_errno));
        return EXIT_FAILURE;
    }

    printf("gethostbyname2 %s\n", host_name);
    PrintHostEnt(host_info);
    return EXIT_SUCCESS;
} // main


static void
PrintHostEnt(const struct hostent *host) {
    // h_name
    printf("    official name: %s\n", host->h_name);

    // h_aliases
    const bool hasAliases = (NULL != host->h_aliases[0]);
    puts(hasAliases? "    aliases:" : "    no aliases");
    for (char **scan = host->h_aliases;
         NULL != *scan; ++scan) {
        printf ("        %s\n", *scan);
    }

    // h_addrtype
    printf ("    addrtype: %d (%s)\n", 
            host->h_addrtype,
            (host->h_addrtype == AF_INET ? "AF_INET" 
             : (host->h_addrtype == AF_INET6 ? "AF_INET6"
                : "UNKNOWN")));
    
    // h_addr_list
    const bool hasAddresses = (NULL != host->h_addr);
    puts(hasAddresses? "    addresses:" : "    no addresses");
    for (char **scan = host->h_addr_list;
         NULL != *scan; ++scan) {
        char addr_name[INET_ADDRSTRLEN];
        if (inet_ntop(host->h_addrtype, *scan,
                      addr_name, sizeof(addr_name))) {
            printf ("        %s\n", addr_name);
        }
    }

} // PrintHostEnt
