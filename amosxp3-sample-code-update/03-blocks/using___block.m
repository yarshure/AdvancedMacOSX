/* using___block.m - Demonstrates the __block storage class. */
//gcc -g -Wall -Wextra using___block.m -o using___block
#import <stdio.h>

typedef void (^Incrementer)(void);

int main(void) {
    __block int x = 0;
    void (^logX)(void) = ^{
        printf("x = %d\n", x);
    };

    Incrementer add1 = ^{
        puts("add1");
        x++;
    };
    Incrementer add2 = ^{
        puts("add2");
        x += 2;
    };
    Incrementer add3 = ^{
        puts("add3");
        x += 3;
    };

    printf("x starts as %d.\n", x);
    add1(); logX();
    add2(); logX();
    add3(); logX();
    printf("x ends as %d.\n", x);
    return 0;
}
