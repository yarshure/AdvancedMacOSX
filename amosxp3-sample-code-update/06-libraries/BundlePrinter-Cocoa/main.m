// main.m -- the main BundlePrinter program

#import <Foundation/Foundation.h>
#import "BundlePrinter.h"

NSString *processPlugin (NSString *path) {

    NSString *message = nil;

    NSLog (@"processing plug-in: %@", path);

    // Load the bundle
    {  // Braces required by ARC when branching out of this scope
        NSBundle *plugin = [NSBundle bundleWithPath: path];
        
        
        if (plugin == nil) {
            NSLog (@"could not load plug-in at path %@", path);
            goto bailout;
        }
        
        // Get the class the bundle declares as its Principal one.
        // If there are multiple classes defined in the bundle, we
        // wouldn't know which one to talk to first
        Class principalClass = [plugin principalClass];
        
        if (principalClass == nil) {
            NSLog (@"could not load principal class for plug-in at path %@", path);
            NSLog (@"make sure the PrincipalClass target setting is correct");
            goto bailout;
        }
        
        // Do a little sanity checking
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
        id pluginInstance = [[principalClass alloc] init];
        
        // get the message and dispose with the instance
        message = [pluginInstance message];
        
        // ok, we're done with it
        [principalClass deactivate];
    }
    
 bailout:
    return message;

} // processPlugin

int main (int argc, const char *argv[]) {
    @autoreleasepool {
    
    // Walk the current directory looking for bundles.
    // An application would look in its bundle, or maybe a plugin
    // directory in ~/Library.
        NSFileManager *manager = [NSFileManager defaultManager];

        for (NSString *path in [manager enumeratorAtPath: @"."]) {

            // Only look for stuff that has a .bundle extension
            if ([[path pathExtension] isEqualToString: @"bundle"]) {

                // Invoke the plugin.
                NSString *message = processPlugin (path);

                if (message != nil) { // plugin succeeded
                    printf ("\nmessage is: '%s'\n\n", [message UTF8String]);
                }
            }
        }

    }
    return EXIT_SUCCESS;
    
} // main
