// add_one_two_exercise.m - Two blocks with shared variable.
// Check with:
// clang -Weverything add_one_two_exercise.m -framework Foundation -o add_one_two_exercise

#import <stdio.h>

typedef void (^BlockRef)(void);

// UNDERSPECIFIED - Could just use global/static x.
int x = 0;
BlockRef add_one = ^{ ++x; };
BlockRef add_two = ^{ x += 2; };

// INTENDED:
int
main(void) {
    __block int x = 0;

    BlockRef add_one = ^{ ++x; };
    BlockRef add_two = ^{ x += 2; };
    BlockRef log_x = ^{ fprintf(stderr, "x = %d\n", x); };

    log_x();
    add_one();
    log_x();
    add_two();
    log_x();
    return 0;
}
