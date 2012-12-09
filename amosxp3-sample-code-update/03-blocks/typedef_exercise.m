// typedef_exercise.m - Exemplifies declaring a reference returning a funcptr.
// Notice how the return type and parameter types surround
// the "body" (^b2)() of the declaration.
// Parens around the (*decl) are required.
int foo(int);
int (*(^b2)(void))(int) = ^{
    return foo;
};

// Apply the syntax demoed in b2 twice.
// Exercise: simplify this with typedefs.
block_factory_func factory;
int (^(*(^b3)(void))(int))(void) = ^{
    return factory;
}

// Solution follows.
// get_const_block_factory_func's type is equivalent to b3's;
// unlike b3, its declaration is directly comprehensible.
typedef int (^const_block_t)(void);
typedef const_block_t (*block_factory_func)(int);
block_factory_func (^get_const_block_factory_func)(void);

// Step by step for declaring a func ptr:
/* - write variable name first
               b
   - dereference it with *
              *b
   - parenthesize it
             (*b)
   - add return type at head
         int (*b)
   - add argument list at tail
         int (*b)(void)
   - done! b is a pointer to a function taking void and return int
*/

// vi: filetype=objc syntax=objc ts=4 sw=4 et:
