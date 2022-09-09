//
//  UMLayerMTP3.m
//  ulibmtp3
//
//  Created by Andreas Fink on 04/12/14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import "UMLayerMTP3.h"
#import "UMMTP3LinkSet.h"
#import "UMMTP3Link.h"
#import "UMMTP3PointCode.h"

#import "UMMTP3Task_m2paStatusIndication.h"
#import "UMMTP3Task_m2paSctpStatusIndication.h"
#import "UMMTP3Task_m2paDataIndication.h"
#import "UMMTP3Task_m2paCongestion.h"
#import "UMMTP3Task_m2paCongestionCleared.h"
#import "UMMTP3Task_m2paProcessorOutage.h"
#import "UMMTP3Task_m2paProcessorRestored.h"
#import "UMMTP3Task_m2paSpeedLimitReached.h"
#import "UMMTP3Task_m2paSpeedLimitReachedCleared.h"
#import "UMMTP3Task_adminAttachOrder.h"
#import "UMMTP3Task_adminCreateLinkSet.h"
#import "UMMTP3Task_adminCreateLink.h"
#import "UMMTP3Label.h"
#import "UMMTP3HeadingCode.h"
#import "UMMTP3InstanceRoute.h"
#import "UMM3UAApplicationServer.h"
#import "UMMTP3Task_start.h"
#import "UMMTP3Task_stop.h"
#import "UMLayerMTP3UserProtocol.h"
#import "UMMTP3InstanceRoutingTable.h"
#import "UMM3UAApplicationServerProcess.h"
#import "UMMTP3SyslogClient.h"
#import "UMMTP3StatisticDb.h"

@implementation UMLayerMTP3

#pragma mark -
#pragma mark Initializer

- (UMLayerMTP3 *)initWithTaskQueueMulti:(UMTaskQueueMulti *)tq name:(NSString *)name
{
    NSString *s = [NSString stringWithFormat:@"mtp3/%@",name];
    self = [super initWithTaskQueueMulti:tq name:s];
    if(self)
    {
        [self genericInitialisation];
    }
    return self;
}

- (void)genericInitialisation
{
	_linksets        = [[UMSynchronizedSortedDictionary alloc]init];
	_links	         = [[UMSynchronizedSortedDictionary alloc]init];
    _userPart        = [[UMSynchronizedSortedDictionary  alloc]init];
    _routingTable    = [[UMMTP3InstanceRoutingTable alloc]init];
    _housekeepingTimer = [[UMTimer alloc]initWithTarget:self
                                               selector:@selector(housekeeping)
                                                 object:NULL
                                                seconds:6
                                                   name:@"housekeeping"
                                                repeats:YES
                                        runInForeground:YES];
    _routeRetestTime = MTP3_ROUTE_RETEST_TIMER_DEFAULT;
    _routeRetestTimer = [[UMTimer alloc]initWithTarget:self
                                         selector:@selector(routeRetestTimerEvent)
                                           object:NULL
                                          seconds:_routeRetestTime
                                             name:@"routeRetestTimer"
                                          repeats:YES
                                  runInForeground:NO];
    _mtp3Lock = [[UMMutex alloc]initWithName:@"mtp3-lock"];
}

-(NSString *)layerType
{
    return @"sctp";
}

#pragma mark -
#pragma mark LinkSet Handling

- (void)refreshRoutingTable
{
    /* FIXME: do we still need this? or maybe we should check status of linkset AVAIL/UNAVAIL here and send updateLinksetAvailable: etc to routing table */
}

- (void)addLinkSet:(UMMTP3LinkSet *)ls
{
    ls.mtp3 = self;
    ls.variant = self.variant;
    ls.logFeed = [self.logFeed copy];
    ls.logFeed.subsection = @"mtp3_linkset";
    ls.logFeed.name = ls.name;
    ls.logLevel = self.logLevel;
    if(ls.localPointCode == NULL)
    {
        ls.localPointCode = self.opc;
    }
    _linksets[ls.name]=ls;
    [self refreshRoutingTable];
}

- (void)addLink:(UMMTP3Link *)lnk
{
	_links[lnk.name]=lnk;
}

- (void)removeLink:(UMMTP3Link *)lnk
{
	[_links removeObjectForKey:lnk.name];
}

- (void)removeAllLinkSets
{
    self.linksets = [[UMSynchronizedSortedDictionary alloc]init];
}


- (void)removeLinkSet:(UMMTP3LinkSet *)ls
{
    ls.mtp3 = NULL;
    [_linksets removeObjectForKey:ls.name];
}

- (void)removeLinkSetByName:(NSString *)n
{
    UMMTP3LinkSet *ls = _linksets[n];
    [self removeLinkSet:ls];
}

- (UMMTP3LinkSet *)getLinkSetByName:(NSString *)n
{
    UMMTP3LinkSet *ls = _linksets[n];
    return ls;
}

- (UMMTP3LinkSet *)getLinkByName:(NSString *)n
{
	return _links[n];
}

- (UMMTP3PointCode *)adjacentPointCodeOfLinkSet:(NSString *)asname
{
    UMMTP3LinkSet *ls = [self getLinkSetByName:asname];
    return ls.adjacentPointCode;
}

#pragma mark -
#pragma mark M2PA callbacks

- (void) adminCreateLinkSet:(NSString *)linkset
{
    @autoreleasepool
    {
        UMMTP3Task_adminCreateLinkSet *task = [[UMMTP3Task_adminCreateLinkSet alloc ]initWithReceiver:self
                                                                                           sender:(id)NULL
                                                                                          linkset:linkset];
        [self queueFromAdmin:task];
    }
}

- (void) adminCreateLink:(NSString *)linkset
                     slc:(int)slc
                    link:(NSString *)link
{
    @autoreleasepool
    {
        UMMTP3Task_adminCreateLink *task = [[UMMTP3Task_adminCreateLink alloc ]initWithReceiver:self
                                                                                           sender:(id)NULL
                                                                                              slc:(int)slc
                                                                                          linkset:linkset
                                                                                             link:link];
        [self queueFromAdmin:task];
    }
}

- (void)adminAttachOrder:(UMLayerM2PA *)m2pa_layer
					 slc:(int)slc
			 linkSetName:(NSString *)linkSetName
				linkName:(NSString *)linkName
{
    @autoreleasepool
    {
        UMMTP3Task_adminAttachOrder *task = [[UMMTP3Task_adminAttachOrder alloc ]initWithReceiver:self
                                                                                           sender:(id)NULL
                                                                                              slc:(int)slc
                                                                                             m2pa:m2pa_layer
                                                                                      linkSetName:linkSetName
                                                                                         linkName:linkName];
        [self queueFromAdmin:task];
    }
}

- (void) adminAttachConfirm:(UMLayer *)attachedLayer
                        slc:(int)slc
                     userId:(id)uid
{
    UMMTP3LinkSet *linkSet = _linksets[uid];
    [linkSet attachmentConfirmed:slc];
}


- (void) adminAttachFail:(UMLayer *)attachedLayer
                     slc:(int)slc
                  userId:(id)uid
                  reason:(NSString *)r
{
    UMMTP3LinkSet *linkSet = _linksets[uid];
    [linkSet attachmentFailed:slc reason:r];
}

- (void) sentAckConfirmFrom:(UMLayer *)sender
                   userInfo:(NSDictionary *)userInfo
{
    NSLog(@"sentAckConfirmFrom Not yet implemented");
}

- (void) sentAckFailureFrom:(UMLayer *)sender
                   userInfo:(NSDictionary *)userInfo
                      error:(NSString *)err
                     reason:(NSString *)reason
                  errorInfo:(NSDictionary *)ei
{
    NSLog(@"sentAckFailureFrom Not yet implemented");
}


- (void) m2paStatusIndication:(UMLayer *)caller
                          slc:(int)xslc
                       userId:(id)uid
                       status:(M2PA_Status)s
{
    return [self m2paStatusIndication:caller
                                  slc:xslc
                               userId:uid
                               status:s
                                async:YES];
}

- (void) m2paStatusIndication:(UMLayer *)caller
                          slc:(int)xslc
                       userId:(id)uid
                       status:(M2PA_Status)s
                        async:(BOOL)async
{
    @autoreleasepool
    {
        UMMTP3Task_m2paStatusIndication *task = [[UMMTP3Task_m2paStatusIndication alloc]initWithReceiver:self
                                                                                                  sender:caller
                                                                                                     slc:xslc
                                                                                                  userId:uid
                                                                                                  status:s];
        if(async)
        {
           [self queueFromLowerWithPriority:task];
        }
        else
        {
            [task main];
        }
    }
}


