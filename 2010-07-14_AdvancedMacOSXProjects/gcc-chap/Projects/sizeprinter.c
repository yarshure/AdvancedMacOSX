#include <stdio.h>  // for printf()

/* compile with
gcc -arch ppc64 -g -Wall -o sizeprinter sizeprinter.c
or
gcc -arch x86_64 -g -Wall -o sizeprinter sizeprinter.c
or
gcc -arch i386 -g -Wall -o sizeprinter sizeprinter.c
or
gcc -arch ppc -g -Wall -o sizeprinter sizeprinter.c
or
gcc -arch ppc64 -arch ppc -g -Wall -o sizeprinter sizeprinter.c
or
gcc -arch ppc -arch i386 -arch ppc64 -arch x86_64 -g -Wall -o sizeprinter sizeprinter.c
or
gcc -g -o fat-g4 sizeprinter.c
gcc -arch sizeprinter -g -o fat-g5 sizeprinter.c
lipo -create -output fat fat-g4 fat-g5
*/

int main (void)
{
    printf ("sizeof(int*) is %ld\n", sizeof(int*));

    return (0);

} // main
