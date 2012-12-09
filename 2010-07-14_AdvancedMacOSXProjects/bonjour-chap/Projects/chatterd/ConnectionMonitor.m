#import "ConnectionMonitor.h"

@implementation ConnectionMonitor

- (BOOL)connection:(NSConnection *)ancestor 
                 shouldMakeNewConnection:(NSConnection *)conn
{
        NSLog(@"creating new connection: %d total connections", 
                         [[NSConnection allConnections] count]);
        return YES;
}

- (void)connectionDidDie:(NSNotification *)note
{
    NSConnection *connection = [note object];
    NSLog(@"connection did die: %@", connection);
}
@end
