//
//  UMM3UAApplicationServerProcess.h
//  ulibmtp3
//
//  Created by Andreas Fink on 24.01.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ulibsctp/ulibsctp.h>
#import "UMMTP3Variant.h"
#import "UMMTP3PointCode.h"
#import "UMM3UAStatus.h"
#import "UMMTP3Label.h"

#define M3UA_DEFAULT_BEAT_TIMER                0
#define M3UA_DEFAULT_MAX_BEAT_OUTSTANDING      3

@class UMM3UAApplicationServer;


@interface UMM3UAApplicationServerProcess : UMLayer<UMLayerSctpUserProtocol>
{
    UMLayerSctp                 *_sctpLink;
    UMM3UAApplicationServer     *_as;
    BOOL                        _congested;
    UMM3UA_Status               _status;

    BOOL                        _speedLimitReached;
    double                      _speedLimit;

    UMMTP3PointCode             *_adjacentPointCode;
    UMMTP3PointCode             *_localPointCode;
    BOOL                        _aspup_received;
    BOOL                        _standby_mode;
    NSMutableData       *_incomingStream0;
    NSMutableData       *_incomingStream1;
    UMMutex             *_incomingStreamLock;

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

    NSDate *_lastBeatReceived;
    NSDate *_lastBeatAckReceived;
    NSDate *_lastBeatSent;
    NSDate *_lastBeatAckSent;

    UMTimer                     *_beatTimer;
    NSTimeInterval              _beatTime;
    int                         _beatMaxOutstanding;
    UMTimer                     *_houseKeepingTimer;
    
    UMThroughputCounter *_inboundThroughputPackets;
    UMThroughputCounter *_outboundThroughputPackets;
    UMThroughputCounter *_inboundThroughputBytes;
    UMThroughputCounter *_outboundThroughputBytes;
    NSString            *_lastError;
    BOOL                _forcedOutOfService;
}


@property(readwrite,strong,atomic)  UMM3UAApplicationServer *as;
@property(readwrite,strong,atomic)  NSString *name;
@property (readonly) BOOL sctp_connecting;
@property (readonly) BOOL sctp_up;
@property (readonly) BOOL up;
@property (readonly) BOOL active;
@property(readonly)    UMSocketStatus                 sctp_status;
@property(readwrite,assign,atomic)   UMM3UA_Status status;

@property(readwrite,strong,atomic)  NSDate *lastBeatReceived;
@property(readwrite,strong,atomic)  NSDate *lastBeatAckReceived;
@property(readwrite,strong,atomic)  NSDate *lastBeatSent;
@property(readwrite,strong,atomic)  NSDate *lastBeatAckSent;
@property(readwrite,strong,atomic)  NSString *lastError;
@property(readwrite,assign,atomic)  NSTimeInterval beatTime;
@property(readwrite,assign,atomic)  int beatMaxOutstanding;
@property(readwrite,strong,atomic)  UMThroughputCounter *inboundThroughputPackets;
@property(readwrite,strong,atomic)  UMThroughputCounter *outboundThroughputPackets;
@property(readwrite,strong,atomic)  UMThroughputCounter *inboundThroughputBytes;
@property(readwrite,strong,atomic)  UMThroughputCounter *outboundThroughputBytes;


@property (readonly)                BOOL congested;
@property (readonly)                UMThroughputCounter  *speedometer;
@property (readonly)                BOOL                 standby_mode;


- (void)start;
- (void)stop;

- (void)powerOn;
- (void)powerOff;

- (void)forcedPowerOn;
- (void)forcedPowerOff;

- (void)goInactive;
- (void)goActive;

- (void)setConfig:(NSDictionary *)cfg applicationContext:(id)appContext;
- (UMSynchronizedSortedDictionary *)config;

- (void)processBEAT:(UMSynchronizedSortedDictionary *)params;
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

-(void)sendPdu:(NSData *)data
         label:(UMMTP3Label *)label
       heading:(int)heading
            ni:(int)ni
            mp:(int)mp
            si:(int)si
    ackRequest:(NSDictionary *)ackRequest
 correlationId:(uint32_t)correlation_id
       options:(NSDictionary *)options;

- (NSString *)statusString;

- (UMSynchronizedSortedDictionary *)m3uaStatusDict;
@end
