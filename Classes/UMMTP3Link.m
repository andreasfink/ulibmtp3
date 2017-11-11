//
//  UMMTP3Link.m
//  ulibmtp3
//
//  Created by Andreas Fink on 04/12/14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import "UMMTP3Link.h"
#import "UMMTP3LinkSet.h"
#import "UMMTP3LinkState.h"
#import "UMLayerMTP3.h"
#import "UMLayerMTP3ApplicationContextProtocol.h"

@implementation UMMTP3Link


@synthesize name;
@synthesize attachmentStatus;
@synthesize m2pa;
@synthesize linkset;
@synthesize slc;
@synthesize attachmentFailureStatus;

@synthesize congested;
@synthesize processorOutage;
@synthesize speedLimitReached;
@synthesize linkState;
@synthesize linkTestTime;

- (UMMTP3Link *) init
{
    self = [super init];
    if(self)
    {
        linkState = [[UMMTP3LinkState alloc]init];
        logLevel = UMLOG_MAJOR;
    }
    return self;
}

- (void)attach
{
    UMLayerM2PAUserProfile *profile = [[UMLayerM2PAUserProfile alloc]init];
    profile.allMessages =YES;
    
    [m2pa adminAttachFor:linkset.mtp3 profile:profile userId:linkset.name ni:linkset.mtp3.networkIndicator slc:slc];
}


- (void)attachmentConfirmed
{
    attachmentStatus = UMMTP3Link_attachmentStatus_attached;
    attachmentFailureStatus =@"";
}

- (void)attachmentFailed:(NSString *)reason
{
    attachmentStatus = UMMTP3Link_attachmentStatus_detached;
    attachmentFailureStatus = reason;
}

- (void)sctpStatusUpdate:(SCTP_Status)s
{
    self.sctp_status = s;
}

- (void)m2paStatusUpdate:(M2PA_Status)newStatus
{
    M2PA_Status old_status = self.m2pa_status;
    self.m2pa_status = newStatus;
    
    if((old_status == M2PA_STATUS_OFF) && (newStatus == M2PA_STATUS_OOS))
    {
        [m2pa startFor:linkset.mtp3];
    }
    if(newStatus==M2PA_STATUS_ALIGNED_READY)
    {
    }
    if((old_status != M2PA_STATUS_IS) && (newStatus == M2PA_STATUS_IS))
    {
        [self startLinkTestTimer];
    }
    else if((old_status == M2PA_STATUS_IS) && (newStatus != M2PA_STATUS_IS))
    {
        [self stopLinkTestTimer];
    }
}

- (void)congestionIndication
{
    congested = YES;
}

- (void)congestionClearedIndication
{
    congested = NO;
}

- (void)processorOutageIndication
{
    processorOutage = YES;
}

- (void)processorRestoredIndication
{
    processorOutage = NO;
}

- (void)speedLimitReachedIndication
{
    speedLimitReached=YES;
}

- (void)speedLimitReachedClearedIndication
{
    speedLimitReached=NO;
}

- (void)setConfig:(NSDictionary *)cfg applicationContext:(id<UMLayerMTP3ApplicationContextProtocol>)appContext
{
    if (cfg[@"slc"])
    {
        slc = [cfg[@"slc"] intValue];
        if(cfg[@"link-test-time"])
        {
            linkTestTime  = [cfg[@"linktest-timer"] intValue];
        }
        else
        {
            linkTestTime = 30.0;
        }
    }
    logLevel = UMLOG_MAJOR;
    if(cfg[@"log-level"])
    {
        logLevel = [cfg[@"log-level"] intValue];
    }
}

- (NSDictionary *)config
{
    NSMutableDictionary *cfg = [[NSMutableDictionary alloc]init];
    cfg[@"slc"] = @(slc);
    return cfg;
}


- (void)powerOn
{
    [m2pa powerOnFor:linkset.mtp3];
}
- (void)powerOff
{
    [m2pa powerOffFor:linkset.mtp3];
}

- (void)start
{
    [m2pa startFor:linkset.mtp3];
}
- (void)stop
{
    [m2pa stopFor:linkset.mtp3];
}

- (void)linkTestTimerEvent:(id)parameter
{
    [linkset linktestTimeEventForLink:self];
}

-(void)startLinkTestTimer2
{
/*    NSTimer *linkTestTimer = [NSTimer timerWithTimeInterval:linkTestTime target:self selector:@selector(linkTestTimerEvent:) userInfo:nil repeats:YES];
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    [runLoop addTimer:linkTestTimer forMode:NSDefaultRunLoopMode];
 */
}

- (void)startLinkTestTimer
{
    if(linkTestTime > 0)
    {
        linkTestTimer = [[UMTimer alloc]initWithTarget:self selector:@selector(linkTestTimerEvent:) object:NULL duration:(linkTestTime * 1000000) name:@"linktestTimer" repeats:YES];
        [linkTestTimer start];
    }
        /*
    if(linkTestTime > 0)
    {
        [self performSelectorOnMainThread:@selector(startLinkTestTimer2) withObject:NULL waitUntilDone:NO];
    }
 */
}

- (void)stopLinkTestTimer
{
    [linkTestTimer stop];
}

@end
