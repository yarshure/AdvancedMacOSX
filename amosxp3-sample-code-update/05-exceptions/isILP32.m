
// Errors
// clang -g -Weverything -Wno-pedantic -o isILP32 isILP32.m
// Compiles OK
// clang -arch i386 -g -Wall -o isILP32 isILP32.m

typedef char AssertIntAndLongHaveSameSize[(sizeof(int) == sizeof(long)) ? 0 : -1];

int main (void) {
    return 0;
} // main