- (void) m2paSctpStatusIndication:(UMLayer *)caller
                              slc:(int)xslc
                           userId:(id)uid
                           status:(UMSocketStatus)s
{
    @autoreleasepool
    {
        UMMTP3Task_m2paSctpStatusIndication *task = [[UMMTP3Task_m2paSctpStatusIndication alloc]initWithReceiver:self
                                                                                                          sender:caller
                                                                                                             slc:xslc
                                                                                                          userId:uid
                                                                                                          status:s];
        [self queueFromLowerWithPriority:task];
    }
}

- (void) m2paDataIndication:(UMLayer *)caller
                        slc:(int)xslc
			   mtp3linkName:(NSString *)linkName
                       data:(NSData *)d
{
    @autoreleasepool
    {
        UMMTP3Task_m2paDataIndication *task = [[UMMTP3Task_m2paDataIndication alloc]initWithReceiver:self
                                                                                              sender:caller
                                                                                                 slc:xslc
                                                                                        mtp3linkName:linkName
                                                                                                data:d];
        [task main];
//        [self queueFromLower:task];
    }
}


- (void) m2paCongestion:(UMLayer *)caller
                    slc:(int)xslc
                 userId:(id)uid
{
    @autoreleasepool
    {
        UMMTP3Task_m2paCongestion *task = [[UMMTP3Task_m2paCongestion alloc]initWithReceiver:self
                                                                                      sender:caller
                                                                                         slc:xslc
                                                                                      userId:uid];
        [self queueFromLowerWithPriority:task];
    }
}

- (void) m2paCongestionCleared:(UMLayer *)caller
                           slc:(int)xslc
                        userId:(id)uid
{
    @autoreleasepool
    {
        UMMTP3Task_m2paCongestionCleared *task = [[UMMTP3Task_m2paCongestionCleared alloc]initWithReceiver:self
                                                                                      sender:caller
                                                                                         slc:xslc
                                                                                      userId:uid];
        [self queueFromLowerWithPriority:task];
    }
}

- (void) m2paProcessorOutage:(UMLayer *)caller
                         slc:(int)xslc
                      userId:(id)uid
{
    @autoreleasepool
    {
        UMMTP3Task_m2paProcessorOutage *task = [[UMMTP3Task_m2paProcessorOutage alloc]initWithReceiver:self
                                                                                                     sender:caller
                                                                                                        slc:xslc
                                                                                                     userId:uid];
        [self queueFromLowerWithPriority:task];
    }
}


- (void) m2paProcessorRestored:(UMLayer *)caller
                           slc:(int)xslc
                        userId:(id)uid
{
    @autoreleasepool
    {
        UMMTP3Task_m2paProcessorRestored *task = [[UMMTP3Task_m2paProcessorRestored alloc]initWithReceiver:self
                                                                                                sender:caller
                                                                                                   slc:xslc
                                                                                                userId:uid];
        [self queueFromLowerWithPriority:task];
    }
}


- (void) m2paSpeedLimitReached:(UMLayer *)caller
                           slc:(int)xslc
                        userId:(id)uid
{
    @autoreleasepool
    {
        UMMTP3Task_m2paSpeedLimitReached *task = [[UMMTP3Task_m2paSpeedLimitReached alloc]initWithReceiver:self
                                                                                                sender:caller
                                                                                                   slc:xslc
                                                                                                userId:uid];
        [self queueFromLowerWithPriority:task];
    }
}

- (void) m2paSpeedLimitReachedCleared:(UMLayer *)caller
                                  slc:(int)xslc
                               userId:(id)uid

{
    @autoreleasepool
    {
        UMMTP3Task_m2paSpeedLimitReachedCleared *task = [[UMMTP3Task_m2paSpeedLimitReachedCleared alloc]initWithReceiver:self
                                                                                                    sender:caller
                                                                                                       slc:xslc
                                                                                                    userId:uid];
        [self queueFromLowerWithPriority:task];
    }
}

#pragma mark -
#pragma mark Tasks

- (void) _adminCreateLinkSetTask:(UMMTP3Task_adminCreateLinkSet *)task
{
    @autoreleasepool
    {
        if(self.logLevel <= UMLOG_DEBUG)
        {
            [self logDebug:@"_adminCreateLinkSetTask"];
        }
        
        UMMTP3LinkSet *ls = [[UMMTP3LinkSet alloc] init];
        ls.name = [task linkset];
        _linksets[ls.name] = ls;
    }
}

- (void) _adminCreateLinkTask:(UMMTP3Task_adminCreateLink *)task
{
    @autoreleasepool
    {
        if(self.logLevel <= UMLOG_DEBUG)
        {
            [self logDebug:@"_adminCreateLinkTask"];
        }
        
        NSString *linksetName = task.linkset;
        UMMTP3Link *link =[[UMMTP3Link alloc] init];
        link.slc = task.slc;
        link.name = task.link;
        UMMTP3LinkSet *linkset = _linksets[linksetName];
        [linkset addLink:link];
    }
}


- (void)_adminAttachOrderTask:(UMMTP3Task_adminAttachOrder *)task
{
    @autoreleasepool
    {
        if(self.logLevel <= UMLOG_DEBUG)
        {
            [self logDebug:@"adminAttachOrder"];
        }
        UMLayerM2PA *m2pa = task.m2pa;
        UMLayerM2PAUserProfile *profile = [[UMLayerM2PAUserProfile alloc]initWithDefaultProfile];
        profile.allMessages = YES;
        profile.sctpLinkstateMessages = YES;
        profile.m2paLinkstateMessages = YES;
        profile.dataMessages = YES;
        profile.processorOutageMessages = YES;

        [m2pa adminAttachFor:self
                     profile:profile
                    linkName:task.linkName
                         slc:task.slc];
    }
}

- (void) _m2paStatusIndicationTask:(UMMTP3Task_m2paStatusIndication *)task;
{
    @autoreleasepool
    {
        if(self.logLevel <=UMLOG_DEBUG)
        {
            [self logDebug:@"_m2paStatusIndicationTask"];
            [self logDebug:[NSString stringWithFormat:@" slc: %d",task.slc]];
            [self logDebug:[NSString stringWithFormat:@" userId: %@",task.userId]];
            [self logDebug:[NSString stringWithFormat:@" status: %@ (%d)", [UMLayerM2PA m2paStatusString:task.status], task.status]];
        }
        
        UMMTP3Link *link = [self getLinkByName: task.userId];
        UMMTP3LinkSet *linkset = link.linkset;
        [linkset m2paStatusUpdate:task.status slc:task.slc];
    }
}


- (void) _m2paRemoteProcessorOutage:(UMMTP3Task_m2paStatusIndication *)task;
{
    @autoreleasepool
    {
        if(self.logLevel <=UMLOG_DEBUG)
        {
            [self logDebug:@"_m2paStatusIndicationTask"];
            [self logDebug:[NSString stringWithFormat:@" slc: %d",task.slc]];
            [self logDebug:[NSString stringWithFormat:@" userId: %@",task.userId]];
            [self logDebug:[NSString stringWithFormat:@" status: %@ (%d)", [UMLayerM2PA m2paStatusString:task.status], task.status]];
        }

        UMMTP3Link *link = [self getLinkByName: task.userId];
        UMMTP3LinkSet *linkset = link.linkset;
        [linkset m2paStatusUpdate:task.status slc:task.slc];
    }
}


- (void) _m2paSctpStatusIndicationTask:(UMMTP3Task_m2paSctpStatusIndication *)task;
{
    @autoreleasepool
    {
        if(self.logLevel <=UMLOG_DEBUG)
        {
            [self logDebug:@"_m2paSctpStatusIndicationTask"];
            [self logDebug:[NSString stringWithFormat:@" slc: %d",task.slc]];
            [self logDebug:[NSString stringWithFormat:@" userId: %@",task.userId]];
            switch(task.status)
            {
                    
                case UMSOCKET_STATUS_FOOS:
                    [self logDebug:[NSString stringWithFormat:@" status: M_FOOS (%d)",task.status]];
                    break;
                case UMSOCKET_STATUS_OFF:
                    [self logDebug:[NSString stringWithFormat:@" status: OFF (%d)",task.status]];
                    break;
                case UMSOCKET_STATUS_OOS:
                    [self logDebug:[NSString stringWithFormat:@" status: OOS (%d)",task.status]];
                    break;
                case UMSOCKET_STATUS_IS:
                    [self logDebug:[NSString stringWithFormat:@" status: IS (%d)",task.status]];
                    break;
                default:
                    [self logDebug:[NSString stringWithFormat:@" status: UNKNOWN(%d)",task.status]];
                    break;
            }
        }
        UMMTP3LinkSet *linkset = [self getLinkSetByName:task.userId];
        [linkset sctpStatusUpdate:task.status slc:task.slc];
    }
}


