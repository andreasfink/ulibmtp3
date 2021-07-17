//
//  UMMTP3Link.h
//  ulibmtp3
//
//  Created by Andreas Fink on 04.12.2014.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import <ulib/ulib.h>
#import <ulibsctp/ulibsctp.h>
#import <ulibm2pa/ulibm2pa.h>
#import "UMLayerMTP3ApplicationContextProtocol.h"

@class UMMTP3LinkSet;

typedef enum UMMTP3Link_attachmentStatus
{
    UMMTP3Link_attachmentStatus_detached            =   0,
    UMMTP3Link_attachmentStatus_attachmentPending   =   1,
    UMMTP3Link_attachmentStatus_attached            =   2,
} UMMTP3Link_attachmentStatus;

@interface UMMTP3Link : UMObject
{
    NSString                    *_name;
    int                         _slc;
    NSMutableDictionary         *_userId;
    M2PA_Status                 _last_m2pa_status;
    M2PA_Status                 _current_m2pa_status;
    UMSocketStatus              _sctp_status;
    UMLayerM2PA                 *_m2pa;
    UMMTP3LinkSet               *_linkset;
    UMMTP3Link_attachmentStatus _attachmentStatus;
    NSString                    *_attachmentFailureStatus;
    BOOL                        _congested;
    BOOL                        _processorOutage;
    BOOL                        _speedLimitReached;
    UMTimer                     *_linkTestTimer;
    UMTimer                     *_reopenTimer1;
    UMTimer                     *_reopenTimer2;
    NSTimeInterval              _linkTestTime;
    NSTimeInterval              _reopenTime1;
    NSTimeInterval              _reopenTime2;
    int                         _linkTestMaxOutStanding;
    int                         _outstandingLinkTests;
    UMLogLevel                  _logLevel;
    BOOL                        _forcedOutOfService;
}

- (NSString *)name;

@property (readwrite,strong)    NSString *name;
@property (readwrite,assign)    int slc;
@property (readwrite,assign,atomic)    M2PA_Status         last_m2pa_status;
@property (readwrite,assign,atomic)    M2PA_Status         current_m2pa_status;
@property (readwrite,assign,atomic)    UMSocketStatus         sctp_status;
@property (readwrite,assign)    UMMTP3Link_attachmentStatus attachmentStatus;
@property (readwrite,strong)    UMLayerM2PA     *m2pa;
@property (readwrite,strong)    UMMTP3LinkSet   *linkset;
@property (readwrite,strong)    NSString *attachmentFailureStatus;

@property (readwrite,assign)    BOOL congested;
@property (readwrite,assign)    BOOL processorOutage;
@property (readwrite,assign)    BOOL speedLimitReached;
@property (readwrite,assign)    BOOL emergency;
@property (readwrite,assign)    BOOL forcedOutOfService;
@property (readwrite,assign)    NSTimeInterval linkTestTime;
@property (readwrite,assign)    NSTimeInterval reopenTime1;
@property (readwrite,strong)    UMTimer *reopenTimer1;
@property (readwrite,assign)    NSTimeInterval reopenTime2;
@property (readwrite,strong)    UMTimer *reopenTimer2;
@property (readwrite,assign)    UMLogLevel  logLevel;
@property (readwrite,assign,atomic)    int outstandingLinkTests;

- (void)attachmentConfirmed;
- (void)attachmentFailed:(NSString *)reason;
- (void)sctpStatusUpdate:(UMSocketStatus)s;

- (void)congestionIndication;
- (void)congestionClearedIndication;
- (void)processorOutageIndication;
- (void)processorRestoredIndication;
- (void)speedLimitReachedIndication;
- (void)speedLimitReachedClearedIndication;

- (void)setConfig:(NSDictionary *)cfg applicationContext:(id<UMLayerMTP3ApplicationContextProtocol>)appContext;
- (NSDictionary *)config;
- (void)attach;

- (void)powerOn;
- (void)powerOff;
- (void)forcedPowerOn;
- (void)forcedPowerOff;

- (void)start;
- (void)stop;

- (void)stopDetachAndDestroy;

- (void)startLinkTestTimer;
- (void)stopLinkTestTimer;
- (void)startReopenTimer1;
- (void)startReopenTimer2;
- (void)stopReopenTimer1;
- (void)stopReopenTimer2;
@end
