// f.c -- Demonstrate simple block compilation.
// clang -Wall -Wextra -g -c f.c -o f.o
// Use nm to look at the generated block literal, descriptor, and function.
void f(void) {
    int x = 0;
    int (^b)(void) = ^{ return x + 1; };
    int y = b();
}
