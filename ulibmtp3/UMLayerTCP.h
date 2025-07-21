//
//  UMLayerTCP.h
//  ulibmtp3
//
//  Created by Andreas Fink on 21.07.2025.
//  Copyright © 2025 Andreas Fink (andreas@fink.org). All rights reserved.
//
#if 0

#import <ulib/ulib.h>

@interface UMLayerTCP : UMLayer
{
     BOOL                _isPassive;
}

@property(readwrite,assign) BOOL isPassive;

/* LAYER API. The following methods queue a task */
#pragma mark -
#pragma mark Task Creators

- (void)adminInit;
- (void)adminSetConfig:(NSDictionary *)config applicationContext:(id<UMLayerSctpApplicationContextProtocol>)appContext;
- (void)adminAttachFor:(id<UMLayerSctpUserProtocol>)caller
               profile:(UMLayerSctpUserProfile *)p
                userId:(id)uid;
- (void)adminDetachFor:(id<UMLayerSctpUserProtocol>)caller
                userId:(id)uid;


- (void)openFor:(id<UMLayerSctpUserProtocol>)caller sendAbortFirst:(BOOL)abortFirst reason:(NSString *)reason;
- (void)closeFor:(id<UMLayerSctpUserProtocol>)caller reason:(NSString *)reason;
- (void)dataFor:(id<UMLayerSctpUserProtocol>)caller
           data:(NSData *)sendingData
       streamId:(uint16_t)sid
     protocolId:(uint32_t)pid
     ackRequest:(NSDictionary *)ack
    synchronous:(BOOL)sync;
- (BOOL)isPassive;


@end
#endif
