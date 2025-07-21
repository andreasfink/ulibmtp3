//
//  UMLayerTCP.m
//  ulibmtp3
//
//  Created by Andreas Fink on 21.07.2025.
//  Copyright © 2025 Andreas Fink (andreas@fink.org). All rights reserved.
//
#if 0
#import "UMLayerTCP.h"
#import "UMLayerTCPUserProtocol.h"

- (void)adminInit
{
    
}
- (void)adminSetConfig:(NSDictionary *)config applicationContext:(id)appContext
{
    
}

- (void)adminAttachFor:(id)caller
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

