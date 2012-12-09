// nodepool.m -- A simple memory pool for vending like-size pieces of
//               memory.  An example of custom memory management.

//gcc -Wall -g -O1 -framework Foundation -o nodepool nodepool.m

#import <Foundation/Foundation.h>
#import <stdio.h>
#import <stdlib.h>

// The free list that runs through all the blocks
typedef struct BWPoolElement {
    struct BWPoolElement *next;
} BWPoolElement;

@interface BWNodePool : NSObject {
    unsigned char  *memblock; // A big blob of bytes.
    BWPoolElement  *freelist;
    size_t          nodeSize;
    size_t          count;
}

- (id) initWithNodeSize: (size_t) nodeSize  count: (size_t) count;
- (void *) allocNode;
- (void) freeNode: (void *) nodePtr;

@end // BWNodePool


@implementation BWNodePool

- (void) weaveFreeListFrom: (unsigned char *) startAddress  
                  forCount: (size_t) theCount {
    unsigned char *scan = startAddress;
    int i;
    for (i = 0; i < theCount; i++) {
        if (freelist == NULL) {
            freelist = (BWPoolElement *) scan;
            freelist->next = NULL;
        } else {
            BWPoolElement *temp = (BWPoolElement*) scan;
            temp->next = freelist;
            freelist = temp;
        }
        scan += nodeSize;
    }
} // weaveFreeListFrom


- (id) initWithNodeSize: (size_t) theNodeSize  count: (size_t) theCount {
    if ((self = [super init])) {
        nodeSize = theNodeSize;
        count = theCount;

        // Make sure there's enough space to store the pointers for the
        // freelist.
        if (nodeSize < sizeof(BWPoolElement)) {
            nodeSize = sizeof(BWPoolElement);
        }
        
        // Allocate memory for the block.
        memblock = malloc (nodeSize * count);

        // Walk through the block building the freelist.
        [self weaveFreeListFrom: memblock  forCount: theCount];
    }

    return (self);

} // initWithNodeSize


- (void) dealloc {
    free (memblock);
    [super dealloc];
} // dealloc


- (void *) allocNode {
    if (freelist == NULL) {
        // We're out of space, so just throw our hands up and
        // surrender for now.  You can add pool growing by keeping an
        // array of memblocks and creating a new one when the previous
        // block fills up.
        fprintf (stderr, "out of space in node pool.  Giving up\n");
        abort ();
    }

    // take a new node off of the freelist
    void *newNode = freelist;
    freelist = freelist->next;

    return (newNode);

} // allocNode


- (void) freeNode: (void *) nodePtr {
    // Stick the freed node at the head of the freelist.
    ((BWPoolElement *)nodePtr)->next = freelist;
    freelist = nodePtr;
} // freeNode

@end // BWNodePool


// The node we're using the nodepool for.
#define NODE_BUF_SIZE 137
typedef struct ListNode {
    int                 someData;
    struct ListNode    *next;
} ListNode;

void haveFunWithPool (int nodeCount) {
    NSLog (@"Creating nodes with the node pool");

    BWNodePool *nodePool =
        [[BWNodePool alloc] initWithNodeSize: sizeof(ListNode)
                            count: nodeCount];
    ListNode *head, *node, *prev;
    head = node = prev = NULL;
    int i;
    for (i = 0; i < nodeCount; i++) {
        node = [nodePool allocNode];
        node->someData = i;
	// If you wish, you can do some extra work.  This function call

        // Some bookkeeping so we can clean up afterwards.
        node->next = prev;
        prev = node;
    }
    head = node;

    NSLog (@"Cleaning up");
    [nodePool release];

    NSLog (@"Done");

} // haveFunWithPool


void haveFunWithMalloc (int nodeCount) {
    NSLog (@"Creating nodes with malloc");

    ListNode *head, *node, *prev;
    head = node = prev = NULL;
    int i;
    for (i = 0; i < nodeCount; i++) {
        node = malloc (sizeof(ListNode));
        node->someData = i;
	// If you wish, you can do some extra work.  This function call

        // Some bookkeeping so we can clean up afterwards.
        node->next = prev;
        prev = node;
    }
    head = node;

    NSLog (@"Cleaning up");
    while (head != NULL) {
        ListNode *node = head;
        head = head->next;
        free (node);
    }

    NSLog (@"Done");

} // haveFunWithMalloc


int main (int argc, char *argv[]) {
    int count;

    if (argc != 3) {
        fprintf (stderr, "usage: %s -p|-m #\n", argv[0]);
        fprintf (stderr, "       exercise memory allocation\n");
        fprintf (stderr, "       -p to use a memory pool\n");
        fprintf (stderr, "       -m to use malloc\n");
        fprintf (stderr, "       #  number of nodes to play with\n");
        return 1;
    }
    count = atoi (argv[2]);

    if (strcmp(argv[1], "-p") == 0) {
        haveFunWithPool (count);
    } else {
        haveFunWithMalloc (count);
    }

    return 0;

} // main
