// main.m -- the main BundlePrinter program

#import <Foundation/Foundation.h>
#import "BundlePrinter.h"


NSString *processPlugin (NSString *path)
{
    NSBundle *plugin;
    Class principalClass;
    id pluginInstance;
    NSString *message = nil;

    NSLog (@"processing plug-in: %@", path);

    // load the bundle
    plugin = [NSBundle bundleWithPath: path];

    if (plugin == nil) {
	NSLog (@"could not load plug-in at path %@", path);
	goto bailout;
    }

    // get the class the bundle declares as its Principal one.
    // if there are multiple classes defined in the bundle, we 
    // won't know which one to talk to first
    principalClass = [plugin principalClass];

    if (principalClass == nil) {
	NSLog (@"could not load principal class for plug-in at path %@", path);
	NSLog (@"make sure the PrincipalClass target setting is correct");
	goto bailout;
    }

    // do a little sanity checking
    if (![principalClass conformsToProtocol: @protocol(BundlePrinterProtocol)]) {
	NSLog (@"plug-in principal class must conform to the BundlePrinterProtocol");
	goto bailout;
    }

    // tell the plug-in that it's being activated
    if (![principalClass activate]) {
	NSLog (@"could not activate class for plug-in at path %@", path);
	goto bailout;
    }

    // make an instance of the plug-in and ask it for a message
    pluginInstance = [[principalClass alloc] init];

    // get the message and dispose with the instance
    message = [pluginInstance message];
    [pluginInstance release];
    
    
    // ok, we're done with it
    [principalClass deactivate];
    
    
 bailout:
    
    return (message);

} // processPlugin



int main (int argc, const char *argv[]) 
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSDirectoryEnumerator *enumerator;
    NSString *path, *message;
    
    // walk the current directory looking for bundles

    enumerator = [[NSFileManager defaultManager] enumeratorAtPath: @"."];
    while (path = [enumerator nextObject]) {
	// only look for stuff that has a .bundle extension

	if ([[path pathExtension] isEqualToString: @"bundle"]) {

	    // invoke the plugin
	    message = processPlugin (path);

	    if (message != nil) { // plugin succeeded
		printf ("\nmessage is: '%s'\n\n", [message cString]);
	    }
	}
    }
    
    
    [pool release];
    
    return (0);
    
} // main
