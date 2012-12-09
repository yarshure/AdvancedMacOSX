// bundleprinter.m -- dynamically load plugins and invoke functions on them, using
//                    the dlopen() family of calls.

// clang -g -Weverything -o bundleprinter bundleprinter.m

#import <sys/dirent.h>	// for struct dirent
#import <dirent.h>	// for opendir and friends
#import <dlfcn.h>       // for dlopen() and friends
#import <errno.h>	// for errno/strerror
#import <fnmatch.h>	// for fnmatch
#import <stdio.h>	// for printf
#import <stdlib.h>	// for EXIT_SUCCESS
#import <string.h>	// for strdup

// We need a type to coerce a void pointer to the function pointer we
// need to jump through.  Having a type makes things a bit easier
// to read rather than doing this inline.

typedef int (*BNRMessageActivateFP) (void);
typedef void (*BNRMessageDeactivateFP) (void);
typedef char * (*BNRMessageMessageFP) (void);

static char *processPlugin (const char *path) {
    char *message = NULL;

    void *module = dlopen (path, RTLD_LAZY);

    if (module == NULL) {
        fprintf (stderr, 
                 "couldn't load plugin at path %s.  error is %s\n",
                 path, dlerror());
        goto bailout;
    }

    BNRMessageActivateFP activator =
        (BNRMessageActivateFP) dlsym (module, "BNRMessageActivate");
    BNRMessageDeactivateFP deactivator = 
        (BNRMessageDeactivateFP) dlsym (module, "BNRMessageDeactivate");
    BNRMessageMessageFP messagator =
        (BNRMessageMessageFP) dlsym (module, "BNRMessageMessage");

    if (activator == NULL || deactivator == NULL || messagator == NULL) {
        fprintf (stderr, 
                 "could not find BNRMessage* symbol (%p %p %p)\n",
                 activator, deactivator, messagator);
        goto bailout;
    }

    int result = (activator)();
    if (!result) { // the module didn't consider itself loaded
        goto bailout;
    }

    message = (messagator)();

    (deactivator)();

  bailout:
    if (module != NULL) {
        result = (dlclose (module));
        if (result != 0) {
            fprintf (stderr, "could not dlclose %s.  Error is %s\n",
                     path, dlerror());
        }
    }
    
    return message;
    
} // processPlugin


int main (void) {
    // walk through the current directory

    DIR *directory = opendir (".");

    if (directory == NULL) {
	fprintf (stderr, 
		 "could not open current directory to look for plugins\n");
	fprintf (stderr, "error: %d (%s)\n", errno, strerror(errno));
	exit (EXIT_FAILURE);
    }

    struct dirent *entry;
    while ((entry = readdir(directory)) != NULL) {
	// If this is a file of type .msg (an extension made up for this
	// sample), process it like a plug-in.

	if (fnmatch("*.msg", entry->d_name, 0) == 0) {
	    char *message = processPlugin (entry->d_name);

	    printf ("\nmessage is: '%s'\n\n", message);
            free (message);
	}
    }

    closedir (directory);

    return EXIT_SUCCESS;

} // main
