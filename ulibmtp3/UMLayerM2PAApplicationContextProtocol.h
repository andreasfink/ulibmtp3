//
//  UMSS7Stack_ApplicationContext_protocol.h
//  ulibm2pa
//
//  Created by Andreas Fink on 24.01.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/ulib.h>

@class UMLayerM2PA;

@protocol UMLayerM2PAApplicationContextProtocol<NSObject>

- (UMLayerSctp *)getSCTP:(NSString *)name;

@end


@protocol UMM2PAStatisticsCouter<NSObject>

@property(readonly,strong)     UMThroughputCounter *inboundThroughputPackets;
@property(readonly,strong)     UMThroughputCounter *outboundThroughputPackets;
@property(readonly,strong)     UMThroughputCounter *inboundThroughputBytes;
@property(readonly,strong)     UMThroughputCounter *outboundThroughputBytes;

@end
