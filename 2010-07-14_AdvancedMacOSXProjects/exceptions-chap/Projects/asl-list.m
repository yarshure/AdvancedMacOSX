// asl-list.m -- show what asl messages have been logged so far

#import <asl.h>		// for ASL API
#import <stdio.h>	// for printf()

/*
cc -g -Wmost -o asl-list asl-list.m
*/

void dumpAslMsg (aslmsg message)
{
    // walk the keys and values in each message
    const char *key, *value;
    int i = 0;
    while (key = asl_key (message, i)) {
        value = asl_get (message, key);
        printf ("%d: %s => %s\n", i, key, value);
        i++;
    }

} // dumpAslMsg


int main (void)
{
    // construct a query for all senders using a regular expression that
    // matches everything
    aslmsg query;
    query = asl_new (ASL_TYPE_QUERY);
    asl_set_query (query, ASL_KEY_SENDER, "", ASL_QUERY_OP_TRUE);

    // perform the search
    aslresponse results = asl_search (NULL, query);

    // walk the returned messages
    aslmsg message;
    while (message = aslresponse_next(results)) {
        dumpAslMsg (message);
        printf ("----------------------------------------\n");
    }

    aslresponse_free (results);
    asl_free (query);

    return (0);

} // main
