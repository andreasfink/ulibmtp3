//
//  UMM3UATcpReceiver.h
//  ulibmtp3
//
//  Created by Andreas Fink on 11.08.2025.
//  Copyright © 2025 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/ulib.h>

@class UMM3UAApplicationServerProcess;
@class UMM3UATcpRegistry;

@interface UMM3UATcpReceiver : UMBackgrounder
{
    UMSocket                        *_socket;
    UMM3UAApplicationServerProcess  *_asp;
    UMM3UATcpRegistry               *_registry;
    UMLogLevel                      _logLevel;
    int                             _receivePollTimeoutMs;
    NSDate                          *_lastActivity;
    BOOL                            _mustClose;
    NSTimeInterval                  _idleTimeout;
}

- (UMM3UATcpReceiver *)initWithSocket:(UMSocket *)socket registry:(UMM3UATcpRegistry *)registry asp:(UMM3UAApplicationServerProcess *)asp logFeed:(UMLogFeed *)feed logLevel:(UMLogLevel)level;

@end
