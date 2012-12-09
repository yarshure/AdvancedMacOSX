// permtype.m -- Use stat to discover the type and permissions for a file.

// clang -g -Weverything -o permtype permtype.m

#import <errno.h>       // for errno
#import <grp.h>         // for group file access routines
#import <pwd.h>         // for passwd file access routines
#import <stdio.h>       // for printf
#import <stdlib.h>      // for EXIT_SUCCESS
#import <string.h>      // for strerror
#import <sys/stat.h>    // for stat() and struct stat
#import <sys/time.h>    // for struct tm, localtime, etc

// Lookup table for mapping permission values to the familiar
// character strings.
static const char *g_perms[]  = {
    "---", "--x", "-w-", "-wx", "r--", "r-x", "rw-", "rwx"
};

// Mapping from the file type bit mask to a human-readable string.
typedef struct FileType {
    unsigned long   mask;
    const char     *type;
} FileType;

static FileType g_filetypes[] = {
    { S_IFREG, "Regular File" },
    { S_IFDIR, "Directory" },
    { S_IFLNK, "Symbolic Link" },
    { S_IFCHR, "Character Special Device" },
    { S_IFBLK, "Block Special Device" },
    { S_IFIFO, "FIFO" },
    { S_IFSOCK, "Socket" },
};

static void displayInfo (const char *filename) {
    struct stat statbuf;
    int result = lstat (filename, &statbuf);

    if (result == -1) {
	fprintf (stderr, "error with stat(%s) :  %d (%s)\n",
		 filename, errno, strerror(errno));
	return;
    }

    printf ("%s:\n", filename);

    printf ("  permissions: %s%s%s\n",
	    g_perms[(statbuf.st_mode & S_IRWXU) >> 6],
	    g_perms[(statbuf.st_mode & S_IRWXG) >> 3],
	    g_perms[(statbuf.st_mode & S_IRWXO)]);

    // Get the readable string for the type.
    FileType *scan = g_filetypes;
    FileType *stop = scan + (sizeof(g_filetypes) / sizeof(*g_filetypes));

    while (scan < stop) {
	if ((statbuf.st_mode & S_IFMT) == scan->mask) {
	    printf ("  type: %s\n", scan->type);
	    break;
	}
	scan++;
    }
    
    // Any special bits sets?
    if ((statbuf.st_mode & S_ISUID) == S_ISUID) printf ("  set-uid!\n");
    if ((statbuf.st_mode & S_ISGID) == S_ISGID) printf ("  set-group-id!\n");

    // File size.
    printf ("  file is %ld bytes (%.2f K)\n", 
	    (long)statbuf.st_size, (float) (statbuf.st_size / 1024.0));

    // Owning user / group
    struct passwd *passwd = getpwuid (statbuf.st_uid);
    printf ("  user: %s (%d)\n", passwd->pw_name, statbuf.st_uid);
    struct group *group = getgrgid (statbuf.st_gid);
    printf ("  group: %s (%d)\n", group->gr_name, statbuf.st_gid);

    // Now the dates
    char buffer[1024];
    struct tm *tm;
    
    tm = localtime (&statbuf.st_atime);
    strftime (buffer, 1024, "%c", tm);
    printf ("  last access: %s\n", buffer);
    
    tm = localtime (&statbuf.st_mtime);
    strftime (buffer, 1024, "%c", tm);
    printf ("  last modification: %s\n", buffer);
    
    tm = localtime (&statbuf.st_ctime);
    strftime (buffer, 1024, "%c", tm);
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


