
// clang -o fat-macro-warn fat-macro-warn.c
// clang -arch i386 -o fat-macro-warn fat-macro-warn.c
// clang -arch i386 -arch x86_64 -o fat-macro-warn fat-macro-warn.c

int main (void) {

#warning compiling the file

#ifdef __LP64__
#warning in LP64
#endif

#ifdef __i386__
#warning in __i386__
#endif

#ifdef __x86_64__
#warning in __x86_64__
#endif

    return 0;

} // main
