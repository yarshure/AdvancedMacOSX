// limits.m -- See the current resource limits.

// clang -g -Weverything -Wno-padded -o limits limits.m

#import <sys/resource.h> // for the RLMIT_* constants
#import <errno.h>        // for errno
#import <stdio.h>        // for printf() and friends
#import <string.h>       // for strerror()

typedef struct Limit {
    int resource;
    const char *name;
} Limit;

Limit limits[] = {
    { RLIMIT_DATA,    "data segment maximum (bytes)" },
    { RLIMIT_RSS,     "resident size maximum (bytes)" },
    { RLIMIT_STACK,   "stack size maximum (bytes)" },
    { RLIMIT_MEMLOCK, "wired memory maximum (bytes)" },
    { RLIMIT_FSIZE,   "file size maximum (bytes)" },
    { RLIMIT_NOFILE,  "max number of simultaneously open files" },
    { RLIMIT_NPROC,   "max number of simultaneous processes" },
    { RLIMIT_CPU,     "cpu time maximum (seconds)" },
    { RLIMIT_CORE,    "core file maximum (bytes)" }
};

// Turn the rlim_t value in to a string, also translating the magic
// "infinity" value to something human readable

static void stringValue (rlim_t value, char *buffer, size_t buffersize) {
    if (value == RLIM_INFINITY) strcpy (buffer, "infinite");
    else snprintf (buffer, buffersize, "%lld", value);
} // stringValue


// Right-justify the first entry in a field width of 45, then display
// two more strings.
#define FORMAT_STRING "%45s: %-10s (%s)\n"

int main (void) {
    Limit *scan = limits;
    Limit *stop = scan + (sizeof(limits) / sizeof(*limits));

    printf (FORMAT_STRING, "limit name", "soft-limit", "hard-limit");

    while (scan < stop) {
        struct rlimit rl;
        if (getrlimit (scan->resource, &rl) == -1) {
            fprintf (stderr, "error in getrlimit for %s: %d/%s\n",
                     scan->name, errno, strerror(errno));
        } else {
            char softLimit[20];
            char hardLimit[20];

            stringValue (rl.rlim_cur, softLimit, 20);
            stringValue (rl.rlim_max, hardLimit, 20);
            
            printf (FORMAT_STRING, scan->name, softLimit, hardLimit);
        }
        scan++;
    }
    return 0;
} // main
