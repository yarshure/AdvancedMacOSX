// f_generated.c -- Rough equivalent to the compiler's output for f_block.c.
// gcc -std=c99 -Wall -Wextra -Wno-unused -c f_block_generated.c -o f_block_generated.o
// It's easiest to figure out the details if you use -S instead of -c
// and look at the assembly code.

// <-- NOT IN BOOK
#include <objc/objc.h>  // Class
#include <sys/types.h>  // NULL
extern Class _NSConcreteStackBlock;
extern void _Block_object_assign(void *, const void *, const int);
extern void _Block_object_dispose(const void *, const int);
#define NULL (0)
enum {
    BLOCK_HAS_DESCRIPTOR = (1 << 29),
};
enum {
    BLOCK_FIELD_IS_BYREF = 8,
};

#if 0
// It's useful to compile and run just to ensure we didn't write a crasher.
/* You'll have to jump through hoops to get this to work under 10.5
 * using PLBlocks. You'll need to use /Developer/usr/bin/gcc-blocks,
 * add the directory containing PLBlocks.framework
 * to the framework search path with -F
 * then link in -framework PLBlocks. */
void f(void);
int main(void) {
  f();
  return 0;
}
#endif
// NOT IN BOOK -->

// __block int x
struct __byref_x {
  /* header */
  void *isa;
  struct __byref_x *forwarding;
  int flags;
  int size;

  /* no helpers needed */

  int x;
};

typedef void (*generic_invoke_funcptr)(void *, ...);
struct __block_literal {
    void *isa;
    int flags;
    int reserved;
    generic_invoke_funcptr invoke;
    struct __block_descriptor_tmp *descriptor;
    struct __byref_x *captured_x;
};

void __copy_helper_block_(struct __block_literal *dst,
                          struct __block_literal *src);
void __destroy_helper_block_(struct __block_literal *bp);


typedef void (*generic_copy_funcptr)(void *, void *);
typedef void (*generic_dispose_funcptr)(void *);
static const struct __block_descriptor_tmp {
    unsigned long reserved;
    unsigned long literal_size;
    /* helpers to copy __block reference captured_x */
    generic_copy_funcptr copy;
    generic_dispose_funcptr dispose;
} __block_descriptor_tmp = {
    0UL, sizeof(struct __block_literal),
    (generic_copy_funcptr)__copy_helper_block_,
    (generic_dispose_funcptr)__destroy_helper_block_
};

// ^int (void) { return x + 1; }
int __f_block_invoke_(struct __block_literal *bp) {
    return bp->captured_x->forwarding->x + 1;
}
typedef int (*iv_funcptr)(struct __block_literal *);


void f(void) {
    // __block int x = 0;
    struct __byref_x x = {
        .isa = NULL,
        .forwarding = &x,
        .flags = 0,
        .size = sizeof(x),
        .x = 0
    };
    // int (^b)(void) = ^{ return x + 1 };
    struct __block_literal __b = {
        .isa = &_NSConcreteStackBlock,
        .flags = BLOCK_HAS_DESCRIPTOR,
        .reserved = 0,
        .invoke = (generic_invoke_funcptr)__f_block_invoke_,
        .descriptor = &__block_descriptor_tmp,
        .captured_x = x.forwarding
    };
    struct __block_literal *b = &__b;
    int y = (*(iv_funcptr)(b->invoke))(b);

    // Clean up before leaving scope of x.
    _Block_object_dispose(x.forwarding, BLOCK_FIELD_IS_BYREF);
}

void __copy_helper_block_(struct __block_literal *dst,
                          struct __block_literal *src) {
  _Block_object_assign(&dst->captured_x, src->captured_x,
                       BLOCK_FIELD_IS_BYREF);
}

void __destroy_helper_block_(struct __block_literal *bp) {
  _Block_object_dispose(bp->captured_x, BLOCK_FIELD_IS_BYREF);
}
