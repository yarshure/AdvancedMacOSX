#import <stdio.h>
#import <stdint.h>

int main (int argc, char *argv[])
{
    long long int littleDoggie;

    littleDoggie = (long long int)INT32_MAX * (long long int)INT32_MAX;

    printf ("a really big number %ll, %d\n", littleDoggie, INT32_MAX);

} // main
