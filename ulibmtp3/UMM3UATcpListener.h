//
//  UMM3UATcpListener.h
//  ulibmtp3
//
//  Created by Andreas Fink on 11.08.2025.
//  Copyright © 2025 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/ulib.h>

@class UMM3UATcpRegistry;

@interface UMM3UATcpListener : UMBackgrounder
{
    UMSocket                    *_umsocket;
    int                         _port;
    NSString                    *_localIpAddress;
    BOOL                        _isBound;
    BOOL                        _isListening;
    UMMutex                     *_listenerLock;
    UMM3UATcpRegistry           *_registry;
    UMSynchronizedDictionary    *_layers;
    NSNumber                    *_configuredMtu;
    BOOL                        _firstMessage;
    BOOL                        _isInvalid;
    int                         _minReceiveBufferSize;
    int                         _minSendBufferSize;
    NSString                    *_dscp;
    UMLogLevel                  _logLevel;
    int                         _pollTimeoutInMs;
    BOOL                        _mustListen;
    BOOL                        _enableSSL;
    NSString                    *_privateKeyFile;
    NSData                      *_privateKeyFileData;
    NSString                    *_certFile;
    NSData                      *_certFileData;
    UMSocketError               _lastErr;
}


@property(readwrite,atomic,strong)  UMSocket                    *umsocket;
@property(readwrite,atomic,assign)  int                         port;
@property(readwrite,atomic,strong)  NSString                    *localIpAddress;
@property(readwrite,atomic,assign)  BOOL                        isBound;
@property(readwrite,atomic,assign)  BOOL                        isListening;
@property(readwrite,atomic,strong)  UMMutex                     *listenerLock;
@property(readwrite,atomic,strong)  UMM3UATcpRegistry           *registry;
@property(readwrite,atomic,strong)  UMSynchronizedDictionary    *layers;
@property(readwrite,atomic,strong)  NSNumber                    *configuredMtu;
@property(readwrite,atomic,assign)  BOOL                        firstMessage;
@property(readwrite,atomic,assign)  BOOL                        isInvalid;
@property(readwrite,atomic,assign)  int                         minReceiveBufferSize;
@property(readwrite,atomic,assign)  int                         minSendBufferSize;
@property(readwrite,atomic,strong)  NSString                    *dscp;
@property(readwrite,atomic,assign)  UMLogLevel                  logLevel;
@property(readwrite,atomic,assign)  int                         pollTimeoutInMs;
@property(readwrite,atomic,assign)  BOOL                        mustListen;
@property(readwrite,atomic,assign)  BOOL                        enableSSL;
@property(readwrite,atomic,strong)  NSString                    *privateKeyFile;
@property(readwrite,atomic,strong)  NSData                      *privateKeyFileData;
@property(readwrite,atomic,strong)  NSString                    *certFile;
@property(readwrite,atomic,strong)  NSData                      *certFileData;
@property(readwrite,atomic,assign)  UMSocketError               lastErr;

- (UMM3UATcpListener *)initWithPort:(int)localPort
                     localIpAddress:(NSString *)address
                            logFeed:(UMLogFeed *)feed
                           logLevel:(UMLogLevel)level;


- (void)startListening;
- (void)stopListening;
- (NSString *)name;
@end

