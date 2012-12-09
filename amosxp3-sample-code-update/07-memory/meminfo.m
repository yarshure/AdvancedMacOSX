// meminfo.m -- get random information about the system

// clang -framework Foundation -o meminfo meminfo.m


#import <Foundation/Foundation.h>

int main (int argc, char *argv[]) {
    printf ("page size: %lu\n", NSPageSize());

    NSProcessInfo *info = [NSProcessInfo processInfo];
    
    printf ("real memory: %llu bytes (%llu megabytes)\n", 
            [info physicalMemory],
	    [info physicalMemory] / (1024 * 1024));
    printf ("sbrk(0) is %p\n", sbrk(0));

    return (0);

} // main
