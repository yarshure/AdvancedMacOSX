// fopen.m -- use gdb to poke around in a FILE handle

/* compile with
cc -g -o fopen fopen.m
*/

#import <stdlib.h>
#import <stdio.h>

int main (int argc, char *argv)
{
    FILE *file;
    file = fopen ("/tmp/nork", "w+");

    fclose (file);

    exit (EXIT_SUCCESS);

} // main

