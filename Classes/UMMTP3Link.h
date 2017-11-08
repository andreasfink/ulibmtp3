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
@class UMMTP3LinkState;
typedef enum UMMTP3Link_attachmentStatus
{
    UMMTP3Link_attachmentStatus_detached            =   0,
    UMMTP3Link_attachmentStatus_attachmentPending   =   1,
    UMMTP3Link_attachmentStatus_attached            =   2,
} UMMTP3Link_attachmentStatus;

@interface UMMTP3Link : UMObject
{
    NSString                    *name; /* will be set by linkset to linksetname:<slc> */
    int                         slc;
    NSMutableDictionary         *userId;
    UMMTP3LinkState             *linkState;
    M2PA_Status                 m2pa_status;
    SCTP_Status                 sctp_status;
    UMLayerM2PA __weak          *m2pa;
    UMMTP3LinkSet __weak        *linkset;
    UMMTP3Link_attachmentStatus attachmentStatus;
    NSString                    *attachmentFailureStatus;
    BOOL                        congested;
    BOOL                        processorOutage;
    BOOL                        speedLimitReached;
    UMTimer                     *linkTestTimer;
    NSTimeInterval              linkTestTime;
    UMLogLevel                  logLevel;
}

- (NSString *)name;

@property (readwrite,strong)    NSString *name;
@property (readwrite,assign)    int slc;
@property (readwrite,strong)    UMMTP3LinkState     *linkState;
@property (readwrite,assign)    M2PA_Status         m2pa_status;
@property (readwrite,assign)    SCTP_Status         sctp_status;
@property (readwrite,assign)    UMMTP3Link_attachmentStatus attachmentStatus;
@property (readwrite,weak)      UMLayerM2PA     *m2pa;
@property (readwrite,weak)      UMMTP3LinkSet   *linkset;
@property (readwrite,strong)    NSString *attachmentFailureStatus;

@property (readwrite,assign)    BOOL congested;
@property (readwrite,assign)    BOOL processorOutage;
@property (readwrite,assign)    BOOL speedLimitReached;
@property (readwrite,assign)    NSTimeInterval linkTestTime;



- (void)attachmentConfirmed;
- (void)attachmentFailed:(NSString *)reason;
- (void)sctpStatusUpdate:(SCTP_Status)s;
- (void)m2paStatusUpdate:(M2PA_Status)s;
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
- (void)start;
- (void)stop;


@end
