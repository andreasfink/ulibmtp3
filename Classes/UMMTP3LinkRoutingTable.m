//
//  UMMTP3LinkRoutingTable.m
//  ulibmtp3
//
//  Created by Andreas Fink on 26.01.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMMTP3LinkRoutingTable.h"
#import "UMMTP3PointCode.h"
#import "UMMTP3LinkSet.h"
#import "UMMTP3Route.h"
#import "UMMTP3RouteMetrics.h"
#import "UMMTP3RoutePriority.h"


@implementation UMMTP3LinkRoutingTable


-(UMMTP3RoutingTable *)init
{
    self = [super init];
    if(self)
    {
        routesByPointCode = [[UMSynchronizedSortedDictionary alloc]init];
    }
    return self;
}

- (UMMTP3Route *)findRouteForDestination:(UMMTP3PointCode *)pc
                                    mask:(int)mask
                             linksetName:(NSString *)linksetName
                                   exact:(BOOL)exact
{
    /* this route searches for routes matching exact (orBigger==NO) or super routes */
    /* mask for a pointcode specific is 14 or 24 (ITU vs ANSI */
    /* if orBigger=YES then it would look for x-xxx-x/14 and then for x-xxx-y/13 etc... */
    /* the mask integer indicates how many bits are in the node part (so its value is 0 for a /14, 1 for /13 etc) */

    int startmask = mask;
    int endmask;
    if(exact==YES)
    {
        endmask = startmask;
    }
    else
    {
        endmask = [pc maxmask];
    }
    for(int m=startmask; m <= endmask; m++)
    {
        NSString *key = [pc maskedPointcodeString:m];
        UMMTP3Route *r = routesByPointCode[key];
        if(r)
        {
            if(linksetName)
            {
                if([linksetName isEqualToString:r.linksetName])
                {
                    return r;
                }
            }
            else
            {
                return r;
            }
        }
    }
    return NULL;
}

- (UMMTP3Route *)findRouteForDestination:(UMMTP3PointCode *)pc
                                    mask:(int)mask
                      excludeLinkSetName:(NSString *)linksetName
                                   exact:(BOOL)exact
{
    int startmask = mask;
    int endmask;
    if(exact==YES)
    {
        endmask = startmask;
    }
    else
    {
        endmask = [pc maxmask];
    }
    for(int m=startmask; m <= endmask; m++)
    {
        NSString *key = [pc maskedPointcodeString:m];
        UMMTP3Route *r = routesByPointCode[key];
        if(r)
        {
            if(linksetName)
            {
                if(![linksetName isEqualToString:r.linksetName])
                {
                    return r;
                }
            }
            else
            {
                return r;
            }
        }
    }
    return NULL;
}

- (NSArray *)findRoutesForDestination:(UMMTP3PointCode *)pc
                                 mask:(int)mask
                          linksetName:(NSString *)linksetName
                                exact:(BOOL)exact
{
    UMMTP3Route *r = [self findRouteForDestination:pc
                                              mask:mask
                                       linksetName:linksetName
                                             exact:exact];
    return @[r];
}

- (NSArray *)findRoutesForDestination:(UMMTP3PointCode *)pc
                                 mask:(int)mask
                   excludeLinkSetName:(NSString *)linksetName
                                exact:(BOOL)exact
{
    UMMTP3Route *r = [self findRouteForDestination:pc
                                              mask:mask
                                excludeLinkSetName:linksetName
                                             exact:exact];
    return @[r];
}


- (void)updateRouteAvailable:(UMMTP3PointCode *)pc mask:(int)mask linksetName:(NSString *)linksetName
{
    UMMTP3Route *r = [self findRouteForDestination:pc mask:mask linksetName:linksetName exact:YES];
    if(r)
    {
        r.status = UMMTP3_ROUTE_ALLOWED;
    }
    else
    {
        r = [[UMMTP3Route alloc]initWithPc:pc
                               linksetName:linksetName
                                  priority:UMMTP3RoutePriority_undefined
                                      mask:mask];
        r.status = UMMTP3_ROUTE_ALLOWED;
        routesByPointCode[r.routingTableKey] = r;
    }
}
- (void)updateRouteRestricted:(UMMTP3PointCode *)pc mask:(int)mask linksetName:(NSString *)linksetName
{
    UMMTP3Route *r = [self findRouteForDestination:pc mask:mask linksetName:linksetName exact:YES];
    if(r)
    {
        r.status = UMMTP3_ROUTE_RESTRICTED;
    }
    else
    {

        r = [[UMMTP3Route alloc]initWithPc:pc
                               linksetName:linksetName
                                  priority:UMMTP3RoutePriority_undefined
                                      mask:mask];
        r.status = UMMTP3_ROUTE_RESTRICTED;
        r.mask = mask;
    }
}

- (UMMTP3RouteStatus)isRouteAvailable:(UMMTP3PointCode *)pc mask:(int)mask linksetName:(NSString *)linksetName
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

- (void)updateRouteUnavailable:(UMMTP3PointCode *)pc mask:(int)mask linksetName:(NSString *)linksetName
{
    if(logLevel <=UMLOG_DEBUG)
    {
        NSString *s = [NSString stringWithFormat:@"updateRouteUnavailable:%@/%d",pc.stringValue,(pc.maxmask-mask)];
        [logFeed debugText:s];
    }

    UMMTP3Route *r = [self findRouteForDestination:pc mask:mask linksetName:linksetName exact:YES];
    if(r)
    {
        r.status = UMMTP3_ROUTE_PROHIBITED;
    }
    else
    {
        r = [[UMMTP3Route alloc]initWithPc:pc
                               linksetName:linksetName
                                  priority:UMMTP3RoutePriority_undefined
                                      mask:mask];
        r.status = UMMTP3_ROUTE_PROHIBITED;
        routesByPointCode[r.routingTableKey] = r;
    }
}


- (UMSynchronizedDictionary *)objectValue
{
    UMSynchronizedSortedDictionary *d = [[UMSynchronizedSortedDictionary alloc]init];
    NSArray *keys = [routesByPointCode allKeys];
    for (id key in keys)
    {
        UMMTP3Route *r = routesByPointCode[key];
        d[key] = [r objectValue];
    }
    return d;
}

- (NSString *)jsonString
{
    return [routesByPointCode jsonString];
}


@end