- (void) _m2paDataIndicationTask:(UMMTP3Task_m2paDataIndication *)task
{
    @autoreleasepool
    {
        if(self.logLevel <=UMLOG_DEBUG)
        {
            [self logDebug:@"_m2paDataIndicationTask"];
            [self logDebug:[NSString stringWithFormat:@" slc: %d",task.slc]];
            [self logDebug:[NSString stringWithFormat:@" data: %@",task.data.description]];
        }
        /* userid contains UMMTP3Link */

        UMMTP3Link *link = [self getLinkByName:task.m3linkName];
        UMMTP3LinkSet *linkset = link.linkset;
        if(linkset==NULL)
        {
            [self logMajorError:[NSString stringWithFormat:@"linkset '%@' not found for slc %d",task.m3linkName,task.slc]];
        }
        else
        {
            [linkset dataIndication:task.data slc:task.slc];
        }
    }
}

- (void) _m2paCongestionTask:(UMMTP3Task_m2paCongestion*)task
{
    @autoreleasepool
    {
        if(self.logLevel <=UMLOG_DEBUG)
        {
            [self logDebug:@"_m2paCongestionTask"];
            [self logDebug:[NSString stringWithFormat:@" slc: %d",task.slc]];
            [self logDebug:[NSString stringWithFormat:@" userId: %@",task.userId]];
        }
        UMMTP3Link *link = [self getLinkByName:task.userId];
        UMMTP3LinkSet *linkset = link.linkset;
        [self updateRouteRestricted:linkset.adjacentPointCode
                               mask:linkset.adjacentPointCode.maxmask
                        linksetName:linkset.name
                           priority:UMMTP3RoutePriority_5
                             reason:@"congestion"];
        [link congestionIndication];
    }
}


- (void) _m2paCongestionClearedTask:(UMMTP3Task_m2paCongestionCleared *)task
{
    @autoreleasepool
    {
        if(self.logLevel <=UMLOG_DEBUG)
        {
            [self logDebug:@"_m2paCongestionClearedTask"];
            [self logDebug:[NSString stringWithFormat:@" slc: %d",task.slc]];
            [self logDebug:[NSString stringWithFormat:@" userId: %@",task.userId]];
        }
        UMMTP3Link *link = [self getLinkByName:task.userId];
        UMMTP3LinkSet *linkset = link.linkset;
        [self updateRouteAvailable:linkset.adjacentPointCode
                              mask:linkset.adjacentPointCode.maxmask
                       linksetName:linkset.name
                          priority:UMMTP3RoutePriority_1
                            reason:@"congestion-cleared"];
        [link congestionClearedIndication];
    }
}


- (void) _m2paProcessorOutageTask:(UMMTP3Task_m2paProcessorOutage *)task
{
    @autoreleasepool
    {
        if(self.logLevel <=UMLOG_DEBUG)
        {
            [self logDebug:@"_m2paProcessorOutageTask"];
            [self logDebug:[NSString stringWithFormat:@" slc: %d",task.slc]];
            [self logDebug:[NSString stringWithFormat:@" userId: %@",task.userId]];
        }
        UMMTP3Link *link = [self getLinkByName:task.userId];
        UMMTP3LinkSet *linkset = link.linkset;
        [self updateRouteUnavailable:linkset.adjacentPointCode
                                mask:linkset.adjacentPointCode.maxmask
                         linksetName:linkset.name
                            priority:UMMTP3RoutePriority_1
                              reason:@"processor-outage"];

        [link processorOutageIndication];
    }
}

- (void) _m2paProcessorRestoredTask:(UMMTP3Task_m2paProcessorRestored *)task
{
    @autoreleasepool
    {
        if(self.logLevel <=UMLOG_DEBUG)
        {
            [self logDebug:@"_m2paProcessorRestoredTask"];
            [self logDebug:[NSString stringWithFormat:@" slc: %d",task.slc]];
            [self logDebug:[NSString stringWithFormat:@" userId: %@",task.userId]];
        }
        UMMTP3Link *link = [self getLinkByName:task.userId];
        UMMTP3LinkSet *linkset = link.linkset;
        [self updateRouteAvailable:linkset.adjacentPointCode
                              mask:linkset.adjacentPointCode.maxmask
                       linksetName:linkset.name
                          priority:UMMTP3RoutePriority_1
                            reason:@"processor-restored"];
        [link processorRestoredIndication];
    }
}


- (void) _m2paSpeedLimitReachedTask:(UMMTP3Task_m2paSpeedLimitReached *)task
{
    @autoreleasepool
    {
        if(self.logLevel <=UMLOG_DEBUG)
        {
            [self logDebug:@"_m2paSpeedLimitReachedTask"];
            [self logDebug:[NSString stringWithFormat:@" slc: %d",task.slc]];
            [self logDebug:[NSString stringWithFormat:@" userId: %@",task.userId]];
        }
        UMMTP3Link *link = [self getLinkByName:task.userId];
        UMMTP3LinkSet *linkset = link.linkset;
        [self updateRouteRestricted:linkset.adjacentPointCode
                               mask:linkset.adjacentPointCode.maxmask
                        linksetName:linkset.name
                           priority:UMMTP3RoutePriority_1
                             reason:@"speed-limit-reached"];
        /* inform upper layers */
        [link speedLimitReachedIndication];
    }
}
- (void) _m2paSpeedLimitReachedClearedTask:(UMMTP3Task_m2paSpeedLimitReachedCleared *)task
{
    @autoreleasepool
    {
        if(self.logLevel <=UMLOG_DEBUG)
        {
            [self logDebug:@"_m2paSpeedLimitReachedClearedTask"];
            [self logDebug:[NSString stringWithFormat:@" slc: %d",task.slc]];
            [self logDebug:[NSString stringWithFormat:@" userId: %@",task.userId]];
        }
        UMMTP3Link *link = [self getLinkByName:task.userId];
        UMMTP3LinkSet *linkset = link.linkset;
        [self updateRouteAvailable:linkset.adjacentPointCode
                              mask:linkset.adjacentPointCode.maxmask
                       linksetName:linkset.name
                          priority:UMMTP3RoutePriority_1
                            reason:@"speed-limit-cleared"];
        [link speedLimitReachedClearedIndication];
    }
}

- (void) m3uaCongestion:(UMM3UAApplicationServer *)as
      affectedPointCode:(UMMTP3PointCode *)pc
                   mask:(uint32_t)mask
      networkAppearance:(uint32_t)network_appearance
     concernedPointcode:(UMMTP3PointCode *)concernedPc
    congestionIndicator:(uint32_t)congestionIndicator
{
    @autoreleasepool
    {
        if(self.logLevel <=UMLOG_DEBUG)
        {
            [self logDebug:@"m3uaCongestion"];
        }
        [self updateRouteRestricted:as.adjacentPointCode
                               mask:mask
                        linksetName:as.name
                           priority:UMMTP3RoutePriority_1
                             reason:@"m3ua-congestion"];
        as.congestionLevel = 1;
    }
}

- (void) m3uaCongestionCleared:(UMM3UAApplicationServer *)as
      affectedPointCode:(UMMTP3PointCode *)pc
                   mask:(uint32_t)mask
      networkAppearance:(uint32_t)network_appearance
     concernedPointcode:(UMMTP3PointCode *)concernedPc
    congestionIndicator:(uint32_t)congestionIndicator
{
    @autoreleasepool
    {
        if(self.logLevel <=UMLOG_DEBUG)
        {
            [self logDebug:@"m3uaCongestionCleared"];
        }
        [self updateRouteAvailable:as.adjacentPointCode
                              mask:mask
                       linksetName:as.name
                          priority:UMMTP3RoutePriority_1
                            reason:@"m3ua-congestion-cleared"];
        as.congestionLevel = 0;
    }
}

#pragma mark -
#pragma mark Config Management

- (NSDictionary *)config
{
    @autoreleasepool
    {
        NSMutableDictionary *config = [[NSMutableDictionary alloc]init];
        [self addLayerConfig:config];
        switch(_variant)
        {
            case UMMTP3Variant_ITU:
                config[@"variant"]=@"itu";
                break;
            case UMMTP3Variant_ANSI:
                config[@"variant"]=@"ansi";
                break;
            case UMMTP3Variant_China:
                config[@"variant"]=@"china";
                break;
            default:
                break;
        }
        config[@"opc"] = [_opc stringValue];
        config[@"ni"] = @(_networkIndicator);
        NSMutableDictionary *linksetsConfig = [[NSMutableDictionary alloc]init];
        NSArray *linksetNames = [_linksets allKeys];
        for(NSString *linksetName in linksetNames)
        {
            UMMTP3LinkSet *linkset = _linksets[linksetName];
            linksetsConfig[linksetName] = [linkset config];
        }
        config[@"linksets"] = linksetsConfig;
        return config;
    }
}

