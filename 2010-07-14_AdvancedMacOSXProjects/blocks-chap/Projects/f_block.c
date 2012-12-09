// f_block.c -- Demonstrate simple __block variable compilation.
// clang -Wall -Wextra -g -c f_block.c -o f_block.o
// Use nm to look at the generated block descriptor helper functions.
void f(void) {
    __block int x = 0;
    int (^b)(void) = ^{ return x + 1; };
    int y = b();
}
