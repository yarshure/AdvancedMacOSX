// free2.m -- generate a memory manager complaint

/* compile with
cc -g -o free2 free2.m
*/

#import <stdlib.h>

int main (int argc, char *argv[])
{
    char *blah;

    blah = malloc (1024);
    free (blah);
    free (blah);

} // main