- (void)setConfig:(NSDictionary *)cfg applicationContext:(id<UMLayerMTP3ApplicationContextProtocol>)appContext
{
    @autoreleasepool
    {

        [self readLayerConfig:cfg];

        _appContext = appContext;
        _stpMode = YES;
        if(cfg[@"mode"])
        {
            NSString *v = [cfg[@"mode"] stringValue];
            if([v isEqualToString:@"stp"])
            {
                _stpMode = YES;
            }
            else if([v isEqualToString:@"ssp"])
            {
                _stpMode = NO;
            }
        }

        NSString *var = cfg[@"variant"];
        if([var isEqualToString:@"itu"])
        {
            _variant = UMMTP3Variant_ITU;
        }
        else if([var isEqualToString:@"ansi"])
        {
            _variant = UMMTP3Variant_ANSI;
            _networkIndicator = 2;
        }
        else if([var isEqualToString:@"china"])
        {
            _variant = UMMTP3Variant_China;
        }
        else /* defaults to ITU */
        {
            _variant = UMMTP3Variant_ITU;
        }
        

        NSString *pcStr = cfg[@"opc"];
        self.opc = [[UMMTP3PointCode alloc]initWithString:pcStr variant:_variant];
        switch(_variant)
        {
            case UMMTP3Variant_ANSI:
                _ansiOpc = _opc;
                break;
            case UMMTP3Variant_Japan:
                _japanOpc = _opc;
                break;
            case UMMTP3Variant_ITU:
                _ituOpc = _opc;
                break;
            case UMMTP3Variant_China:
                _chinaOpc = _opc;
                break;
            default:
                break;
        }
        pcStr = cfg[@"ansi-opc"];
        if(pcStr)
        {
            _ansiOpc = [[UMMTP3PointCode alloc]initWithString:pcStr variant:UMMTP3Variant_ANSI];
        }
        pcStr = cfg[@"japan-opc"];
        if(pcStr)
        {
            _japanOpc = [[UMMTP3PointCode alloc]initWithString:pcStr variant:UMMTP3Variant_Japan];
        }
        pcStr = cfg[@"japan-opc"];
        if(pcStr)
        {
            _japanOpc = [[UMMTP3PointCode alloc]initWithString:pcStr variant:UMMTP3Variant_Japan];
        }
        pcStr = cfg[@"china-opc"];
        if(pcStr)
        {
            _chinaOpc = [[UMMTP3PointCode alloc]initWithString:pcStr variant:UMMTP3Variant_Japan];
        }


        NSDictionary *linksetsConfig = cfg[@"linksets"];
        NSString *s = [cfg[@"ni"]stringValue];

        if((  [s isEqualToStringCaseInsensitive:@"international"])
           || ([s isEqualToStringCaseInsensitive:@"int"])
           || ([s isEqualToStringCaseInsensitive:@"0"]))
        {
            _networkIndicator = 0;
        }
        else if(([s isEqualToStringCaseInsensitive:@"national"])
                || ([s isEqualToStringCaseInsensitive:@"nat"])
                || ([s isEqualToStringCaseInsensitive:@"2"]))
        {
            _networkIndicator = 2;
        }
        else if(([s isEqualToStringCaseInsensitive:@"spare"])
                || ([s isEqualToStringCaseInsensitive:@"international-spare"])
                || ([s isEqualToStringCaseInsensitive:@"int-spare"])
                || ([s isEqualToStringCaseInsensitive:@"1"]))
        {
            _networkIndicator = 1;
        }
        else if(([s isEqualToStringCaseInsensitive:@"reserved"])
                || ([s isEqualToStringCaseInsensitive:@"national-reserved"])
                || ([s isEqualToStringCaseInsensitive:@"nat-reserved"])
                || ([s isEqualToStringCaseInsensitive:@"3"]))
        {
            _networkIndicator = 3;
        }
        else
        {
            if(_variant == UMMTP3Variant_ANSI)
            {
                [self logMajorError:[NSString stringWithFormat:@"Unknown MTP3 network-indicator '%@' defaulting to national (ansi)",s]];
                _networkIndicator = 2;
            }
            else
            {
                [self logMajorError:[NSString stringWithFormat:@"Unknown MTP3 network-indicator '%@' defaulting to international",s]];
                _networkIndicator = 0;
            }
        }

        [self removeAllLinkSets];
        for(NSString *linksetName in linksetsConfig)
        {
            NSDictionary *linksetConfig = linksetsConfig[linksetName];
            
            UMMTP3LinkSet  *linkset = [[UMMTP3LinkSet alloc]init];
            linkset.name = linksetName;
            linkset.variant = self.variant;
            [linkset setConfig:linksetConfig applicationContext:appContext];
            [self addLinkSet:linkset];
        }

        if(cfg[@"statistic-db-instance"])
        {
            _statisticDbInstance       = [cfg[@"statistic-db-instance"] stringValue];
        }
        if(cfg[@"statistic-db-pool"])
        {
            _statisticDbPool        = [cfg[@"statistic-db-pool"] stringValue];
        }
        if(cfg[@"statistic-db-table"])
        {
            _statisticDbTable       = [cfg[@"statistic-db-table"] stringValue];
        }
        if(cfg[@"statistic-db-autocreate"])
        {
            _statisticDbAutoCreate  = @([cfg[@"statistic-db-autocreate"] boolValue]);
        }
        else
        {
            _statisticDbAutoCreate=@(YES);
        }
        if(cfg[@"routing-update-log"])
        {
            _routingUpdateLogFileName = [cfg[@"routing-update-log"] stringValue];
            _routingUpdateLogFile = fopen(_routingUpdateLogFileName.UTF8String,"w+");
            if(_routingUpdateLogFile)
            {
                NSString *s = [[NSDate date]stringValue];
                fprintf(_routingUpdateLogFile,"--ROUTING-UPDATE-LOG-FILE started %s--\n",s.UTF8String);
                fflush(_routingUpdateLogFile);
            }
        }
    }
}

- (UMMTP3InstanceRoute *)findRouteForDestination:(UMMTP3PointCode *)search_dpc
{
    UMMTP3InstanceRoute *re = [_routingTable findRouteForDestination:search_dpc
                                                                mask:search_dpc.maxmask
                                                  excludeLinkSetName:NULL
                                                               exact:NO];
    return re;
}


- (UMMTP3_Error)sendPDU:(NSData *)pdu
                    opc:(UMMTP3PointCode *)fopc
                    dpc:(UMMTP3PointCode *)fdpc
                     si:(int)si
                     mp:(int)mp
                options:(NSDictionary *)options
{
    return [self sendPDU:pdu
                     opc:fopc
                     dpc:fdpc
                      si:si
                      mp:mp
                 options:options
         routedToLinkset:NULL
                     sls:-1];
}

- (UMMTP3_Error)sendPDU:(NSData *)pdu
                    opc:(UMMTP3PointCode *)fopc
                    dpc:(UMMTP3PointCode *)fdpc
                     si:(int)si
                     mp:(int)mp
                options:(NSDictionary *)options
        routedToLinkset:(NSString **)routedToLinkset
                    sls:(int)sls
{
    NSString *rtl;
    UMMTP3_Error err;
    @autoreleasepool
    {
        if(fopc==NULL)
        {
            fopc = _opc;
        }
        UMMTP3InstanceRoute *route = [self findRouteForDestination:fdpc];
        err= [self forwardPDU:pdu
                          opc:fopc
                          dpc:fdpc
                           si:si
                           mp:mp
                        route:route
                      options:options
                sourceLinkset:@"local"
              routedToLinkset:&rtl
                          sls:sls];
    }
    if(routedToLinkset != NULL)
    {
        *routedToLinkset = rtl;
    }
    return err;
}

