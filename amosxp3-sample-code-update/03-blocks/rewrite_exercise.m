// rewrite_exercise.m - Rewrite function as block.
// Check with:
// clang -Wall -Wextra rewrite_exercise.m -c -o rewrite_exercise.o
/*
int k(void) {
    return 1;
}
*/

typedef int (^IntBlock)(void);
IntBlock k = ^{
    return 1;
};
/* OR */
//IntBlock k = ^int (void) { ... };

