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

#define MTP3_LINK_REOPEN_TIME1_DEFAULT   6.0 /* if link goes down, we restart it in 6 seconds */
#define MTP3_LINK_REOPEN_TIME2_DEFAULT   180 /* if link doesnt come up within 3 minutes, we kill it and after restarttimer1 restart it */
#define	MTP3_LINK_TEST_TIMER_DEFAULT		30.0	/* T2 of MTP2 30...90 sec*/
#define	MTP3_LINK_TEST_ACK_TIMER_DEFAULT	6.0		/* T1 of MTP2 . 4...12 sec*/
@implementation UMMTP3Link

- (UMMTP3Link *) init
{
    self = [super init];
    if(self)
    {
        _logLevel = UMLOG_MAJOR;
        _last_m2pa_status = M2PA_STATUS_OFF;
        _current_m2pa_status = M2PA_STATUS_OFF;
        _linkTestAckTime = MTP3_LINK_TEST_ACK_TIMER_DEFAULT; 
        _linkTestTime = MTP3_LINK_TEST_TIMER_DEFAULT; 
        _reopenTime1 = MTP3_LINK_REOPEN_TIME1_DEFAULT;
        _reopenTime2 = MTP3_LINK_REOPEN_TIME2_DEFAULT;
        _reopenTimer1 = [[UMTimer alloc]initWithTarget:self
                                             selector:@selector(reopenTimer1Event:)
                                               object:NULL
                                              seconds:_reopenTime1
                                                 name:@"reopenTimer1"
                                              repeats:NO
                                      runInForeground:YES];
        _reopenTimer2 = [[UMTimer alloc]initWithTarget:self
                                             selector:@selector(reopenTimer2Event:)
                                               object:NULL
                                              seconds:_reopenTime2
                                                 name:@"reopenTimer1"
                                              repeats:NO
                                      runInForeground:YES];

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

- (void)sctpStatusUpdate:(UMSocketStatus)s
{
    self.sctp_status = s;
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
        _linkTestTime = MTP3_LINK_TEST_TIMER_DEFAULT;
    }

    if(cfg[@"link-test-ack-time"])
    {
        _linkTestAckTime  = (NSTimeInterval)[cfg[@"link-test-ack-time"] doubleValue];
    }
    else
    {
        _linkTestAckTime = MTP3_LINK_TEST_ACK_TIMER_DEFAULT;
    }

    if(cfg[@"link-test-max-outstanding"])
    {
        _linkTestMaxOutStanding  = (NSTimeInterval)[cfg[@"link-test-max-outstanding"] intValue];
    }
    else
    {
        _linkTestMaxOutStanding = 3;
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


    if (cfg[@"reopen-timer1"])
    {
        _reopenTime1 = [cfg[@"reopen-timer1"] doubleValue];
    }
    else
    {
        _reopenTime1 = MTP3_LINK_REOPEN_TIME1_DEFAULT;
    }
    _reopenTimer1.seconds = _reopenTime1;

    if (cfg[@"reopen-timer2"])
    {
        _reopenTime2 = [cfg[@"reopen-timer2"] doubleValue];
    }
    else
    {
        _reopenTime2 = MTP3_LINK_REOPEN_TIME2_DEFAULT;
    }
    _reopenTimer2.seconds = _reopenTime2;


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


- (void)forcedPowerOn
{
    _forcedOutOfService = NO;
    [_m2pa powerOnFor:_linkset.mtp3 forced:YES];
}

- (void)forcedPowerOff
{
    _forcedOutOfService = YES;
    [_m2pa powerOffFor:_linkset.mtp3 forced:YES];
}

- (void)powerOn
{
    if(_forcedOutOfService==NO)
    {
        [_m2pa powerOnFor:_linkset.mtp3 forced:NO];
    }
}
- (void)powerOff
{
    [_m2pa powerOffFor:_linkset.mtp3 forced:NO];
}

- (BOOL)emergency
{
    return _m2pa.emergency;
}

- (void)setEmergency:(BOOL)emergency
{
    _m2pa.emergency = emergency;
    if(emergency)
    {
        [_m2pa  emergencyFor:_linkset.mtp3];
    }
    else
    {
        [_m2pa  emergencyCheasesFor:_linkset.mtp3];
    }
}


- (BOOL)forcedOutOfService
{
    return _forcedOutOfService;
}

- (void)setForcedOutOfService:(BOOL)foos
{
    _forcedOutOfService = foos;
    if(foos==YES)
    {
        [_m2pa powerOffFor:_linkset.mtp3];
    }
    else
    {
        [_m2pa powerOnFor:_linkset.mtp3];
    }
}

- (void)start
{
    if(!_forcedOutOfService)
    {
        [_m2pa startFor:_linkset.mtp3];
    }
    
}

- (void)stop
{
    [_m2pa stopFor:_linkset.mtp3 forced:_forcedOutOfService];
}

- (void)linkTestTimerEvent:(id)parameter
{
    [_linkset linktestTimeEventForLink:self];
}

- (void)linkTestAckTimerEvent:(id)parameter
{
    [_linkTestAckTimer stop];
    if(_outstandingSLTA < 2)
    {
        [_linkset linktestTimeEventForLink:self];
    }
    else
    {
        /* we already have */
        /* restarting of link */
        _linkRestartsDueToFailedLinktest++;
        _linkRestartTime = [NSDate date];
        [_m2pa linktestTimerReportsFailure];
    }
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
                                                       name:@"linktestTimer"
                                                    repeats:YES
                                            runInForeground:YES];
        }
        [_linkTestTimer start];
    }
}

