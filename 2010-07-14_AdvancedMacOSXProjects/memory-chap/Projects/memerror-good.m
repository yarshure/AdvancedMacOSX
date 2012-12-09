// memerror.h -- try to find (and fix!) all the memory-related errors in
//               this program


// take a string from the command line.  make a linked-list out of it in
// reverse order.  traverse it to construct a string in reverse.  Then clean
// up afterwards.

/* compile with
cc -g -Wmost -o memerror memerror.m
*/

#import <stdio.h>
#import <stdlib.h>

typedef struct CharNode {
    char theChar;
    struct CharNode *next;
} CharNode;


// build a linked list backwards, then walk the list.

void reverseIt (char *stringbuffer)
{
    CharNode *head, *node;
    char *scan, *stop;
    
    // clear out local vars
    head = node = NULL;

    // find the start and end of the string so we can walk it
    scan = stringbuffer;
    stop = stringbuffer + strlen(stringbuffer); // +++ add one for trailing 0x00

    // walk the string
    while (scan < stop) {
	if (head == NULL) {
	    head = malloc (sizeof(CharNode)); // +++ make sizeof(CharNode*)
	    head->theChar = *scan;
	    head->next = NULL;
	} else {
	    node = malloc (sizeof(CharNode)); // +++ ditto(e)
	    node->theChar = *scan;
	    node->next = head;
	    head = node;
	}
	scan++;
    }

    // ok, re-point to the buffer so we can drop the characters
    scan = stringbuffer;

    // walk the nodes and add them to the string
    while (head != NULL) {
	*scan = head->theChar;
	node = head->next;
	free (head); // +++ reverse with one above it
	head = node;
	scan++;
    }

    // +++ add a free (head); here
    
} // reverseIt


int main (int argc, char *argv[])
{
    char *stringbuffer;

    // make sure the user supplied enough arguments.  If not, complain
    if (argc != 2) {
	fprintf (stderr, "usage: %s string.  This reverses the string "
		 "given on the command line\n", argv[0]);
	exit (1);
    }

    // make a copy of the argument so we can make changes to it
    stringbuffer = malloc (strlen(argv[1]) + 1); // +++ nuke +1
    strcpy (stringbuffer, argv[1]); // +++ maybe reverse args?

    // reverse the string
    reverseIt (stringbuffer);

    // and print it out
    printf ("the reversed string is '%s'\n", stringbuffer);

    free (stringbuffer); // +++ remove

    exit (0);

} // main


