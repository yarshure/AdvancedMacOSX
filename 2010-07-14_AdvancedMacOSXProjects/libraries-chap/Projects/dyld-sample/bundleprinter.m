// bundleprinter.m -- dynamically load some plugins and invoke functions
//                    on them

/* compile with
cc -g -o bundleprinter bundleprinter.m
*/


#import <mach-o/dyld.h>	// for dynamic loading API
#import <sys/types.h>	// for random type definition
#import <sys/dirent.h>	// for struct dirent
#import <dirent.h>	// for opendir and friends
#import <stdlib.h>	// for EXIT_SUCCESS
#import <stdio.h>	// for printf
#import <errno.h>	// for errno/strerror
#import <string.h>	// for strdup


// we need a type to coerce a void pointer to the function pointer we
// need to jump through.  Having a type makes things a bit easier
// to read

typedef int (*BNRMessageActivateFP) (void);
typedef void (*BNRMessageDeactivateFP) (void);
typedef char * (*BNRMessageMessageFP) (void);


// given a module and a symbol, look it up and return the address
// NULL returned if the symbol couldn't be found

void *addressOfSymbol (NSModule *module, const char *symbolName)
{
    NSSymbol	symbol;
    void       *address = NULL;

    symbol = NSLookupSymbolInModule (module, symbolName);

    if (symbol == NULL) {
	fprintf (stderr, "Could not find symbol\n");
	goto bailout;
    }

    address = NSAddressOfSymbol (symbol);

  bailout:
    return (address);

} // addressOfSymbol



// given a path to a plugin, load it, activate it, get the message, 
// deactivate it, and unload it

char *processPlugin (const char *path)
{
    NSObjectFileImage	image;
    NSObjectFileImageReturnCode status;
    NSModule	module = NULL;
    char *message = NULL;
    
    status = NSCreateObjectFileImageFromFile (path, &image);
    
    if (status != NSObjectFileImageSuccess) {
	fprintf (stderr, "couldn't load plugin at path %s.  error is %d\n",
		 path, status);
	goto bailout;
    }

    // this will abort the program if an error happens.
    // if we don't want.
    // _OPTION_PRIVATE is necessary so we can use NSLookupSymbolInModule
    // _RETURN_ON_ERROR is so we don't abort the program if a module happens
    //                  to have a problem loading (say undefined symbols)

    module = NSLinkModule (image, path, 
			   NSLINKMODULE_OPTION_PRIVATE
			   | NSLINKMODULE_OPTION_RETURN_ON_ERROR);

    if (module == NULL) {
	NSLinkEditError
	fprintf (stderr, "couldn't load module from plug-in at path %s.", path);
	goto bailout;
    }

    // ok, we have the module loaded.  Look up the symbols and call them
    // if they exist.
    {
	BNRMessageActivateFP activator;
	BNRMessageDeactivateFP deactivator;
	BNRMessageMessageFP messagator;
	
	activator = addressOfSymbol (module, "_BNRMessageActivate");
	if (activator != NULL) {
	    int result = (activator)();
	    if (!result) { // the module didn't consider itself loaded
		goto bailout;
	    }
	}

	messagator = addressOfSymbol (module, "_BNRMessageMessage");
	if (messagator != NULL) {
	    message = (messagator)();
	}
	
	deactivator = addressOfSymbol (module, "_BNRMessageDeactivate");
	if (deactivator != NULL) {
	    (deactivator)();
	}
    }


  bailout:

    // clean up no matter what
    if (module != NULL) {
	(void) NSUnLinkModule (module, 0);
    }

    // couldn't find a cleanup counterpart to NSCreateObjectFileImageFromFile
    
    return (message);
    
} // processPlugin




int main (int argc, char *argv[])
{
    DIR *directory;
    struct dirent *entry;

    // walk through the current directory

    directory = opendir (".");

    if (directory == NULL) {
	fprintf (stderr, 
		 "could not open current directory to look for plugins\n");
	fprintf (stderr, "error: %d (%s)\n", errno, strerror(errno));
	exit (EXIT_FAILURE);
    }

    while ( (entry = readdir(directory)) != NULL) {

	// if this is a file of type .msg (an extension made up for this
	// sample), process it like a plug-in

	if (strstr(entry->d_name, ".msg") != NULL) {
	    char *message;
	    message = processPlugin (entry->d_name);

	    printf ("\nmessage is: '%s'\n\n", message);
	    if (message != NULL) {
		free (message);
	    }
	}
    }

    closedir (directory);

    exit (EXIT_SUCCESS);

} // main

