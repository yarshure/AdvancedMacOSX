// stringization.m -- show token stringization and concatenation

#import <stdio.h>  // for printf()
#import <math.h>   // for sqrt()

// clang -g -Weverything -o stringization stringization.m

#define FIVE 5

int main (void) {
#define PRINT_EXPR(x) printf("%s = %d\n", #x, (x))
    PRINT_EXPR (5);
    PRINT_EXPR (5 * 10);
    PRINT_EXPR ((int)sqrt(FIVE*FIVE) + (int)log(25 / 5));

#define SPLIT_FUNC(x,y)  x##y
    SPLIT_FUNC (prin, tf) ("hello\n");

    return 0;

} // main
