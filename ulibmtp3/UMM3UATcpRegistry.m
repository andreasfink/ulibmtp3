//
//  UMM3UATcpRegistry.m
//  ulibmtp3
//
//  Created by Andreas Fink on 11.08.2025.
//  Copyright © 2025 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMM3UATcpRegistry.h"
#import "UMM3UATcpListener.h"
#import "UMM3UAApplicationServerProcess.h"
#import "UMM3UATcpListener.h"
@implementation UMM3UATcpRegistry

- (UMM3UATcpRegistry *)init
{
    self = [super init];
    if(self)
    {
        _lock           = [[UMMutex alloc]initWithName:@"m3ua-tcp-registry"];
        _listeners      = [[UMSynchronizedDictionary alloc]init];
        _connections    = [[UMSynchronizedDictionary alloc]init];
    }
    return self;
    
}
- (void) addListener:(UMM3UATcpListener *)listener localAddress:(NSString *)address localPort:(int)port
{
    NSString *key = [NSString stringWithFormat:@"%@:%d",address,port];
    ummutex_lock(_lock);
    UMM3UATcpListener *old = _listeners[key];
    if(old)
    {
        [old shutdownBackgroundTask];
    }
    _listeners[key]=listener;
    ummutex_unlock(_lock);
}

- (UMM3UATcpListener *)getListener:(NSString *)address port:(int)port
{
    NSString *key = [NSString stringWithFormat:@"%@:%d",address,port];
    ummutex_lock(_lock);
    UMM3UATcpListener *listener = _listeners[key];
    ummutex_unlock(_lock);
    return listener;
}

- (UMM3UATcpListener *)getOrCreateListener:(NSString *)address port:(int)port logFeed:(UMLogFeed *)feed logLevel:(UMLogLevel)level
{
    NSString *key = [NSString stringWithFormat:@"%@:%d",address,port];
    ummutex_lock(_lock);
    UMM3UATcpListener *listener = _listeners[key];
    if(listener == NULL)
    {
       listener = [[UMM3UATcpListener alloc]initWithPort:port
                                          localIpAddress:address
                                                 logFeed:feed
                                                logLevel:level];
        [listener startBackgroundTask];
        _listeners[key] = listener;
    }
    ummutex_unlock(_lock);
    return listener;
}

- (void) removeListenerForLocalAddress:(NSString *)address port:(int)port
{
    NSString *key = [NSString stringWithFormat:@"%@:%d",address,port];
    ummutex_lock(_lock);
    UMM3UATcpListener *old = _listeners[key];
    if(old)
    {
        [old shutdownBackgroundTask];
        [_listeners removeObjectForKey:key];
    }
    ummutex_unlock(_lock);
}

- (void) addConnection:(UMM3UAApplicationServerProcess *)asp remoteAddress:(NSString *)address remotePort:(int)port
{
    NSString *key = [NSString stringWithFormat:@"%@:%d",address,port];
    ummutex_lock(_lock);
    UMM3UATcpListener *old = _connections[key];
    _connections[key]=asp;
    old = NULL;
    ummutex_unlock(_lock);
}

- (void) removeConnectionForRemoteAddress:(NSString *)address remotePort:(int)port
{
    NSString *key = [NSString stringWithFormat:@"%@:%d",address,port];
    ummutex_lock(_lock);
    [_connections removeObjectForKey:key];
    ummutex_unlock(_lock);
}


- (UMM3UAApplicationServerProcess *)getAspForRemoteAddress:(NSString *)address port:(int)port
{
    NSString *key = [NSString stringWithFormat:@"%@:%d",address,port];
    ummutex_lock(_lock);
    UMM3UAApplicationServerProcess *asp = _connections[key];
    ummutex_unlock(_lock);
    return asp;
}
@end
