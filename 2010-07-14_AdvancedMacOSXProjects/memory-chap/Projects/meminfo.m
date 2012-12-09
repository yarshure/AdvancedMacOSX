// meminfo.m -- get random information about the system

/* compile with
   cc -framework Foundation -o meminfo meminfo.m
*/


#import <Foundation/Foundation.h>

int main (int argc, char *argv[])
{
    printf ("page size: %d\n", NSPageSize());
    
    printf ("real memory: %d bytes (%d megabytes)\n", 
	    NSRealMemoryAvailable(),
	    NSRealMemoryAvailable() / (1024 * 1024));
    printf ("sbrk(0) is %d\n", sbrk(0));

    return (0);

} // main
