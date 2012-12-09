#import "ChatterServer.h"
#import "ChatterServing.h"
#import "ConnectionMonitor.h"
#include <sys/socket.h>

#import <Foundation/Foundation.h>

int main (int argc, const char * argv[]) {
    NSSocketPort *receivePort;
    NSConnection *connection;

    // +++ new stuff
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    if (argc != 2) {
       NSLog(@"Usage: chatterd <servicename>");
       exit(-1);
    }
    NSString *serviceName = [NSString stringWithUTF8String:argv[1]];
    NSNetService *netService;
    // --- end of new stuff

    NSRunLoop *runloop = [NSRunLoop currentRunLoop];
    ConnectionMonitor *monitor = [[ConnectionMonitor alloc] init];
    ChatterServer *chatterServer = [[ChatterServer alloc] init];

    NS_DURING
        // This server will wait for requests on port 8081
        receivePort = [[NSSocketPort alloc] initWithTCPPort:8081];
    NS_HANDLER
        NSLog(@"unable to get port 8081");
        exit(-1);
    NS_ENDHANDLER

    // Create the connection object
    connection = [NSConnection connectionWithReceivePort:receivePort 
                                                sendPort:nil];

    // The port is retained by the connection
    [receivePort release];

    // When clients use this connection, they will 
    // talk to the ChatterServer
    [connection setRootObject:chatterServer];

    // The chatter server is retained by the connection
    [chatterServer release];

    // Set up the monitor object
    [connection setDelegate:monitor];
    [[NSNotificationCenter defaultCenter] addObserver:monitor 
              selector:@selector(connectionDidDie:) 
                  name:NSConnectionDidDieNotification 
                object:nil];

    // +++ new stuff
    netService = [[NSNetService alloc] initWithDomain:@"" 
                                                type:@"_chatter._tcp." 
                                                name:serviceName 
                                                port:8081];
    [netService setDelegate:monitor];
    [netService publish];
    NSLog(@"service published = %@", netService);
    // --- end of new stuff

    // Start the runloop
    [runloop run];      

    // If the run loop exits (and I do not know why it would), cleanup
    [connection release];
    [monitor release];
    [pool release];
    return 0;
}