- (UMMTP3_Error)forwardPDU:(NSData *)pdu
                       opc:(UMMTP3PointCode *)fopc
                       dpc:(UMMTP3PointCode *)fdpc
                        si:(int)si
                        mp:(int)mp
                     route:(UMMTP3InstanceRoute *)route
                   options:(NSDictionary *)options
             sourceLinkset:(NSString *)sourceLinkset
           routedToLinkset:(NSString **)routedToLinkset
                       sls:(int)sls
{
    NSString *rtls = NULL;
    UMMTP3_Error err = UMMTP3_error_internal_error;

    @autoreleasepool
    {
        if(self.logLevel <= UMLOG_DEBUG)
        {
            [self.logFeed debugText:[NSString stringWithFormat:@"routed to route '%@'",route.name]];
            [self.logFeed debugText:[NSString stringWithFormat:@" linkset '%@'",route.linksetName]];
            [self.logFeed debugText:[NSString stringWithFormat:@" pointcode '%@'",route.pointcode]];
        }
        if(route==NULL)
        {
            [self.logFeed majorErrorText:@"no route to destination (route==null)"];
            err =  UMMTP3_error_no_route_to_destination;
        }
        else
        {
            NSString *linksetName = route.linksetName;
            rtls = linksetName;
            UMMTP3LinkSet *linkset = _linksets[linksetName];
            if(linkset==NULL)
            {
                [self.logFeed majorErrorText:[NSString stringWithFormat:@"linkset named '%@' not found",linksetName]];
                rtls = @"no-route-to-destination";
                err = UMMTP3_error_no_route_to_destination;
            }
            else
            {
                UMMTP3Label *label = [[UMMTP3Label alloc]init];
                label.opc = fopc;
                label.dpc = fdpc;
                if(sls != -1)
                {
                    NSString *s = options[@"mtp3-sls"];
                    if(s.length > 0)
                    {
                        label.sls = [s intValue] % 16;
                    }
                    else
                    {
                        label.sls = [UMUtil random:16];
                    }
                }
                else
                {
                    label.sls = sls;
                }
                int ni;
                if(linkset.overrideNetworkIndicator)
                {
                    ni = [linkset.overrideNetworkIndicator intValue];
                }
                else
                {
                    ni = _networkIndicator;
                }
                if([linkset isKindOfClass:[UMM3UAApplicationServer class]])
                {
                    if(self.logLevel <= UMLOG_DEBUG)
                    {
                        [self.logFeed debugText:[NSString stringWithFormat:@"sending PDU to application server %@",linkset.name]];
                        [self.logFeed debugText:[NSString stringWithFormat:@" label: %@",label]];
                        [self.logFeed debugText:[NSString stringWithFormat:@" ni: %d",ni]];
                        [self.logFeed debugText:[NSString stringWithFormat:@" sls: %d",sls]];
                        [self.logFeed debugText:[NSString stringWithFormat:@" mp: %d",mp]];
                        [self.logFeed debugText:[NSString stringWithFormat:@" pdu: %@",pdu]];
                    }
                    [linkset sendPdu:pdu
                               label:label
                             heading:-1
                                  ni:ni
                                  mp:mp
                                  si:si
                          ackRequest:NULL
                       correlationId:0
                             options:options];
                    [_statisticDb addByteCount:(int)pdu.length
                               incomingLinkset:sourceLinkset
                               outgoingLinkset:linkset.name
                                           opc:label.opc.pc
                                           dpc:label.dpc.pc
                                            si:si];
                }
                else
                {
                    if(self.logLevel <= UMLOG_DEBUG)
                    {
                        [self.logFeed debugText:[NSString stringWithFormat:@"sending PDU to m2pa linkset %@",linkset.name]];
                        [self.logFeed debugText:[NSString stringWithFormat:@" label: %@",label]];
                        [self.logFeed debugText:[NSString stringWithFormat:@" ni: %d",ni]];
                        [self.logFeed debugText:[NSString stringWithFormat:@" sls: %d",sls]];
                        [self.logFeed debugText:[NSString stringWithFormat:@" mp: %d",mp]];
                        [self.logFeed debugText:[NSString stringWithFormat:@" pdu: %@",pdu]];
                    }
                    [linkset sendPdu:pdu
                               label:label
                             heading:-1
                                  ni:ni
                                  mp:mp
                                  si:si
                          ackRequest:NULL
                       correlationId:0
                             options:options];
                    [_statisticDb addByteCount:(int)pdu.length
                               incomingLinkset:sourceLinkset
                               outgoingLinkset:linkset.name
                                           opc:label.opc.pc
                                           dpc:label.dpc.pc
                                            si:si];
                }
                err = UMMTP3_no_error;
            }
        }
    }
    if(routedToLinkset)
    {
        *routedToLinkset = rtls;
    }
    return err;
}

- (void)start
{
    
    @autoreleasepool
    {
        if(_statisticDbPool && _statisticDbTable)
        {
            if(_statisticDbInstance==NULL)
            {
                _statisticDbInstance = _layerName;
            }
            _statisticDb = [[UMMTP3StatisticDb alloc]initWithPoolName:_statisticDbPool
                                                            tableName:_statisticDbTable
                                                           appContext:_appContext
                                                           autocreate:_statisticDbAutoCreate.boolValue
                                                             instance:_statisticDbInstance];
            if(_statisticDbAutoCreate.boolValue)
            {
                [_statisticDb doAutocreate];
            }
            [_housekeepingTimer start];
        }
        UMMTP3Task_start *task = [[UMMTP3Task_start alloc]initWithReceiver:self];
        [self queueFromAdmin:task];
    }
}

- (void)stop
{
    @autoreleasepool
    {
        UMMTP3Task_stop *task = [[UMMTP3Task_stop alloc]initWithReceiver:self];
        [self queueFromAdmin:task];
    }
}

- (void)_start
{
    @autoreleasepool
    {
        NSArray *linksetNamesArray = [_linksets allKeys];
        for(NSString *linksetName in linksetNamesArray)
        {
            UMMTP3LinkSet *ls = _linksets[linksetName];
            [ls reloadPlugins];
            [ls reloadPluginConfigs];
            [ls reopenLogfiles];
            [ls openMtp3ScreeningTraceFile];
            [ls openSccpScreeningTraceFile];
            [ls powerOn];
        }
        _isStarted = YES;
    }
}

- (void)_stop
{
    @autoreleasepool
    {
        NSArray *linksetNames = [_linksets allKeys];
        for(NSString *linksetName in linksetNames)
        {
            UMMTP3LinkSet *ls = _linksets[linksetName];
            [ls powerOff];
        }
        _isStarted = NO;
    }
}

- (id<UMLayerMTP3UserProtocol>)findUserPart:(int)upid
{
    return _userPart[@(upid)];
}

- (void)setUserPart:(int)upid user:(id<UMLayerMTP3UserProtocol>)user
{
    _userPart[@(upid)] = user;
}



- (void)processIncomingPdu:(UMMTP3Label *)label
                      data:(NSData *)data
                userpartId:(int)si
                        ni:(int)ni
                       sls:(int)sls
                        mp:(int)mp
               linksetName:(NSString *)linksetName
                   linkset:(UMMTP3LinkSet *)linkset
{
    @autoreleasepool
    {
        [linkset.speedometerRx increase];
        [linkset.speedometerRxBytes increaseBy:(uint32_t)data.length];

        if([label.dpc isEqualToPointCode:_opc])
        {
            [self processIncomingPduLocal:label
                                     data:data
                               userpartId:si
                                       ni:ni
                                      sls:sls
                                       mp:mp
                              linksetName:linksetName
                                  linkset:linkset];
            [_statisticDb addByteCount:(int)data.length
                       incomingLinkset:linksetName
                       outgoingLinkset:@"local"
                                   opc:label.opc.pc
                                   dpc:label.dpc.pc
                                    si:si];
            [linkset.prometheusMetrics.localRxCount increaseBy:1];
        }
        else
        {
            if(_stpMode ==YES)
            {
                [self processIncomingPduForward:label
                                           data:data
                                     userpartId:si
                                             ni:ni
                                            sls:sls
                                             mp:mp
                                    linksetName:linksetName
                                        linkset:linkset];
                [linkset.prometheusMetrics.forwardRxCount increaseBy:1];
            }
            else
            {
                NSString *s =[NSString stringWithFormat:@"DPC is not local and we are not in STP mode. %@->%@ %@",label.opc, label.dpc, [data hexString]];
                [self logMinorError:s];
            }
        }
    }
}

