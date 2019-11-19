//
//  UMMTP3RoutingTable.m
//  ulibmtp3
//
//  Created by Andreas Fink on 04/12/14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import "UMMTP3RoutingTable.h"
#import "UMMTP3PointCode.h"
#import "UMMTP3Route.h"

@implementation UMMTP3RoutingTable


- (UMMTP3Route *)findRouteForDestination:(UMMTP3PointCode *)pc
                                    mask:(int)mask
                             linksetName:(NSString *)linksetName
                                   exact:(BOOL)exact
{
    return NULL;
}

- (UMMTP3Route *)findRouteForDestination:(UMMTP3PointCode *)pc
                                    mask:(int)mask
                      excludeLinkSetName:(NSString *)linksetName
                                   exact:(BOOL)exact
{
    return NULL;
}


- (NSArray *)findRoutesForDestination:(UMMTP3PointCode *)pc
                                 mask:(int)mask
                          linksetName:(NSString *)linksetName
                                exact:(BOOL)exact
{
    return NULL;
}



- (NSArray *)findRoutesForDestination:(UMMTP3PointCode *)pc
                                 mask:(int)mask
                   excludeLinkSetName:(NSString *)linksetName
                                exact:(BOOL)exact;
{
    return NULL;
}


- (BOOL)updateRouteAvailable:(UMMTP3PointCode *)pc  /* returns true if the route has changed */
                        mask:(int)mask
                 linksetName:(NSString *)linksetName
                    priority:(UMMTP3RoutePriority)prio
{
    UMMTP3RouteStatus oldstatus = UMMTP3_ROUTE_UNUSED;
    UMMTP3Route *r = [self findRouteForDestination:pc mask:mask linksetName:linksetName exact:YES];
    if(r)
    {
        oldstatus = r.status;
        r.status = UMMTP3_ROUTE_ALLOWED;
    }
    else
    {
        oldstatus = UMMTP3_ROUTE_UNKNOWN;
        r = [[UMMTP3Route alloc]initWithPc:pc
                               linksetName:linksetName
                                  priority:prio
                                      mask:mask];
        r.status = UMMTP3_ROUTE_ALLOWED;
        routesByPointCode[r.routingTableKey] = r;
    }
    return(oldstatus != r.status);
}

- (BOOL)updateRouteRestricted:(UMMTP3PointCode *)pc
                         mask:(int)mask
                  linksetName:(NSString *)linksetName
                     priority:(UMMTP3RoutePriority)prio
{
    UMMTP3RouteStatus oldstatus = UMMTP3_ROUTE_UNUSED;
    UMMTP3Route *r = [self findRouteForDestination:pc mask:mask linksetName:linksetName exact:YES];
    if(r)
    {
        oldstatus = r.status;
        r.status = UMMTP3_ROUTE_RESTRICTED;
    }
    else
    {
        oldstatus = UMMTP3_ROUTE_UNKNOWN;
        r = [[UMMTP3Route alloc]initWithPc:pc
                               linksetName:linksetName
                                  priority:prio
                                      mask:mask];
        r.status = UMMTP3_ROUTE_RESTRICTED;
        routesByPointCode[r.routingTableKey] = r;
    }
    return(oldstatus != r.status);
}

- (BOOL)updateRouteUnavailable:(UMMTP3PointCode *)pc
                          mask:(int)mask
                   linksetName:(NSString *)linksetName
                      priority:(UMMTP3RoutePriority)prio
{
    UMMTP3RouteStatus oldstatus = UMMTP3_ROUTE_UNUSED;
    UMMTP3Route *r = [self findRouteForDestination:pc mask:mask linksetName:linksetName exact:YES];
    if(r)
    {
        oldstatus = r.status;
        r.status = UMMTP3_ROUTE_PROHIBITED;
    }
    else
    {
        oldstatus = UMMTP3_ROUTE_UNKNOWN;
        r = [[UMMTP3Route alloc]initWithPc:pc
                               linksetName:linksetName
                                  priority:prio
                                      mask:mask];
        r.status = UMMTP3_ROUTE_PROHIBITED;
        routesByPointCode[r.routingTableKey] = r;
    }
    return(oldstatus != r.status);
}

- (UMSynchronizedSortedDictionary *)objectValue
{
    return NULL;
}

- (UMMTP3RouteStatus)isRouteAvailable:(UMMTP3PointCode *)pc
                                 mask:(int)mask
                          linksetName:(NSString *)linksetName
{
    UMMTP3Route *r = [self findRouteForDestination:pc mask:mask linksetName:linksetName exact:YES];
    if(r)
    {
        return r.status;
    }
    else
    {
        return UMMTP3_ROUTE_UNKNOWN;
    }
}

@end
