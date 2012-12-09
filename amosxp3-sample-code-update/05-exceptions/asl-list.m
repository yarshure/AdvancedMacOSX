// asl-list.m -- show what asl messages have been logged so far

// clang -g -Weverything -o asl-list asl-list.m

#import <asl.h>         // for ASL API
#import <stdlib.h>      // for EXIT_SUCCESS
#import <stdio.h>       // for printf()

static void dumpAslMsg (aslmsg message) {
    // walk the keys and values in each message
    const char *key, *value;

    uint32_t i = 0;
    while ((key = asl_key (message, i))) {
        value = asl_get (message, key);
        printf ("%u: %s -> %s\n", i, key, value);
        i++;
    }
} // dumpAslMsg


int main (void) {
    // Construct a query for all senders using a regular expression
    // that matches everything.
    aslmsg query;
    query = asl_new (ASL_TYPE_QUERY);
    asl_set_query (query, ASL_KEY_SENDER, "", ASL_QUERY_OP_TRUE);

    // Perform the search.
    aslresponse results = asl_search (NULL, query);

    // walk the returned messages
    aslmsg message;
    while ((message = aslresponse_next(results))) {
        dumpAslMsg (message);
        printf ("----------------------------------------\n");
    }

    aslresponse_free (results);
    asl_free (query);

    return EXIT_SUCCESS;
} // main
