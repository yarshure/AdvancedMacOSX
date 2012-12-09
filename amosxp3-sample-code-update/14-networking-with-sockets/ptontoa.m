// ptontoa.m -- Exercise inet_pton and inet_ntop

// clang -g -Weverything -Wno-cast-align -o ptontoa ptontoa.m

#import <arpa/inet.h>  // for inet_*
#import <errno.h>      // for errno
#import <netinet/in.h> // for in_addr and in6_addr
#import <stdio.h>      // for printf()
#import <stdlib.h>     // for EXIT_SUCCESS
#import <string.h>     // for strerror
#import <sys/socket.h> // for AF_INET[6]
#import <sys/types.h>  // for type definitions, like u_char

// Convert an IPv6 address to a string.
static const char *in6ToChar (struct in6_addr *addr) {
    static char s_address[INET6_ADDRSTRLEN];

    uint32_t *base = (uint32_t *)addr->s6_addr;

    snprintf(s_address, sizeof(s_address), "%x%x%x%x", 
             ntohl(base[0]), ntohl(base[1]), ntohl(base[2]), ntohl(base[3]));
    return s_address;
} // in6ToChar


int main (void) {

    // --------------------------------------------------
    // IPv4

    // Convert from presentation to numeric, inet_name -> inet_addr
    char inet_name[INET_ADDRSTRLEN];
    strncpy (inet_name, "192.168.254.123", INET_ADDRSTRLEN);
    inet_name[INET_ADDRSTRLEN - 1] = '\0';

    struct in_addr inet_addr;
    int result = inet_pton (AF_INET, inet_name, &inet_addr);

    if (result == 1) {
        printf("address '%s' in binary: %x\n", 
               inet_name, ntohl(inet_addr.s_addr));
    } else if (result == 0) {
        printf("*** address '%s' not parsable\n\n", inet_name);
    } else {
        printf("*** inet_pton: error %d: %s\n",
               errno, strerror(errno));
    }

    // Convert from numeric to presentation, inet_addr -> inet_name
    const char *ntop_result = inet_ntop (AF_INET, &inet_addr, 
                                        inet_name, sizeof(inet_name));

    if (ntop_result != NULL) {  // ntop_result == inet_name
        printf ("address '%x' presentation: '%s'\n", 
                ntohl(inet_addr.s_addr), inet_name);
    } else {
        printf ("*** inet_ntop: error %d: %s\n",
                errno, strerror(errno));
    }

    // --------------------------------------------------
    // IPv6

    // Convert from presentation to numeric,  inet6_name -> inet6_addr
    char inet6_name[INET6_ADDRSTRLEN];
    strncpy (inet6_name, "FE80:0000:0000:0000:0230:65FF:FE06:6523",
             INET6_ADDRSTRLEN);
    inet6_name[INET6_ADDRSTRLEN - 1] = '\0';

    struct in6_addr inet6_addr;
    result = inet_pton (AF_INET6, inet6_name, &inet6_addr);
 
    if (result == 1) {
        printf ("address '%s'\n    in binary: %s\n", 
                inet6_name, in6ToChar(&inet6_addr));
    } else if (result == 0) {
        printf ("*** address '%s' not parsable\n\n", inet_name);
    } else {
        printf ("*** inet_pton: error %d: %s\n",
                errno, strerror(errno));
    }

    // Convert from numeric to presentation, inet6_addr -> inet6_name
    ntop_result = inet_ntop (AF_INET6, &inet6_addr, 
                             inet6_name, sizeof(inet6_name));

    if (ntop_result != NULL) {
        printf("address '%s'\n    presentation: '%s'\n", 
               in6ToChar(&inet6_addr), inet6_name);
    } else {
        printf("*** inet_ntop: error %d: %s\n",
               errno, strerror(errno));
    }
    return EXIT_SUCCESS;
}  // main
