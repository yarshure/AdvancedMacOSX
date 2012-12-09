// asl-log-n-query.m -- do some logs and some queries

#import <asl.h>      // for ASL function
#import <stdio.h>    // for printf()
#import <stdlib.h>   // for EXIT_SUCCESS
#import <syslog.h>   // for LOG_ constants
#import <inttypes.h> // for printf constant PRIu32

// clang -g -Weverything -o asl-log-n-query asl-log-n-query.m

static void dumpAslMsg(aslmsg message) {
    // walk the keys and values in each message
    const char *key, *value;
    uint32_t i = 0;
    while ((key = asl_key(message, i))) {
        value = asl_get (message, key);
        printf ("%u: %s => %s\n", i, key, value);
        i++;
    }
} // dumpAslMsg


int main(void) {
    // Perform a simple log.
    asl_log (NULL, NULL, LOG_NOTICE, "Hello how are %s today?", "you");

    // Make a template message with our custom tags
    aslmsg template = asl_new (ASL_TYPE_MSG);
    asl_set (template, "Suit", "(4A)CGS");

    // Log some messages.
    asl_log (NULL, template, LOG_NOTICE, "Laurel has suited up");
    asl_log (NULL, template, LOG_NOTICE, "Alex has suited up");

    // Do a query to see how many times Alex has worn his (4A)CGS suit

    aslmsg query = asl_new (ASL_TYPE_QUERY);

    asl_set_query (query, "Suit", "(4A)CGS", ASL_QUERY_OP_EQUAL);
    asl_set_query (query, ASL_KEY_MSG, "Alex",
                   ASL_QUERY_OP_EQUAL | ASL_QUERY_OP_PREFIX);

    // Perform the search.
    aslresponse results = asl_search(NULL, query);

    // Walk the returned messages.
    aslmsg message = NULL;
    while ((message = aslresponse_next(results))) {
        dumpAslMsg(message);
        printf ("----------------------------------------\n");
    }

    // Cleanup.
    aslresponse_free (results);
    asl_free (query);
    asl_free( template);

    return EXIT_SUCCESS;
} // main
 
