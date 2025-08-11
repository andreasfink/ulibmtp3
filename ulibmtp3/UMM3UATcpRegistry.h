//
//  UMM3UATcpRegistry.h
//  ulibmtp3
//
//  Created by Andreas Fink on 11.08.2025.
//  Copyright © 2025 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/ulib.h>

@class UMM3UATcpListener;
@class UMM3UAApplicationServerProcess;

@interface UMM3UATcpRegistry : UMObject
{
    UMMutex                      *_lock;
    UMSynchronizedDictionary     *_listeners; /* key is "local address:port" */
    UMSynchronizedDictionary     *_connections; /* key is "remote address:remote port where remote port can be 0" */
}

- (void) addListener:(UMM3UATcpListener *)listener localAddress:(NSString *)address localPort:(int)port;
- (void) removeListenerForLocalAddress:(NSString *)address port:(int)port;
- (UMM3UATcpListener *)getListener:(NSString *)address port:(int)port;
- (UMM3UATcpListener *)getOrCreateListener:(NSString *)address port:(int)port logFeed:(UMLogFeed *)feed logLevel:(UMLogLevel)level;

- (void) addConnection:(UMM3UAApplicationServerProcess *)asp remoteAddress:(NSString *)address remotePort:(int)port;
- (void) removeConnectionForRemoteAddress:(NSString *)address remotePort:(int)port;

- (UMM3UAApplicationServerProcess *)getAspForRemoteAddress:(NSString *)address port:(int)port;
- (NSString *)contentText;

@end
