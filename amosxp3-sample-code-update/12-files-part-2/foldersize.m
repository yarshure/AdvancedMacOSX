// foldersize.m -- calculate the size of a folder with stat and getdirentriesattr

#import <dirent.h>      // for getdirentries()
#import <errno.h>       // for errno
#import <fcntl.h>       // for O_RDONLY
#import <stdio.h>       // for printf
#import <stdlib.h>      // for EXIT_SUCCESS
#import <string.h>      // for strerror
#import <sys/attr.h>    // for attrreference_t
#import <sys/dirent.h>  // for struct dirent
#import <sys/param.h>   // for MAXPATHLEN
#import <sys/stat.h>    // for struct statbuf and stat()
#import <sys/types.h>   // for random type definition
#import <sys/vnode.h>   // for VDIR
#import <unistd.h>      // for getdirentriesattr()

// clang -g -Weverything -o foldersize foldersize.m

// show the files and sizes of the files as they are processed
static int g_verbose = 0;

// --------------------------------------------------
// stat code

// Calculate the directory size via stat().
static off_t sizeForFolderStat (char *path) {
    DIR *directory = opendir (path);

    if (directory == NULL) {
        fprintf (stderr, "could not open directory '%s'\n", path);
        fprintf (stderr, "error is %d/%s\n", errno, strerror(errno));
        exit (EXIT_FAILURE);
    }

    off_t size = 0;
    struct dirent *entry;
    while ((entry = readdir(directory)) != NULL) {
        char filename[MAXPATHLEN];

        // don't mess with the metadirectories
        if (strcmp(entry->d_name, ".") == 0
            || strcmp(entry->d_name, "..") == 0) {
            continue;
        }

        // Rather than changing the current working directory each
        // time through the loop, construct the full path relative the
        // given path.  Because the original path is either absolute, or
        // relative to the current working directory, this should
        // always give us a stat-able path
        snprintf (filename, MAXPATHLEN, "%s/%s", path, entry->d_name);

        // Use lstat so we don't multiply-count the sizes of files that
        // are pointed to by symlinks.
        struct stat statbuf;
        int result = lstat (filename, &statbuf);

        if (result != 0) {
            fprintf (stderr, "could not stat '%s': %d/%s\n",
                     entry->d_name, errno, strerror(errno));
            continue;
        }

        // Recurse into subfolders.
        if (S_ISDIR(statbuf.st_mode)) {
            size += sizeForFolderStat (filename);

        } else {
            if (g_verbose) printf ("%lld %s\n", statbuf.st_size, entry->d_name);
            size += statbuf.st_size;
        }
    }

    closedir (directory);
    return size;

} // sizeForFolderStat


// --------------------------------------------------
// getdirentriesattr code

// The attributes we want to get with each call to getdirentriesattr.
static struct attrlist g_attrlist; // gets zeroed automatically

// The data being returned by each call.  The alignment is forced off of the
// default alignment (based on off_t, which is 8 bytes), beacuse the structs are
// packed together when returned.
typedef struct fileinfo {
    u_int32_t        length;
    attrreference_t  name;
    fsobj_type_t     objType;
    off_t            logicalSize;
} fileinfo  __attribute__((aligned(1)));

// try to pick up this many entries each time through
#define ENTRIES_COUNT 30

// Don't know how long each file name is, so make a guess so we can
// size the results buffer
#define AVG_NAME_GUESSTIMATE 64


static off_t sizeForFolderAttr (char *path) {
    off_t size = 0;
    int fd = open (path, O_RDONLY);

    if (fd == -1) {
        fprintf (stderr, "could not open directory '%s'\n", path);
        fprintf (stderr, "error is %d/%s\n", errno, strerror(errno));
        exit (EXIT_FAILURE);
    }

    // A rough guess on the appropriate buffer size
    size_t bufferSize = ENTRIES_COUNT * sizeof(fileinfo) + AVG_NAME_GUESSTIMATE;
    void *attrbuf = malloc (bufferSize);

    while (1) {
        u_int32_t count = ENTRIES_COUNT;
        u_int32_t newState = 0;
        u_int32_t base;
        int result = getdirentriesattr (fd, &g_attrlist,
                                        attrbuf, bufferSize,
                                        &count, &base, &newState, 0);
        if (result < 0) {
            fprintf (stderr, "error with getdirentriesattr for '%s'. %d/%s\n",
                     path, errno, strerror(errno));
            goto bailout;
        }

        // walk the returned buffer
        fileinfo *scan = (fileinfo *) attrbuf;
        
        for (; count > 0; count--) {
            if (scan->objType == VDIR) {
                char filename[MAXPATHLEN];

                snprintf (filename, MAXPATHLEN, "%s/%s", path, 
                          ((char *) &scan->name) 
                          + scan->name.attr_dataoffset);
                
                size += sizeForFolderAttr (filename);

            } else {
                if (g_verbose) {
                    printf ("%lld %s\n", scan->logicalSize,
                            ((char *) &scan->name) + scan->name.attr_dataoffset);
                }
                size += scan->logicalSize;
            }
            
            // Move to the next attribute in the returned set.  Clang complains
            // about alignment, but we don't have much control over that.
            scan = (fileinfo *) (((char *) scan) + scan->length);
        }

        if (result == 1) {
            // We're done.
            break;
        }
    }
    
bailout:
    close (fd);
    free (attrbuf);

    return size;

} // sizeForFolderAttr


int main (int argc, char *argv[]) {
    // sanity check the program arguments first
    if (argc != 3) {
        fprintf (stderr, "usage:  %s {stat|attr} /path/to/directory\n", argv[0]);
        return EXIT_FAILURE;
    }
    off_t size = 0;

    if (strcmp(argv[1], "stat") == 0) {
        size = sizeForFolderStat (argv[2]);

    } else if (strcmp(argv[1], "attr") == 0) {

        // these are the attributes we're wanting.  Set them up
        // globally so we don't have to do a memset + this jazz
        // on every recursion

        g_attrlist.bitmapcount = ATTR_BIT_MAP_COUNT;
        g_attrlist.commonattr = ATTR_CMN_NAME | ATTR_CMN_OBJTYPE;
        g_attrlist.fileattr = ATTR_FILE_DATALENGTH;

        // Using ATTR_FILE_TOTALSIZE would be better so that we get
        // the space consumed by resource forks, but we're using this
        // code to parallel what stat gives us, which doesn't include
        // resource fork size.

        size = sizeForFolderAttr (argv[2]);

    } else {
        fprintf (stderr, "usage:  %s {stat|attr} /path/to/directory\n", argv[0]);
        return EXIT_FAILURE;
    }

    printf ("size is %lld bytes (%lld K).\n", size, size / 1024);
    return EXIT_SUCCESS;

} // main

