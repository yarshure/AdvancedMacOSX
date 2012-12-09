// permtype-getattrlist.m -- use getattrlist() to discover type and
//                           permisisons for a file.

// clang -Weverything -Wno-packed -o permtype-getattrlist permtype-getattrlist.m

#import <errno.h>       // for errno
#import <grp.h>         // for group file access routines
#import <pwd.h>         // for passwd file access routines
#import <stdio.h>       // for printf
#import <stdlib.h>      // for EXIT_SUCCESS
#import <string.h>      // for memset()
#import <sys/attr.h>    // for attribute structures
#import <sys/stat.h>    // for stat() and struct stat
#import <unistd.h>      // for getattrlist()

// Lookup table for mapping permission values to the familiar
// character strings.
static const char *g_perms[]  = {
    "---", "--x", "-w-", "-wx", "r--", "r-x", "rw-", "rwx"
};

// Mapping from the file type bit mask to a human-readable string.
typedef struct FileType {
    unsigned long       mask;
    const char         *type;
} FileType;

static FileType g_types[] = {
    { S_IFREG, "Regular File" },
    { S_IFDIR, "Directory" },
    { S_IFLNK, "Symbolic Link" },
    { S_IFCHR, "Character Special Device" },
    { S_IFBLK, "Block Special Device" },
    { S_IFIFO, "FIFO" },
    { S_IFSOCK, "Socket" },
};

// structure of the data being returned by getattrlist()

typedef struct PermTypeAttributes {
    u_int32_t           length;
    attrreference_t     name;
    struct timespec     modTime;
    struct timespec     changeTime;
    struct timespec     accessTime;
    uid_t               ownerId;
    gid_t               groupId;
#if __LITTLE_ENDIAN__
    mode_t              accessMask;
    short               padding;
#else
    short               padding;
    mode_t              accessMask;
#endif
    off_t               fileLogicalSize;
    char                fileNameSpace[MAXPATHLEN];
} __attribute__ ((packed)) PermTypeAttributes;

static void displayInfo (const char *filename) {
    // Clear out the attribute request structure first, otherwise you'll
    // get undefined results.
    // This warns with clang 4.0 - still figuring out why.
    struct attrlist attrList = { 0 };
    attrList.bitmapcount = ATTR_BIT_MAP_COUNT;

    // Get the name, the permissions, and the stat-style times.
    attrList.commonattr = ATTR_CMN_NAME | ATTR_CMN_MODTIME | ATTR_CMN_CHGTIME 
        | ATTR_CMN_ACCTIME | ATTR_CMN_OWNERID | ATTR_CMN_GRPID | ATTR_CMN_ACCESSMASK;

    // Also get the file size.
    attrList.fileattr = ATTR_FILE_TOTALSIZE;
    
    // The returned data cannot be larger than the size of PermTypeAttributes.
    PermTypeAttributes permAttributes;
    int result = getattrlist (filename, &attrList, &permAttributes,
                              sizeof(permAttributes), 0);
    if (result == -1) {
        fprintf (stderr, "error with getattrlist(%s) : %d / %s\n",
                 filename, errno, strerror(errno));
        return;
    }
    
    // Be a little paranoid about the variable-sized returned data.
    char *nameStart = ((char *) &permAttributes.name) 
        + permAttributes.name.attr_dataoffset;
    char *nameEnd = nameStart + permAttributes.name.attr_length;
    char *bufferEnd = permAttributes.fileNameSpace
        + sizeof(permAttributes.fileNameSpace);

    // getattrlist() won't actually clobber past the end of our structure,
    // but blindly following pointers can be painful.
    if (nameEnd > bufferEnd) {
        fprintf (stderr, "Returned filename was truncated\n");
        return;
    }

    // Print the Name, then permissions.
    printf ("%s:\n", nameStart);
    printf ("  permissions: %s%s%s\n",
            g_perms[(permAttributes.accessMask & S_IRWXU) >> 6],
            g_perms[(permAttributes.accessMask & S_IRWXG) >> 3],
            g_perms[(permAttributes.accessMask & S_IRWXO)]);
    
    // Figure out the type.
    FileType *scan = g_types;
    FileType *stop = scan + (sizeof(g_types) / sizeof(*g_types));
    
    while (scan < stop) {
        if ((permAttributes.accessMask & S_IFMT) == scan->mask) {
            printf ("  type: %s\n", scan->type);
            break;
        }
        scan++;
    }
    
    // Any special bits sets?
    if ((permAttributes.accessMask & S_ISUID) == S_ISUID) printf ("  set-uid!\n");
    if ((permAttributes.accessMask & S_ISGID) == S_ISUID) printf ("  set-group-id!\n");
    
    // The file size isn't applicable to directories.
    if ((permAttributes.accessMask & S_IFMT) == S_IFREG) {
        printf ("  file is %lld bytes (%lld K)\n", 
                permAttributes.fileLogicalSize,
                permAttributes.fileLogicalSize / 1024);
    }
    
    // Owning user / group.
    struct passwd *passwd = getpwuid (permAttributes.ownerId);
    struct group *group = getgrgid (permAttributes.groupId);
    
    printf ("  user: %s (%d)\n", passwd->pw_name, permAttributes.ownerId);
    printf ("  group: %s (%d)\n", group->gr_name, permAttributes.groupId);
    
    // Now the dates.
    char buffer[1024];
    struct tm *tm;
    
    tm = localtime (&permAttributes.accessTime.tv_sec);
    strftime (buffer, sizeof(buffer), "%c", tm);
    printf ("  last access: %s\n", buffer);
    
    tm = localtime (&permAttributes.modTime.tv_sec);
    strftime (buffer, sizeof(buffer), "%c", tm);
    printf ("  last modification: %s\n", buffer);
    
    tm = localtime (&permAttributes.changeTime.tv_sec);
    strftime (buffer, sizeof(buffer), "%c", tm);
    printf ("  last inode change: %s\n", buffer);
    
    // double-space output
    printf ("\n");

} // displayInfo


int main (int argc, char *argv[]) {
    if (argc == 1) {
        fprintf (stderr, "usage:  %s /path/to/file ... \n", argv[0]);
        return EXIT_FAILURE;
    }
    for (int i = 1; i < argc; i++) {
        displayInfo (argv[i]);
    }

    return EXIT_SUCCESS;

} // main
