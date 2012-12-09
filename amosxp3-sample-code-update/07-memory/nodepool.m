// nodepool.m -- A simple memory pool for vending like-size pieces of
//               memory.  An example of custom memory management.

// clang -Weverything -g -Os -framework Foundation -o nodepool nodepool.m

#import <Foundation/Foundation.h>

#import <stdio.h>
#import <stdlib.h>

// The free list that runs through all the blocks
typedef struct BWPoolElement {
    struct BWPoolElement *next;
} BWPoolElement;

@interface BWNodePool : NSObject {
    void           *_memblock; // A big blob of bytes.
    BWPoolElement  *_freelist; // Pointer to the head of the freelist.
    size_t          _nodeSize;
    size_t          _nodeCount;
}

- (id) initWithNodeSize: (size_t) nodeSize  count: (size_t) count;
- (void *) allocNode;
- (void) freeNode: (void *) nodePtr;

@end // BWNodePool


@implementation BWNodePool

- (void) weaveFreeListFrom: (void *) startAddress  
                  forCount: (size_t) theCount {
    BWPoolElement *scan = startAddress;
    for (size_t i = 0; i < theCount; i++) {
        if (_freelist == NULL) {
            _freelist = scan;
            _freelist->next = NULL;
        } else {
            BWPoolElement *temp = scan;
            scan->next = _freelist;
            _freelist = temp;
        }
        scan++;
    }
} // weaveFreeListFrom


- (id) initWithNodeSize: (size_t) theNodeSize  count: (size_t) theCount {
    if ((self = [super init])) {
        _nodeSize = theNodeSize;
        _nodeCount = theCount;

        // Make sure there's enough space to store the pointers for the freelist.
        if (_nodeSize < sizeof(BWPoolElement)) {
            _nodeSize = sizeof(BWPoolElement);
        }
        
        // Allocate memory for the block.
        _memblock = malloc (_nodeSize * _nodeCount);
        NSLog (@"memblock is %p", _memblock);

        // Walk through the block building the freelist.
        [self weaveFreeListFrom: _memblock  forCount: theCount];
    }

    return self;

} // initWithNodeSize


- (void) dealloc {
    free (_memblock);
    [super dealloc];
} // dealloc


- (void *) allocNode {
    if (_freelist == NULL) {
        // We're out of space, so just throw our hands up and
        // surrender for now.  You can grow the pool by keeping an
        // array of memblocks and creating a new one when the previous
        // block fills up.
        fprintf (stderr, "out of space in node pool.  Giving up\n");
        abort ();
    }

    // take a new node off of the freelist
    void *newNode = _freelist;
    _freelist = _freelist->next;

    return newNode;

} // allocNode


- (void) freeNode: (void *) nodePtr {
    // Stick the freed node at the head of the freelist.
    ((BWPoolElement *)nodePtr)->next = _freelist;
    _freelist = nodePtr;
} // freeNode

@end // BWNodePool


// The node we're using the nodepool for.

typedef struct ListNode {
    long                someData;
    struct ListNode    *next;
} ListNode;


static void haveFunWithPool (int nodeCount) {
    NSLog (@"Creating nodes with the node pool");
    
    BWNodePool *nodePool =
        [[BWNodePool alloc] initWithNodeSize: sizeof(ListNode)
                            count: (size_t) nodeCount];
    ListNode *node = NULL, *prev = NULL;

    for (int i = 0; i < nodeCount; i++) {
        node = [nodePool allocNode];
        node->someData = i;
	// If you wish, you can do some extra work.

        // Construct a linked list through the nodes
        node->next = prev;
        prev = node;
    }

    NSLog (@"Cleaning up");

    // Destroy all the nodes at once.  If each node has memory management
    // obligations, you would need to walk the list of nodes.
    [nodePool release];

    NSLog (@"Done");

} // haveFunWithPool


static void haveFunWithMalloc (int nodeCount) {
    NSLog (@"Creating nodes with malloc");

    ListNode *node = NULL, *prev = NULL;
    for (int i = 0; i < nodeCount; i++) {
        node = malloc (sizeof(ListNode));
        node->someData = i;
	// If you wish, you can do some extra work.

        // Construct a linked list through the nodes
        node->next = prev;
        prev = node;
    }
    ListNode *head = node;

    NSLog (@"Cleaning up");

    while (head != NULL) {
        ListNode *nukeNode = head;
        head = head->next;
        free (nukeNode);
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