- (void)stopLinkTestTimer
{
    [_linkTestTimer stop];
}


- (void)startLinkTestAckTimer
{
    if(_linkTestAckTime > 0)
    {
        if(_linkTestAckTimer==NULL)
        {
            _linkTestAckTimer = [[UMTimer alloc]initWithTarget:self
                                                   	  selector:@selector(linkTestAckTimerEvent:)
                                                        object:NULL
                                                       seconds:_linkTestAckTime
                                                          name:@"linktestAckTimer"
                                                       repeats:NO
                                               runInForeground:YES];
        }
        [_linkTestAckTimer start];
    }
}

- (void)stopLinkTestAckTimer
{
    [_linkTestAckTimer stop];
}

- (void)startReopenTimer1
{
    if(_reopenTime1 > 0)
    {
        if(_reopenTimer1==NULL)
        {
            _reopenTimer1 = [[UMTimer alloc]initWithTarget:self
                                                 selector:@selector(reopenTimer1Event:)
                                                   object:NULL
                                                  seconds:_reopenTime1
                                                     name:@"reopenTimer1"
                                                  repeats:NO
                                          runInForeground:YES];
        }
        [_reopenTimer1 startIfNotRunning];
    }
}

- (void)startReopenTimer2
{
    if(_reopenTime2 > 0)
    {
        if(_reopenTimer2==NULL)
        {
            _reopenTimer2 = [[UMTimer alloc]initWithTarget:self
                                                 selector:@selector(reopenTimer2Event:)
                                                   object:NULL
                                                  seconds:_reopenTime2
                                                     name:@"reopenTimer2"
                                                  repeats:NO
                                          runInForeground:YES];
        }
        [_reopenTimer2 startIfNotRunning];
    }
}

- (void)stopReopenTimer1
{
    [_reopenTimer1 stop];
}

- (void)stopReopenTimer2
{
    [_reopenTimer2 stop];
}


- (void)reopenTimer1Event:(id)parameter
{
    [_linkset reopenTimer1EventFor:self];
}

- (void)reopenTimer2Event:(id)parameter
{
    [_linkset reopenTimer2EventFor:self];
}



- (void)stopDetachAndDestroy
{
    /* FIXME: do something here */
}
@end

