#import "ConnectionMonitor.h"

@implementation ConnectionMonitor

- (BOOL) connection: (NSConnection *) ancestor
shouldMakeNewConnection: (NSConnection *) connection {
    NSLog (@"creating new connection");
    return (YES);

} // shouldMakeNewConnection


- (void) connectionDidDie: (NSNotification *) notification {
    NSConnection *connection = [notification object];
    NSLog (@"connection died :'-(  : %@", connection);
} // connectionDidDie

@end // ConnectionMonitor
