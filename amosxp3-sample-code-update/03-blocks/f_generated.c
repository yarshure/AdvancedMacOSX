// f_generated.c -- Rough equivalent to the compiler's output for f.c.
// gcc -std=c99 -Wall -Wextra -Wno-unused -c f_generated.c -o f_generated.o
// It's easiest to figure out the details if you use -S instead of -c
// and look at the assembly code.

// <-- NOT IN BOOK
#include <objc/objc.h>  // Class
extern Class _NSConcreteStackBlock;
enum {
    BLOCK_HAS_DESCRIPTOR = (1 << 29),
};
// NOT IN BOOK -->

typedef void (*generic_invoke_funcptr)(void *, ...);
struct __block_literal {
    void *isa;
    int flags;
    int reserved;
    generic_invoke_funcptr invoke;
    struct __block_descriptor_tmp *descriptor;
    const int captured_x;
};

static const struct __block_descriptor_tmp {
    unsigned long reserved;
    unsigned long literal_size;
    /* no copy/dispose helpers needed */
} __block_descriptor_tmp = {
    0UL, sizeof(struct __block_literal)
};

// ^int (void) { return x + 1; }
int __f_block_invoke_(struct __block_literal *bp) {
    return bp->captured_x + 1;
}
typedef int (*iv_funcptr)(struct __block_literal *);

void f(void) {
    int x = 0;
    // int (^b)(void) = ^{ return x + 1 };
    struct __block_literal __b = {
        .isa = &_NSConcreteStackBlock,
        .flags = BLOCK_HAS_DESCRIPTOR,
        .reserved = 0,
        .invoke = (generic_invoke_funcptr)__f_block_invoke_,
        .descriptor = &__block_descriptor_tmp,
        .captured_x = x
    };
    struct __block_literal *b = &__b;
    int y = (*(iv_funcptr)(b->invoke))(b);
}
