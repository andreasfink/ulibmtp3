//
//  UMM3UATcpListener.m
//  ulibmtp3
//
//  Created by Andreas Fink on 11.08.2025.
//  Copyright © 2025 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMM3UATcpListener.h"
#import "UMLayerMTP3.h"
#import "UMM3UATcpRegistry.h"
#import "UMM3UATcpReceiver.h"

#include <poll.h>

@implementation UMM3UATcpListener

- (void)dealloc
{
    [_umsocket close];
    _umsocket = NULL;
    _isInvalid=YES;
}


- (UMM3UATcpListener *)initWithPort:(int)localPort
                      localIpAddress:(NSString *)address
                             logFeed:(UMLogFeed *)feed
                            logLevel:(UMLogLevel)level
{
    NSString *name = [NSString stringWithFormat:@"M3UA-TCP-LISTENER(%@:%d)",address,localPort];
    self = [super initWithName: name];
    if(self)
    {
        _logLevel       = level;
        _logFeed        = feed;
        _listenerLock   = [[UMMutex alloc]initWithName:_name];
        _isInvalid      = NO;
        _port           = localPort;
        _localIpAddress = address;
        _pollTimeoutInMs    = 500;
    }
    return self;
}

- (void)backgroundInit
{
    if(_logLevel <= UMLOG_DEBUG)
    {
        [_logFeed debugText:[NSString stringWithFormat:@"starting:%@",_name]];
    }
    ulib_set_thread_name(_name);
    _umsocket                       = [[UMSocket alloc]initWithType:UMSOCKET_TYPE_TCP name:_name];
    _umsocket.requestedLocalAddress = _localIpAddress;
    _umsocket.requestedLocalPort    = _port;
    if(_dscp)
    {
        [_umsocket setDscpString:_dscp];
    }
    [self setBufferSizes];
    [_umsocket switchToNonBlocking];
#define     LOG_MINOR_ERROR(err,area)  if(err) { NSString *s = [NSString stringWithFormat:@"ERROR in %@: %d %@",area,err,[UMSocket getSocketErrorString:err]]; [self logMinorError:s]; }
#define     LOG_MAYOR_ERROR(err,area)  if(err) { NSString *s = [NSString stringWithFormat:@"ERROR in %@: %d %@",area,err,[UMSocket getSocketErrorString:err]]; [self logMajorError:s]; }
    
    UMSocketError err;
    
    err = [_umsocket setIPDualStack];
    LOG_MINOR_ERROR(err,@"setIPDualStack");
    
    err = [_umsocket setLinger];
    LOG_MINOR_ERROR(err,@"setLinger");
    
    err = [_umsocket setReuseAddr];
    LOG_MINOR_ERROR(err,@"setReuseAddr");
    
    err = [_umsocket setPathMtuDiscovery:YES];
    LOG_MINOR_ERROR(err,@"setPathMtuDiscovery");
    
    err = [_umsocket bind];
    LOG_MAYOR_ERROR(err,@"bind");
    if(err==UMSocketError_no_error)
    {
        _isBound = YES;
        err = [_umsocket listen:128];
        LOG_MAYOR_ERROR(err,@"listen");
        
        if(err!=UMSocketError_no_error)
        {
            _mustListen = YES;
            _isListening = YES;
        }
    }
}

- (int)work
{
    int returnValue = 0;
    if(_mustListen == NO)
    {
        return -1;
    }
    @autoreleasepool
    {
        UMSocketError pollResult = [_umsocket dataIsAvailable:_pollTimeoutInMs];
        if(pollResult == UMSocketError_has_data_and_hup)
        {
            NSLog(@"  UMSocketError_has_data_and_hup");
            /* we get connection request but nobody is there to read the answer so we ignore it */
            ;
        }
        else if (pollResult == UMSocketError_has_data)
        {
            returnValue = 1;
            /* we get new inbound connection request */
            UMSocketError ret1=UMSocketError_no_error;
            UMSocket *clientSocket = [_umsocket accept:&ret1];
            if(clientSocket)
            {
                clientSocket.useSSL                 = _enableSSL;
                clientSocket.serverSideKeyFilename  = _privateKeyFile;
                clientSocket.serverSideKeyData      = _privateKeyFileData;
                clientSocket.serverSideCertFilename = _certFile;
                clientSocket.serverSideCertData     = _certFileData;
                
                UMM3UAApplicationServerProcess *asp = [_registry getAspForRemoteAddress:_umsocket.connectedRemoteAddress port:_umsocket.connectedRemotePort];
                if (asp)
                {
                    UMM3UATcpReceiver *con = [[UMM3UATcpReceiver alloc] initWithSocket:clientSocket registry:_registry asp:asp logFeed:_logFeed logLevel:_logLevel];
                    [con startBackgroundTask];
                }
                else
                {
                    [clientSocket close];
                }
            }
            else
            {
                _lastErr = ret1;
            }
        }
        else if(pollResult == UMSocketError_no_data)
        {
            usleep(10000); /* just to avoid too busy loops */
        }
        else
        {
            _lastErr = pollResult;
            _mustListen=NO;
        }
    }
    _isListening = NO;
    return returnValue;
}

- (void)backgroundExit
{
    _isListening = NO;
    _mustListen = NO;
    [_umsocket close];
    _umsocket = NULL;
    _isBound=NO;
}


- (void)logMinorError:(NSString *)s
{
    [_logFeed minorErrorText:s];
}

- (void)logMajorError:(NSString *)s
{
    [_logFeed majorErrorText:s];
}

- (void)logDebug:(NSString *)s
{
    [_logFeed debugText:s];
}

- (void)setBufferSizes
{
    int currentSize = [_umsocket receiveBufferSize];
    if(currentSize < _minReceiveBufferSize)
    {
        [_umsocket setReceiveBufferSize:_minReceiveBufferSize];
    }
    currentSize = [_umsocket sendBufferSize];
    if(currentSize < _minSendBufferSize)
    {
        [_umsocket setSendBufferSize:_minSendBufferSize];
    }
}

- (void) processError:(UMSocketError)err
{
    [self logMajorError:[NSString stringWithFormat:@"processError %d %@",err,[UMSocket getSocketErrorString:err]]];
}

- (void) processHangup
{
    [self logMinorError:@"processHangup"];
}




- (NSString *)description
{
    return _name;
}


- (void)startListening
{
    _mustListen = YES;
    ummutex_lock(_listenerLock);
    @try
    {
        if(_layers.count==0) /* the first layer is being added */
        {
            [self startBackgroundTask];
            [_registry addListener:self localAddress:_localIpAddress localPort:_port];
        }
    }
    @finally
    {
        ummutex_unlock(_listenerLock);
    }

}

- (void)stopListening
{
    _mustListen = NO;
    ummutex_lock(_listenerLock);
    @try
    {
        [_registry removeListenerForLocalAddress:_localIpAddress port:_port];
    }
    @finally
    {
        ummutex_unlock(_listenerLock);
    }
}

@end
