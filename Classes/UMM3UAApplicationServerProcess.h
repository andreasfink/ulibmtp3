//
//  UMM3UAApplicationServerProcess.h
//  ulibmtp3
//
//  Created by Andreas Fink on 24.01.17.
//  Copyright © 2017 Andreas Fink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ulibsctp/ulibsctp.h>
#import "UMMTP3LinkState.h"
#import "UMMTP3Variant.h"
#import "UMMTP3PointCode.h"
#import "UMM3UAStatus.h"
#import "UMMTP3Label.h"

@class UMM3UAApplicationServer;

@interface UMM3UAApplicationServerProcess : UMLayer<UMLayerSctpUserProtocol>
{
    NSString                    *name;
    UMLayerSctp                 *sctpLink;
    SCTP_Status                 sctp_status;
    UMM3UAApplicationServer __weak  *as;
    BOOL                        congested;

    UMM3UA_Status               status;

    BOOL                        speedLimitReached;
    double                      speedLimit;
    UMThroughputCounter         *speedCounter;

    UMMTP3PointCode             *adjacentPointCode;
    UMMTP3PointCode             *localPointCode;
    //UMM3UA_Status               m3ua_status;
    BOOL                        aspup_received;
    BOOL                        standby_mode;
    NSMutableData       *incomingStream0;
    NSMutableData       *incomingStream1;
//    UMMTP3Variant       variant;

    UMTimer             *linktest_timer;
    UMTimer             *reopen_timer1;
    UMTimer             *reopen_timer2;
    int                 sltm_serial;

    NSTimeInterval      linktest_timer_value;
    NSTimeInterval      reopen_timer1_value;
    NSTimeInterval      reopen_timer2_value;
    double              speed;

    UMThroughputCounter	*speedometer;
    UMThroughputCounter	*submission_speed;
    time_t  link_up_time;
    time_t  link_down_time;
    time_t  link_congestion_time;
    time_t  link_speed_excess_time;
    time_t  link_congestion_cleared_time;
    time_t  link_speed_excess_cleared_time;
    BOOL     speed_within_limit;
}

@property (readwrite,weak)    UMM3UAApplicationServer  *as;
@property (readwrite,strong)  NSString *name;

@property (readwrite,assign,atomic) UMM3UA_Status status;
@property (readonly) BOOL sctp_connecting;
@property (readonly) BOOL sctp_up;
@property (readonly) BOOL up;
@property (readonly) BOOL active;

- (void)start;
- (void)stop;

- (void)powerOn;
- (void)powerOff;

- (void)goInactive;
- (void)goActive;

- (void)setConfig:(NSDictionary *)cfg applicationContext:(id)appContext;
- (UMSynchronizedSortedDictionary *)config;

- (void)processBEAT:(NSData *)params;
- (void)processERR:(UMSynchronizedSortedDictionary *)params;
- (void)processNTFY:(UMSynchronizedSortedDictionary *)params;
- (void)processDATA:(UMSynchronizedSortedDictionary *)params;
- (void)processDUNA:(UMSynchronizedSortedDictionary *)params;
- (void)processDAVA:(UMSynchronizedSortedDictionary *)params;
- (void)processSCON:(UMSynchronizedSortedDictionary *)params;
- (void)processDUPU:(UMSynchronizedSortedDictionary *)params;
- (void)processDRST:(UMSynchronizedSortedDictionary *)params;
- (void)processASPUP:(UMSynchronizedSortedDictionary *)params;
- (void)processASPDN:(UMSynchronizedSortedDictionary *)params;
- (void)processASPUP_ACK:(UMSynchronizedSortedDictionary *)params;
- (void)processASPDN_ACK:(UMSynchronizedSortedDictionary *)params;
- (void)processASPAC:(UMSynchronizedSortedDictionary *)params;
- (void)processASPIA:(UMSynchronizedSortedDictionary *)params;
- (void)processASPAC_ACK:(UMSynchronizedSortedDictionary *)params;
- (void)processASPIA_ACK:(UMSynchronizedSortedDictionary *)params;
- (void)processREG_REQ:(UMSynchronizedSortedDictionary *)params;
- (void)processREG_RSP:(UMSynchronizedSortedDictionary *)params;
- (void)processDEREG_REQ:(UMSynchronizedSortedDictionary *)params;
- (void)processDEREG_RSP:(UMSynchronizedSortedDictionary *)params;

- (void)advertizePointcodeAvailable:(UMMTP3PointCode *)pc mask:(int)mask;
- (void)advertizePointcodeRestricted:(UMMTP3PointCode *)pc mask:(int)mask;
- (void)advertizePointcodeUnavailable:(UMMTP3PointCode *)pc mask:(int)mask;

-(void)sendPdu:(NSData *)data
         label:(UMMTP3Label *)label
       heading:(int)heading
            ni:(int)ni
            mp:(int)mp
            si:(int)si
    ackRequest:(NSDictionary *)ackRequest
 correlationId:(uint32_t)correlation_id;

@end
