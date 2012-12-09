// memerror.m -- try to find (and fix!) all the memory-related errors in
//               this program

// Take a string from the command line.  Make a linked-list out of it in
// reverse order.  Traverse it to construct a string in reverse.  Then clean
// up afterwards.

// clang -g -Wno-format -o memerror memerror.m

#import <stdio.h>
#import <stdlib.h>
#import <string.h>

typedef struct CharNode {
    char theChar;
    struct CharNode *next;
} CharNode;

// Build a linked list backwards, then walk the list.
void reverseIt (char *stringbuffer) {
    CharNode *head, *node;
    char *scan, *stop;
    
    // Clear out local vars
    head = node = NULL;

    // Find the start and end of the string so we can walk it
    scan = stringbuffer;
    stop = stringbuffer + strlen(stringbuffer) + 1;  // trailing null

    // Walk the string
    while (scan < stop) {
	if (head == NULL) {
	    head = malloc (sizeof(CharNode*));
	    head->theChar = *scan;
	    head->next = NULL;
	} else {
	    node = malloc (sizeof(CharNode*));
	    node->theChar = *scan;
	    node->next = head;
	    head = node;
	}
	scan++;
    }

    // Ok, re-point to the buffer so we can drop the characters
    scan = stringbuffer;

    // Walk the nodes and add them to the string
    while (head != NULL) {
	*scan = head->theChar;
	free (head);
	node = head->next;
	head = node;
	scan++;
    }

    // Clean up the head
    free (head);
    
} // reverseIt


int main (int argc, char *argv[]) {
    char *stringbuffer;

    // Make sure the user supplied enough arguments.  If not, complain.
    if (argc != 2) {
	fprintf (stderr, "usage: %s string.  This reverses the string "
		 "given on the command line\n");
        return 1;
    }

    // Make a copy of the argument so we can make changes to it.
    stringbuffer = malloc (strlen(argv[1]));
    strcpy (argv[1], stringbuffer);

    // reverse the string
    reverseIt (stringbuffer);

    // and print it out
    printf ("the reversed string is '%s'\n", *stringbuffer);

    return 0;
} // main


