// CFXMLParse.m -- show callbacks from a C api.
// This program doesn't really parse XML, just shows how to do a callback
// from a C API.  You will need to supply a command-line argument.

/* compile with:
gcc -g -Wall -framework CoreFoundation -framework Foundation -o cfxmlparser cfxmlparser.m
*/

#import <CoreFoundation/CFXMLParser.h>
#import <CoreFoundation/CFXMLNode.h>
#import <Foundation/Foundation.h>

@interface Watcher : NSObject

- (void) watchCreateStructure: (CFXMLNodeRef) node;
- (void) watchAddChild: (void *) child
              toParent: (void *) parent;

@end // Watcher

@implementation Watcher

- (void) watchCreateStructure: (CFXMLNodeRef) node {
    NSLog (@"watched creation of a structure: %p", node);
    CFShow(node);
} // watchCreateStructure

- (void) watchAddChild: (void *) child
              toParent: (void *) parent {
    NSLog (@"watched add child (%p) to parent (%p)", child, parent);

} // watchAddChild

@end // Watcher


void *createStructure (CFXMLParserRef parser, 
                       CFXMLNodeRef node, void *info) {
    Watcher *watcher = (Watcher *) info;
    [watcher watchCreateStructure: node];

    return (NULL);
    
} // createStructure


void addChild (CFXMLParserRef parser, void *in_parent, 
               void *in_child, void *info) {
    Watcher *watcher = (Watcher *) info;
    [watcher watchAddChild: in_child  toParent: in_parent];
    
} // addChild



int main (int argc, const char *argv[]) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSData *xmlData;
    if (argc > 1) {
        xmlData = [NSData dataWithContentsOfFile:
                              [NSString stringWithUTF8String: argv[1]]];
    } else {
		// Use a default value for ease of running in Xcode.
		xmlData = [NSData dataWithContentsOfFile:
		    @"/Applications/Chess.app/Contents/Info.plist"];
    }

    CFXMLParserRef parser;
    
    // set up callbacks.
    CFXMLParserCallBacks callbacks = { 0, createStructure, addChild, 
                                       NULL, NULL,  NULL };

    Watcher *watcher = [[Watcher alloc] init];
    CFXMLParserContext context = { 0, watcher, NULL, NULL, NULL };

    parser = CFXMLParserCreate (kCFAllocatorDefault, (CFDataRef)xmlData, NULL,
                                kCFXMLParserAllOptions, 
                                kCFXMLNodeCurrentVersion,
                                &callbacks, &context);
    if (!CFXMLParserParse(parser)) {
        NSLog (@"parse failed. bummer");
        return (-1);
    }
                  
    CFRelease (parser);
    [watcher release];
    [pool drain];

    return (0);

} // main