- (void)processIncomingPduForward:(UMMTP3Label *)label
                                data:(NSData *)data
                          userpartId:(int)si
                                  ni:(int)ni
                                 sls:(int)sls
                                  mp:(int)mp
                         linksetName:(NSString *)linksetName
                            linkset:(UMMTP3LinkSet *)linkset
{
    @autoreleasepool
    {
        NSMutableDictionary *options = [[NSMutableDictionary alloc]init];
        options[@"mtp3-incoming-linkset"] = linksetName;

        UMMTP3InstanceRoute *route = [_routingTable findRouteForDestination:label.dpc
                                                                       mask:label.dpc.maxmask
                                                         excludeLinkSetName:linksetName
                                                                      exact:NO]; /* we never send back to the link the PDU came from to avoid loops */
        if(route)
        {
            [self forwardPDU:data
                         opc:label.opc
                         dpc:label.dpc
                          si:si
                          mp:mp
                       route:route
                     options:options
               sourceLinkset:linksetName
             routedToLinkset:NULL
                         sls:sls];
        }
        else
        {
            /* no route found */
            NSString *s = [NSString stringWithFormat:@"DroppingPDU from LinkSet: %@ OPC:%@ DPC:%@ no route found. Sending TFP",linksetName,label.opc.stringValue, label.dpc.stringValue];
            [self logMinorError:s];

            UMMTP3LinkSet * linkset = [self getLinkSetByName:linksetName];
            UMMTP3Label *errorLabel = [[UMMTP3Label alloc]init];
            errorLabel.opc = _opc;
            errorLabel.dpc = linkset.adjacentPointCode;
            [linkset sendTFP:errorLabel destination:label.dpc ni:ni mp:mp slc:-1 link:NULL];
            [_statisticDb addByteCount:(int)data.length
                       incomingLinkset:linksetName
                       outgoingLinkset:@"no-route-to-destination"
                                   opc:label.opc.pc
                                   dpc:label.dpc.pc
                                    si:si];
            return;
        }
    }
}


- (void)processIncomingPduLocal:(UMMTP3Label *)label
                                data:(NSData *)data
                          userpartId:(int)si
                                  ni:(int)ni
                                 sls:(int)sls
                                  mp:(int)mp
                         linksetName:(NSString *)linksetName
                             linkset:(UMMTP3LinkSet *)linkset

{
    @autoreleasepool
    {

        switch(si)
        {
            case MTP3_SERVICE_INDICATOR_MGMT:
            case MTP3_SERVICE_INDICATOR_MAINTENANCE_SPECIAL_MESSAGE:
            case MTP3_SERVICE_INDICATOR_TEST:
                @throw([NSException exceptionWithName:@"CODE_ERROR" reason:@"we never expect this here" userInfo:NULL]);
                break;
            case MTP3_SERVICE_INDICATOR_SCCP:
            {
                if(self.logLevel <= UMLOG_DEBUG)
                {
                    [self.logFeed debugText:[NSString stringWithFormat:@"  Service Indicator: [%d] SCCP",si]];
                }
                [self processUserPart:label data:data userpartId:si ni:ni sls:sls mp:mp linksetName:linksetName linkset:linkset ];
            }
                break;
            case MTP3_SERVICE_INDICATOR_TUP:
            {
                if(self.logLevel <= UMLOG_DEBUG)
                {
                    [self.logFeed debugText:[NSString stringWithFormat:@"  Service Indicator: [%d] SPARE_TUP",si]];
                }
                [self processUserPart:label data:data userpartId:si ni:ni sls:sls mp:mp linksetName:linksetName linkset:linkset];

            }
                break;
            case MTP3_SERVICE_INDICATOR_ISUP:
            {
                if(self.logLevel <= UMLOG_DEBUG)
                {
                    [self.logFeed debugText:[NSString stringWithFormat:@"  Service Indicator: [%d] SPARE_ISUP",si]];
                }
                [self processUserPart:label data:data userpartId:si ni:ni sls:sls mp:mp linksetName:linksetName linkset:linkset];

            }
                break;
            case MTP3_SERVICE_INDICATOR_DUP_C:
            {
                if(self.logLevel <= UMLOG_DEBUG)
                {
                    [self.logFeed debugText:[NSString stringWithFormat:@"  Service Indicator: [%d] SPARE_DUP_C",si]];
                }
                [self processUserPart:label data:data userpartId:si ni:ni sls:sls mp:mp linksetName:linksetName linkset:linkset];

            }
                break;
            case MTP3_SERVICE_INDICATOR_DUP_F:
            {
                if(self.logLevel <= UMLOG_DEBUG)
                {
                    [self.logFeed debugText:[NSString stringWithFormat:@"  Service Indicator: [%d] SPARE_DUP_F",si]];
                }
                [self processUserPart:label data:data userpartId:si ni:ni sls:sls mp:mp linksetName:linksetName linkset:linkset];

            }
                break;
            case MTP3_SERVICE_INDICATOR_RES_TESTING:
            {
                if(self.logLevel <= UMLOG_DEBUG)
                {
                    [self.logFeed debugText:[NSString stringWithFormat:@"  Service Indicator: [%d] SPARE_RES_TESTING",si]];
                }
                [self processUserPart:label data:data userpartId:si ni:ni sls:sls mp:mp linksetName:linksetName linkset:linkset];

            }
                break;
            case MTP3_SERVICE_INDICATOR_BROADBAND_ISUP:
            {
                if(self.logLevel <= UMLOG_DEBUG)
                {
                    [self.logFeed debugText:[NSString stringWithFormat:@"  Service Indicator: [%d] SPARE_ISUP",si]];
                }
                [self processUserPart:label data:data userpartId:si ni:ni sls:sls mp:mp linksetName:linksetName linkset:linkset];

            }
                break;
            case MTP3_SERVICE_INDICATOR_SAT_ISUP:
            {
                if(self.logLevel <= UMLOG_DEBUG)
                {
                    [self.logFeed debugText:[NSString stringWithFormat:@"  Service Indicator: [%d] SPARE_SAT_ISUP",si]];
                }
                [self processUserPart:label data:data userpartId:si ni:ni sls:sls mp:mp linksetName:linksetName linkset:linkset];

            }
                break;
            case MTP3_SERVICE_INDICATOR_SPARE_B:
            {
                if(self.logLevel <= UMLOG_DEBUG)
                {
                    [self.logFeed debugText:[NSString stringWithFormat:@"  Service Indicator: [%d] SPARE_B",si]];
                }
                [self processUserPart:label data:data userpartId:si ni:ni sls:sls mp:mp linksetName:linksetName linkset:linkset];

            }
                break;
            case MTP3_SERVICE_INDICATOR_SPARE_C:
            {
                if(self.logLevel <= UMLOG_DEBUG)
                {
                    [self.logFeed debugText:[NSString stringWithFormat:@"  Service Indicator: [%d] SPARE_C",si]];
                }
                [self processUserPart:label data:data userpartId:si ni:ni sls:sls mp:mp linksetName:linksetName linkset:linkset];

            }
                break;
            case MTP3_SERVICE_INDICATOR_SPARE_D:
            {
                if(self.logLevel <= UMLOG_DEBUG)
                {
                    [self.logFeed debugText:[NSString stringWithFormat:@"  Service Indicator: [%d] SPARE_D",si]];
                }
                [self processUserPart:label data:data userpartId:si ni:ni sls:sls mp:mp linksetName:linksetName linkset:linkset];

            }
                break;
            case MTP3_SERVICE_INDICATOR_SPARE_E:
            {
                if(self.logLevel <= UMLOG_DEBUG)
                {
                    [self.logFeed debugText:[NSString stringWithFormat:@"  Service Indicator: [%d] SPARE_E",si]];
                }
                [self processUserPart:label data:data userpartId:si ni:ni sls:sls mp:mp linksetName:linksetName linkset:linkset];

            }
                break;
            case MTP3_SERVICE_INDICATOR_SPARE_F:
            {
                if(self.logLevel <= UMLOG_DEBUG)
                {
                    [self.logFeed debugText:[NSString stringWithFormat:@"  Service Indicator: [%d] SPARE_F",si]];
                }
                [self processUserPart:label data:data userpartId:si ni:ni sls:sls mp:mp linksetName:linksetName linkset:linkset];

            }
                break;
        }
    }
}

- (void)processUserPart:(UMMTP3Label *)label
                   data:(NSData *)data
             userpartId:(int)si
                     ni:(int)ni
                    sls:(int)sls
                     mp:(int)mp
            linksetName:(NSString *)linksetName
                linkset:(UMMTP3LinkSet *)linkset
{
    @autoreleasepool
    {
        NSMutableDictionary *options;
        NSDate *ts = [NSDate new];
        options[@"mtp3-timestamp"] = ts;

        if((linkset.ttmap_in==NULL) && (linkset.ttmap_in_name.length > 0))
        {
            linkset.ttmap_in = [_appContext getTTMap:linkset.ttmap_in_name];
        }
        id<UMLayerMTP3UserProtocol> inst = [self findUserPart:si];
        if(inst)
        {

            [inst mtpTransfer:data
                 callingLayer:self
                          opc:label.opc
                          dpc:label.dpc
                           si:si
                           ni:ni
                          sls:sls
                  linksetName:linksetName
                      options:options
                        ttmap:linkset.ttmap_in];
        }
        else if(_problematicPacketDumper)
        {
            [_problematicPacketDumper logPacket:data
                                            opc:label.opc
                                            dpc:label.dpc
                                            sls:0
                                             ni:ni
                                             si:si];
        }
        /* FIXME: reply something if not reachable? */
    }
}


