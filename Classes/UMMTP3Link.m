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
#import "UMLayerMTP3.h"
#import "UMLayerMTP3ApplicationContextProtocol.h"

@implementation UMMTP3Link

- (UMMTP3Link *) init
{
    self = [super init];
    if(self)
    {
        _logLevel = UMLOG_MAJOR;
        _last_m2pa_status = M2PA_STATUS_OFF;
    }
    return self;
}

- (void)attach
{
    UMLayerM2PAUserProfile *profile = [[UMLayerM2PAUserProfile alloc]init];
    profile.allMessages =YES;

    [_m2pa adminAttachFor:_linkset.mtp3
                  profile:profile
                 linkName:_linkset.name
                      slc:_slc];
}


- (void)attachmentConfirmed
{
    _attachmentStatus = UMMTP3Link_attachmentStatus_attached;
    _attachmentFailureStatus =@"";
}

- (void)attachmentFailed:(NSString *)reason
{
    _attachmentStatus = UMMTP3Link_attachmentStatus_detached;
    _attachmentFailureStatus = reason;
}

- (void)sctpStatusUpdate:(SCTP_Status)s
{
    self.sctp_status = s;
}

- (void)m2paStatusUpdate:(M2PA_Status)newStatus
{
    M2PA_Status old_status = _last_m2pa_status;
    _last_m2pa_status = newStatus;

    if((old_status == M2PA_STATUS_OFF) && (newStatus == M2PA_STATUS_OOS))
    {
        [_m2pa startFor:_linkset.mtp3];
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
    _congested = YES;
}

- (void)congestionClearedIndication
{
    _congested = NO;
}

- (void)processorOutageIndication
{
    _processorOutage = YES;
}

- (void)processorRestoredIndication
{
    _processorOutage = NO;
}

- (void)speedLimitReachedIndication
{
    _speedLimitReached=YES;
}

- (void)speedLimitReachedClearedIndication
{
    _speedLimitReached=NO;
}

- (void)setConfig:(NSDictionary *)cfg applicationContext:(id<UMLayerMTP3ApplicationContextProtocol>)appContext
{
    if (cfg[@"name"])
    {
        self.name = cfg[@"name"];
    }
    if (cfg[@"slc"])
    {
        _slc = [cfg[@"slc"] intValue];
    }
    if(cfg[@"link-test-time"])
    {
        _linkTestTime  = (NSTimeInterval)[cfg[@"link-test-time"] doubleValue];
    }
    else
    {
        _linkTestTime = 30.0;
    }
    _logLevel = UMLOG_MAJOR;
    if(cfg[@"log-level"])
    {
        _logLevel = [cfg[@"log-level"] intValue];
    }

    if (cfg[@"mtp3-linkset"])
    {
        NSString *linkset_name = [cfg[@"mtp3-linkset"] stringValue];
        _linkset = [appContext getMTP3LinkSet:linkset_name];
        if(_linkset==NULL)
        {
            NSString *s = [NSString stringWithFormat:@"Can not find mtp3 linkset '%@' referred from mtp3 link '%@'",linkset_name,_name];
            @throw([NSException exceptionWithName:[NSString stringWithFormat:@"CONFIG_ERROR FILE %s line:%ld",__FILE__,(long)__LINE__]
                                           reason:s
                                         userInfo:NULL]);
        }
    }

    if (cfg[@"m2pa"])
    {
        NSString *m2pa_name = [cfg[@"m2pa"] stringValue];
        _m2pa = [appContext getM2PA:m2pa_name];
        if(_m2pa==NULL)
        {
            NSString *s = [NSString stringWithFormat:@"Can not find m2pa layer '%@' referred from mtp3 link '%@'",m2pa_name,_name];
            @throw([NSException exceptionWithName:[NSString stringWithFormat:@"CONFIG_ERROR FILE %s line:%ld",__FILE__,(long)__LINE__]
                                           reason:s
                                         userInfo:NULL]);

        }
    }
    [_linkset addLink:self];
    UMLayerM2PAUserProfile *up = [[UMLayerM2PAUserProfile alloc]initWithDefaultProfile];
    [_m2pa adminAttachFor:self.linkset.mtp3
                  profile:up
                 linkName:self.name
                      slc:_slc];
}

- (NSDictionary *)config
{
    NSMutableDictionary *cfg = [[NSMutableDictionary alloc]init];
    cfg[@"slc"] = @(_slc);
    return cfg;
}


- (void)powerOn
{
    [_m2pa powerOnFor:_linkset.mtp3];
}
- (void)powerOff
{
    [_m2pa powerOffFor:_linkset.mtp3];
}

- (void)start
{
    [_m2pa startFor:_linkset.mtp3];
}
- (void)stop
{
    [_m2pa stopFor:_linkset.mtp3];
}

- (void)linkTestTimerEvent:(id)parameter
{
    [_linkset linktestTimeEventForLink:self];
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
    if(_linkTestTime > 0)
    {
        if(_linkTestTimer==NULL)
        {
            _linkTestTimer = [[UMTimer alloc]initWithTarget:self
                                                   selector:@selector(linkTestTimerEvent:)
                                                     object:NULL
                                                    seconds:_linkTestTime
                                                       name:@"linktestTimer" repeats:YES];
        }
        [_linkTestTimer start];
    }
}

- (void)stopLinkTestTimer
{
    [_linkTestTimer stop];
}

- (void)stopDetachAndDestroy
{
    /* FIXME: do something here */
}
@end

