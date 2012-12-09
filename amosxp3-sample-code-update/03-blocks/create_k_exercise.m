// create_k_exercise.m - Write function returning block. Use Block_copy().
// Check with:
// clang -Wall -Wextra create_k_exercise.m -o create_k_exercise

#import <Block.h>
#import <stdio.h>

typedef int (^IntBlock)(void);
IntBlock create_k(int i) {
    IntBlock k = ^{ return  i; };
    return Block_copy(k);
}

int
main(void) {
    IntBlock seven = create_k(7);
    fprintf(stderr, "seven() => %d\n", seven());
    return 0;
}