- (int)maxPduSize
{
    return 273;
}


- (BOOL)updateRouteAvailable:(UMMTP3PointCode *)pc
                        mask:(int)mask
                 linksetName:(NSString *)name
                    priority:(UMMTP3RoutePriority)prio /* returns true if status changed */
                      reason:(NSString *)reason
{
    @autoreleasepool
    {
        if(_routingUpdateLogFile)
        {
            NSDate *now = [NSDate date];
            NSString *s = [NSString stringWithFormat:@"%@ LINKSET: %@ PC: %@ STATUS: AVAILABLE PRIO: %d REASON=%@", now.stringValue,name,pc,prio,reason];
            UMMUTEX_LOCK(_mtp3Lock);
            fprintf(_routingUpdateLogFile,"%s\n",s.UTF8String);
            fflush(_routingUpdateLogFile);
            UMMUTEX_UNLOCK(_mtp3Lock);
        }
        UMMTP3RouteStatus old_status = [_routingTable statusOfRoute:pc];
        [_routingTable updateDynamicRouteAvailable:pc mask:mask linksetName:name priority:prio];
        UMMTP3RouteStatus new_status = [_routingTable statusOfRoute:pc];
        if(old_status!=new_status)
        {
            [self updateOtherLinksetsForPointCode:pc excludeLinkSetName:name];
            [self updateUpperLevelPointCode:pc];
            if(_routingUpdateLogFile)
            {
                [self writeRouteStatusToLog:pc];
            }
        }
        return YES;
    }
}

- (BOOL)updateRouteRestricted:(UMMTP3PointCode *)pc
                         mask:(int)mask
                  linksetName:(NSString *)name
                     priority:(UMMTP3RoutePriority)prio
                       reason:(NSString *)reason
{
    @autoreleasepool
    {
        if(_routingUpdateLogFile)
        {
            NSDate *now = [NSDate date];
            NSString *s = [NSString stringWithFormat:@"%@ LINKSET: %@ PC: %@ STATUS: AVAILABLE RESTRICTED: %d REASON=%@", now.stringValue,name,pc,prio,reason];

            UMMUTEX_LOCK(_mtp3Lock);
            fprintf(_routingUpdateLogFile,"%s\n",s.UTF8String);
            fflush(_routingUpdateLogFile);
            UMMUTEX_UNLOCK(_mtp3Lock);
        }
        UMMTP3RouteStatus old_status = [_routingTable statusOfRoute:pc];
        [_routingTable updateDynamicRouteRestricted:pc mask:mask linksetName:name priority:prio];
        UMMTP3RouteStatus new_status = [_routingTable statusOfRoute:pc];
        if(old_status!=new_status)
        {
            [self updateOtherLinksetsForPointCode:pc excludeLinkSetName:name];
            [self updateUpperLevelPointCode:pc];
            if(_routingUpdateLogFile)
            {
                [self writeRouteStatusToLog:pc];
            }
        }
        return YES;
    }
}

- (void)writeRouteStatusEventToLog:(NSString *)event
{
    if(_routingUpdateLogFile==NULL)
    {
        return;
    }
    NSDate *now = [NSDate date];
    NSString *s = [NSString stringWithFormat:@"%@ INFO: %@", now.stringValue,event];
    UMMUTEX_LOCK(_mtp3Lock);
    fprintf(_routingUpdateLogFile,"%s\n",s.UTF8String);
    fflush(_routingUpdateLogFile);
    UMMUTEX_UNLOCK(_mtp3Lock);
}

- (void)writeRouteStatusToLog:(UMMTP3PointCode *)pc
{
    if(_routingUpdateLogFile==NULL)
    {
        return;
    }
    UMMTP3InstanceRoute *ir = [_routingTable findRouteForDestination:pc mask:-1 excludeLinkSetName:NULL exact:YES];
    NSString *status = @"undefined";
    switch(ir.status)
    {
        case UMMTP3_ROUTE_UNUSED:
            status = @"UNUSED";
            break;
        case UMMTP3_ROUTE_UNKNOWN:
            status = @"UNKNOWN";
            break;
        case UMMTP3_ROUTE_PROHIBITED:
            status = @"PROHIBITED";
            break;
        case UMMTP3_ROUTE_RESTRICTED:
            status = @"RESTRICTED";
            break;
        case UMMTP3_ROUTE_ALLOWED:
            status = @"ALLOWED ";
            break;
    }
    NSDate *now = [NSDate date];
    NSString *s = [NSString stringWithFormat:@"%@ PC: %@ STATUS: %@", now.stringValue,pc.stringValue,status];
    UMMUTEX_LOCK(_mtp3Lock);
    fprintf(_routingUpdateLogFile,"%s\n",s.UTF8String);
    fflush(_routingUpdateLogFile);
    UMMUTEX_UNLOCK(_mtp3Lock);
}


- (BOOL)updateRouteUnavailable:(UMMTP3PointCode *)pc
                          mask:(int)mask
                   linksetName:(NSString *)name
                      priority:(UMMTP3RoutePriority)prio
                        reason:(NSString *)reason
{
    @autoreleasepool
    {

        if(_routingUpdateLogFile)
        {
            NSDate *now = [NSDate date];
            NSString *s = [NSString stringWithFormat:@"%@ LINKSET: %@ PC: %@ STATUS: UNAVAILABLE PRIO: %d REASON:%@", now.stringValue,name,pc,prio,reason];
            UMMUTEX_LOCK(_mtp3Lock);
            fprintf(_routingUpdateLogFile,"%s\n",s.UTF8String);
            fflush(_routingUpdateLogFile);
            UMMUTEX_UNLOCK(_mtp3Lock);
        }
        UMMTP3RouteStatus old_status = [_routingTable statusOfRoute:pc];
       [_routingTable updateDynamicRouteUnavailable:pc
                                               mask:mask
                                        linksetName:name
                                           priority:prio];
        UMMTP3RouteStatus new_status = [_routingTable statusOfRoute:pc];

        if(old_status!=new_status)
        {
            [self updateOtherLinksetsForPointCode:pc excludeLinkSetName:name];
            [self updateUpperLevelPointCode:pc];
            if(_routingUpdateLogFile)
            {
                [self writeRouteStatusToLog:pc];
            }
        }
        return YES;
    }
}

- (void)updateOtherLinksetsForPointCode:(UMMTP3PointCode *)pc
                     excludeLinkSetName:(NSString *)name
{
    
    UMMTP3RouteStatus status = [_routingTable statusOfRoute:pc];
    if(status == UMMTP3_ROUTE_PROHIBITED)
    {
        [self updateOtherLinksetsPointCodeUnavailable:pc excludeLinkSetName:name];
    }
    else if(status == UMMTP3_ROUTE_RESTRICTED)
    {
        [self updateOtherLinksetsPointCodeRestricted:pc excludeLinkSetName:name];
    }
    else if(status == UMMTP3_ROUTE_ALLOWED)
    {
        [self updateOtherLinksetsPointCodeAvailable:pc excludeLinkSetName:name];
    }
    else if(status == UMMTP3_ROUTE_UNKNOWN)
    {
        [self updateOtherLinksetsPointCodeAvailable:pc excludeLinkSetName:name];
    }
}

- (void)updateUpperLevelPointCode:(UMMTP3PointCode *)pc
{
    UMMTP3RouteStatus status = [_routingTable statusOfRoute:pc];
    if(status == UMMTP3_ROUTE_PROHIBITED)
    {
        [self updateUpperLevelPointCodeUnavailable:pc];
    }
    else if(status == UMMTP3_ROUTE_RESTRICTED)
    {
        [self updateUpperLevelPointCodeRestricted:pc];

    }
    else if(status == UMMTP3_ROUTE_ALLOWED)
    {
        [self updateUpperLevelPointCodeAvailable:pc];
    }
    else if(status == UMMTP3_ROUTE_UNKNOWN)
    {
        [self updateUpperLevelPointCodeAvailable:pc];
    }
}

- (UMMTP3RouteStatus)getRouteStatus:(UMMTP3PointCode *)pc
{
    int mask = 0;
    UMMTP3InstanceRoute *ir = [_routingTable findRouteForDestination:pc mask:mask excludeLinkSetName:NULL exact:YES];
    return ir.status;
}

