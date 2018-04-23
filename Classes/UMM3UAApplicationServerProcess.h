//
//  UMM3UAApplicationServerProcess.h
//  ulibmtp3
//
//  Created by Andreas Fink on 24.01.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
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
    //NSString                    *_name;
    UMLayerSctp                 *_sctpLink;
    UMM3UAApplicationServer     *_as;
    BOOL                        _congested;
    UMM3UA_Status               _status;

    BOOL                        _speedLimitReached;
    double                      _speedLimit;
    UMThroughputCounter         *_speedCounter;

    UMMTP3PointCode             *_adjacentPointCode;
    UMMTP3PointCode             *_localPointCode;
    BOOL                        _aspup_received;
    BOOL                        _standby_mode;
    NSMutableData       *_incomingStream0;
    NSMutableData       *_incomingStream1;

    UMTimer             *_linktest_timer;
    UMTimer             *_reopen_timer1;
    UMTimer             *_reopen_timer2;
    int                 sltm_serial;

    NSTimeInterval      _linktest_timer_value;
    NSTimeInterval      _reopen_timer1_value;
    NSTimeInterval      _reopen_timer2_value;
    double              _speed;

    UMThroughputCounter	*_speedometer;
    UMThroughputCounter	*_submission_speed;
    time_t  _link_up_time;
    time_t  _link_down_time;
    time_t  _link_congestion_time;
    time_t  _link_speed_excess_time;
    time_t  _link_congestion_cleared_time;
    time_t  _link_speed_excess_cleared_time;
    BOOL     _speed_within_limit;
    UMMutex *_aspLock;
}


@property(readwrite,strong,atomic)  UMM3UAApplicationServer *as;
@property(readonly,strong,atomic)  NSString *name;
@property (readonly) BOOL sctp_connecting;
@property (readonly) BOOL sctp_up;
@property (readonly) BOOL up;
@property (readonly) BOOL active;
@property(readonly)    SCTP_Status                 sctp_status;
@property(readwrite,assign,atomic)   UMM3UA_Status status;


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
- (void)processDAUD:(UMSynchronizedSortedDictionary *)params;
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
- (NSString *)statusString;

@end
