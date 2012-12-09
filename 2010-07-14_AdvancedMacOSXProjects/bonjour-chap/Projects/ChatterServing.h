#import <Foundation/Foundation.h>

// Messages the client will receive from the server
@protocol ChatterUsing

- (oneway void)showMessage:(in bycopy NSString *)message 
    fromNickname:(in bycopy NSString *)nickname;

- (bycopy NSString *)nickname;

@end

// Messages the server will receive from the client
@protocol ChatterServing

- (oneway void)sendMessage:(in bycopy NSString *)message 
                fromClient:(in byref id <ChatterUsing>)client;

// Returns NO if someone already has newClient's nickname
- (BOOL)subscribeClient:(in byref id <ChatterUsing>)newClient;

- (void)unsubscribeClient:(in byref id <ChatterUsing>)client;

@end