- (void)updateUpperLevelPointCodeUnavailable:(UMMTP3PointCode *)pc
{
    if(_routingUpdateLogFile)
    {
        NSDate *now = [NSDate date];
        NSString *s = [NSString stringWithFormat:@"%@ MTP-USER UNAVAILABLE PC %@ (%d)", now.stringValue,pc.stringValue,(int)pc.pc];
        UMMUTEX_LOCK(_mtp3Lock);
        fprintf(_routingUpdateLogFile,"%s\n",s.UTF8String);
        fflush(_routingUpdateLogFile);
        UMMUTEX_UNLOCK(_mtp3Lock);
    }
    NSArray *userKeys = [_userPart allKeys];
    for(NSNumber *userKey in userKeys)
    {
        id<UMLayerMTP3UserProtocol> u = _userPart[userKey];
        [u mtpPause:NULL
       callingLayer:self
         affectedPc:pc
                 si:(int)[userKey integerValue]
                 ni:_networkIndicator
                sls:-1
            options:@{}];
    }
}

- (void)updateUpperLevelPointCodeRestricted:(UMMTP3PointCode *)pc
{
    if(_routingUpdateLogFile)
    {
        NSDate *now = [NSDate date];
        NSString *s = [NSString stringWithFormat:@"%@ MTP-USER RESTRICTED PC %@ (%d)", now.stringValue,pc.stringValue,pc.pc];
        UMMUTEX_LOCK(_mtp3Lock);
        fprintf(_routingUpdateLogFile,"%s\n",s.UTF8String);
        fflush(_routingUpdateLogFile);
        UMMUTEX_UNLOCK(_mtp3Lock);
    }
    NSArray *userKeys = [_userPart allKeys];
    for(NSNumber *userKey in userKeys)
    {
        id<UMLayerMTP3UserProtocol> u = _userPart[userKey];
        [u mtpStatus:NULL
       callingLayer:self
         affectedPc:pc
                 si:(int)[userKey integerValue]
                 ni:_networkIndicator
                 sls:-1
             status:1 /* FIXME: we could use congestion levels here but its national specific */
            options:@{}];
    }
}

- (void)updateUpperLevelPointCodeAvailable:(UMMTP3PointCode *)pc
{
    if(_routingUpdateLogFile)
    {
        NSDate *now = [NSDate date];
        NSString *s = [NSString stringWithFormat:@"%@ MTP-USER AVAIL PC %@", now.stringValue,pc.stringValue];
        UMMUTEX_LOCK(_mtp3Lock);
        fprintf(_routingUpdateLogFile,"%s\n",s.UTF8String);
        fflush(_routingUpdateLogFile);
        UMMUTEX_UNLOCK(_mtp3Lock);
    }
    NSArray *userKeys = [_userPart allKeys];
    for(NSNumber *userKey in userKeys)
    {
        id<UMLayerMTP3UserProtocol> u = _userPart[userKey];
        [u mtpResume:NULL
       callingLayer:self
         affectedPc:pc
                 si:(int)[userKey integerValue]
                 ni:_networkIndicator
                 sls:-1
            options:@{}];
    }
}


- (void)updateOtherLinksetsPointCodeUnavailable:(UMMTP3PointCode *)pc
                             excludeLinkSetName:(NSString *)name
{
    NSArray *linksetNames = [_linksets allKeys];
    for(NSString *linksetName in linksetNames)
    {
        if([linksetName isEqualToString:name])
        {
            continue;
        }
        UMMTP3LinkSet *linkset = _linksets[linksetName];
        [linkset advertizePointcodeUnavailable:pc mask:pc.maxmask];
        if(_routingUpdateLogFile)
        {
            NSDate *now = [NSDate date];
            NSString *s = [NSString stringWithFormat:@"%@ ADVERTIZE PC %@ UNAVAIL to linkset %@", now.stringValue,pc.stringValue,linksetName];
            UMMUTEX_LOCK(_mtp3Lock);
            fprintf(_routingUpdateLogFile,"%s\n",s.UTF8String);
            fflush(_routingUpdateLogFile);
            UMMUTEX_UNLOCK(_mtp3Lock);
        }
    }
}

- (void)updateOtherLinksetsPointCodeRestricted:(UMMTP3PointCode *)pc
                            excludeLinkSetName:(NSString *)name
{
    NSArray *linksetNames = [_linksets allKeys];
    for(NSString *linksetName in linksetNames)
    {
        if([linksetName isEqualToString:name])
        {
            continue;
        }
        UMMTP3LinkSet *linkset = _linksets[linksetName];
        if(_routingUpdateLogFile)
        {
            NSDate *now = [NSDate date];
            NSString *s = [NSString stringWithFormat:@"%@ ADVERTIZE PC %@ RESTRICTED to linkset %@", now.stringValue,pc.stringValue,linksetName];
            UMMUTEX_LOCK(_mtp3Lock);
            fprintf(_routingUpdateLogFile,"%s\n",s.UTF8String);
            fflush(_routingUpdateLogFile);
            UMMUTEX_UNLOCK(_mtp3Lock);
        }
        [linkset advertizePointcodeRestricted:pc mask:pc.maxmask];
    }
}

- (void)updateOtherLinksetsPointCodeAvailable:(UMMTP3PointCode *)pc
                           excludeLinkSetName:(NSString *)name
{
    NSArray *linksetNames = [_linksets allKeys];
    for(NSString *linksetName in linksetNames)
    {
        if([linksetName isEqualToString:name])
        {
            continue;
        }
        UMMTP3LinkSet *linkset = _linksets[linksetName];
        if(_routingUpdateLogFile)
        {
            NSDate *now = [NSDate date];
            NSString *s = [NSString stringWithFormat:@"%@ ADVERTIZE PC %@ AVAIL to linkset %@", now.stringValue,pc.stringValue,linksetName];
            UMMUTEX_LOCK(_mtp3Lock);
            fprintf(_routingUpdateLogFile,"%s\n",s.UTF8String);
            fflush(_routingUpdateLogFile);
            UMMUTEX_UNLOCK(_mtp3Lock);
        }
        [linkset advertizePointcodeAvailable:pc mask:pc.maxmask];
    }
}

- (NSDictionary *)apiStatus
{
    @autoreleasepool
    {
        NSDictionary *d = [[NSDictionary alloc]init];
        return d;
    }
}

- (UMSynchronizedSortedDictionary *)routeStatus
{
    return [_routingTable routeStatus];
}

- (void)stopDetachAndDestroy
{
    /* FIXME: do something here */
}

- (void)housekeeping
{
    [_statisticDb flush];
}


- (void)reopenLogfiles
{
    NSArray *linksetKeys = [_linksets allKeys];
    for(NSString *name in linksetKeys)
    {
        UMMTP3LinkSet *ls = _linksets[name];
        [ls reopenLogfiles];
    }
}

- (void)reloadPluginConfigs
{
    NSArray *linksetKeys = [_linksets allKeys];
    for(NSString *name in linksetKeys)
    {
        UMMTP3LinkSet *ls = _linksets[name];
        [ls reloadPluginConfigs];
    }
}

- (void)reloadPlugins
{
    NSArray *linksetKeys = [_linksets allKeys];
    for(NSString *name in linksetKeys)
    {
        UMMTP3LinkSet *ls = _linksets[name];
        [ls reloadPlugins];
    }
}

- (void)updateRoutingTableLinksetUnavailabe:(NSString *)linksetName
{
    [_routingTable updateLinksetUnavailable:linksetName];
}

- (void)updateRoutingTableLinksetAvailabe:(NSString *)linksetName
{
    [_routingTable updateLinksetAvailable:linksetName];
}

- (void) routeRetestTimerEvent
{
    NSArray<UMMTP3InstanceRoute *> *routes = [_routingTable prohibitedOrRestrictedRoutes];
    for(UMMTP3InstanceRoute *route in routes)
    {
        NSString *linksetName = route.linksetName;
        UMMTP3LinkSet *linkset = _linksets[linksetName];
        if(linkset)
        {
            /* we only test routes where we have a static route configured or
             which are directly attached (these are priority 1 routes) */
            if((route.staticRoute) || (route.priority==UMMTP3RoutePriority_1))
            {
                UMMTP3Label *label = [[UMMTP3Label alloc]init];
                label.opc = _opc;
                if(linkset.localPointCode)
                {
                    label.opc = linkset.localPointCode;
                }
                label.dpc = linkset.adjacentPointCode;
                label.sls = [UMUtil random:16];
                if((route.status == UMMTP3_ROUTE_PROHIBITED) || (route.status == UMMTP3_ROUTE_RESTRICTED))
                {
                    [linkset sendRST:label
                         destination:route.pointcode
                                  ni:_networkIndicator
                                  mp:0
                                 slc:-1
                                link:NULL];
                }
            }
        }
    }
}

@end
