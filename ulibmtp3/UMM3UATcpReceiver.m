//
//  UMM3UATcpReceiver.m
//  ulibmtp3
//
//  Created by Andreas Fink on 11.08.2025.
//  Copyright © 2025 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulibmtp3/UMM3UATcpReceiver.h>
#import <ulibmtp3/UMM3UAApplicationServerProcess.h>
#import <ulibmtp3/UMM3UATcpRegistry.h>

@implementation UMM3UATcpReceiver


- (UMM3UATcpReceiver *)initWithSocket:(UMSocket *)socket registry:(UMM3UATcpRegistry *)registry asp:(UMM3UAApplicationServerProcess *)asp logFeed:(UMLogFeed *)feed logLevel:(UMLogLevel)level
{
    NSString *name = [NSString stringWithFormat:@"TCP-RECEIVER-ASP[%@]",asp.name];
    self = [super initWithName:name];
    if(self)
    {
        _socket = socket;
        _registry = registry;
        _asp = asp;
        _logFeed = feed;
        _logLevel = level;
        _receivePollTimeoutMs = 500;
        _idleTimeout = 90.0; 
        if(_asp.tcpReceiver)
        {
            [_asp.tcpReceiver close];
        }
        _asp.tcpReceiver = self;
    }
    return self;
}

- (void)close
{
    [_socket close];
    _socket = NULL;
}

- (void)backgroundInit
{
    if(_socket.useSSL)
    {
        ulib_set_thread_name([NSString stringWithFormat:@"M3UATcpReceiver %@ (with SSL)",_socket.description]);
        if(_socket.sslActive==NO)
        {
            [_socket startTLS];
        }
    }
    else
    {
        ulib_set_thread_name([NSString stringWithFormat:@"M3UATcpReceiver %@",_socket.description]);
    }
    _lastActivity = [NSDate date];
}

- (int)work
{
    UMSocketError   err;
    BOOL dataReceived = NO;
    
    
    NSDate *now = [NSDate date];

    if((_mustClose) || (_socket==NULL))
    {
        return -1;
    }
    
    UMSocketError pollResult = [_socket dataIsAvailable:_receivePollTimeoutMs];
    if(pollResult == UMSocketError_invalid_file_descriptor)
    {
        _mustClose = YES;
    }
    else  if (pollResult == UMSocketError_no_data)
    {
        if(_idleTimeout>0)
        {
            NSTimeInterval idleTime = [now timeIntervalSinceDate:_lastActivity];
            if(idleTime > _idleTimeout)
            {
                _mustClose = YES;
                return -1;
            }
        }
        return 0;
    }
    else if((pollResult == UMSocketError_has_data) || (pollResult== UMSocketError_has_data_and_hup))
    {
        _lastActivity = now;
        NSData *incomingData = NULL;
        err = [_socket receiveEverythingTo:&incomingData];
        if(incomingData.length>0)
        {
            dataReceived = YES;
            [_asp tcpDataIndication:incomingData];
        }
        if(pollResult == UMSocketError_has_data_and_hup)
        {
            _mustClose = YES;
        }
    }
    else
    {
        _mustClose = YES;
    }
    if(_mustClose)
    {
        return -1;
    }
    if(dataReceived)
    {
        return 1;
    }
    return 0;
}
@end
