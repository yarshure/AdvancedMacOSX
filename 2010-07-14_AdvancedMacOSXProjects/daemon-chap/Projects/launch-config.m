#import <stdio.h>   // for printf()
#import <launch.h>  // for launchd API
#import <string.h>  // for strerror
#import <errno.h>   // for errno
#import <stdlib.h>  // for EXIT_SUCCESS
#import <unistd.h>  // for sleep()

/* compile with
gcc -g -Wall -o launch-config launch-config.m
*/

/* schedule with
launchctl load ./launch-config.plist 
launchctl unload ./launch-config.plist 
*/

static int g_depth;

void printPad ()
{
    int i;
    for (i = 0; i < g_depth; i++) {
        printf ("  ");
    }

} // printPad


void printLaunchData (launch_data_t data);


void dictPrinter (launch_data_t value, const char *key, void *context)
{
    printPad ();
    printf ("key: %s\n", key);

    launch_data_t lookup;
    lookup = launch_data_dict_lookup (value, key);

    g_depth++;
    printLaunchData (value);
    g_depth--;

} // dictPritner


void printLaunchData (launch_data_t data)
{

    switch (launch_data_get_type(data)) {
    case LAUNCH_DATA_DICTIONARY:
        printPad ();
        printf ("dictionary\n");
        g_depth++;
        launch_data_dict_iterate (data, dictPrinter, NULL);
        g_depth--;
        break;

    case LAUNCH_DATA_ARRAY: {
        size_t count = launch_data_array_get_count (data);
        printPad ();
        printf ("array (elements: %d)\n", (int)count);
        int i;
        for (i = 0; i < count; i++) {
            launch_data_t thing;
            thing = launch_data_array_get_index (data, i);
            g_depth++;
            printLaunchData (thing);
            g_depth--;
        }
        break;
    }

    case LAUNCH_DATA_FD:
        printPad ();
        printf ("fd: %d\n", launch_data_get_fd(data));
        break;

    case LAUNCH_DATA_INTEGER:
        printPad ();
        printf ("integer: %lld\n", launch_data_get_integer(data));
        break;

    case LAUNCH_DATA_REAL:
        printPad ();
        printf ("real: %f\n", );
        break;

    case LAUNCH_DATA_BOOL:
        printPad ();
        printf ("bool\n");
        break;

    case LAUNCH_DATA_STRING:
        printPad ();
        printf ("string\n");
        break;

    case LAUNCH_DATA_OPAQUE:
        printPad ();
        printf ("opaque\n");
        break;

    case LAUNCH_DATA_ERRNO:
        printPad ();
        printf ("errno\n");
        break;

    default:
        printf ("unexpected data: %d", launch_data_get_type(data));
        break;
    }

} // printLaunchData




int main (void)
{
    int result = EXIT_FAILURE;

    // looks like this only works if your parent pid is 1
    launch_data_t message;
    message = launch_data_new_string (LAUNCH_KEY_CHECKIN);

    launch_data_t response;
    response = launch_msg (message);

    if (response == NULL) {
        printf ("could not check in\n");
        goto done;
    } else {
        printf ("successfully checked in\n");
    }


#if 0

    launch_data_t message;
    message = launch_data_alloc (LAUNCH_DATA_DICTIONARY);
    launch_data_dict_insert (message,
                             launch_data_new_string
                             ("com.bignerdranch.launchconfig"),
                             LAUNCH_KEY_GETJOB);

    launch_data_t response;
    response = launch_msg (message);

    if (response == NULL) {
        printf ("could not get job stuff\n");
        goto done;
    }
#endif

    switch (launch_data_get_type(response)) {
    case LAUNCH_DATA_ERRNO:
        errno = launch_data_get_errno (response);
        printf ("errno on checkin: %d/%d/%s\n", 
                getuid(), errno, strerror(errno));
        goto done;
    case LAUNCH_DATA_DICTIONARY:
        break;
    default:
        printf ("unknown type in response\n");
        goto done;
    }


    launch_data_t sockets;
    sockets = launch_data_dict_lookup (response, LAUNCH_JOBKEY_SOCKETS);

    if (sockets == NULL) {
        printf ("could not look up sockets\n");
        goto done;
    }

    printLaunchData (sockets);

    printf ("woo!\n");
    fflush (stdout);
    sleep (10);

    result = EXIT_SUCCESS;

done:
    if (message != NULL) {
        launch_data_free (message);
    }
    if (response != NULL) {
        launch_data_free (response);
    }

    return (result);

} // main

