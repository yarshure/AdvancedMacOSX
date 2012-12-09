// testleak.m  -- leak memory and see what 'leaks' does.
// setenv MallocStackLogging 1
// in your environment before running, then run the program like
// leaks ./testleak

#import <stdlib.h>
#import <string.h> // for strcpy()
#import <stdio.h>  // for printf()
#import <unistd.h> // for getpid()

// clang -Weverything -Wno-padded -g -o testleak testleak.m

typedef struct LinkNode {
    struct LinkNode *next;
    char  nodeName[30];
} LinkNode;

static void leak2 () {
    char *astring;
    LinkNode *thing1, *thing2;

    astring = malloc (50);
    strcpy (astring, "hi there");

    astring = malloc (50);
    strcpy (astring, "greetings");

    thing1 = malloc (sizeof(LinkNode));
    thing2 = malloc (sizeof(LinkNode));
    
    strcpy (thing1->nodeName, "node 1");
    thing1->next = thing2;

    strcpy (thing2->nodeName, "node 2");
    thing2->next = thing1; // create a ciruclar list

} // leak2


static void leak1 ()
{
    leak2 ();
} // leak1


int main (void) {
    leak1 ();
    printf ("my process ID is %d.  Sleeping for 10 seconds\n", getpid());
    sleep (10);
    return 0;
} // main

