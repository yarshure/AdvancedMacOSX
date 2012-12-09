
/* compile with
gcc -o fat-macro-warn fat-macro-warn.c
or
gcc -arch ppc64 -o fat-macro-warn fat-macro-warn.c
or
gcc -arch ppc64 -arch ppc -arch i386 -o fat-macro-warn fat-macro-warn.c
*/

int main (void)
{
#warning compiling the file

#ifdef __LP64__
#warning in LP64
#endif

#ifdef __ppc64__
#warning in __ppc64__
#endif

#ifdef __ppc__
#warning in __ppc__
#endif

#ifdef __i386__
#warning in __i386__
#endif

#ifdef __x86_64__
#warning in __x86_64__
#endif

    return (0);

} // main
