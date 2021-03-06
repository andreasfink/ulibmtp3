//
//  UMMTP3InstanceRoutingTable.m
//  ulibmtp3
//
//  Created by Andreas Fink on 17.02.20.
//  Copyright © 2020 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMMTP3InstanceRoutingTable.h"
#import "UMMTP3InstanceRoute.h"
#import "UMMTP3PointCode.h"
#import "UMMTP3RouteMetrics.h"

@implementation UMMTP3InstanceRoutingTable

- (UMMTP3InstanceRoutingTable *)init
{
    self = [super init];
    if(self)
    {
        _lock = [[UMMutex alloc]initWithName: @"mtp3-instance-routing-table-lock"];
        _routesByPointCode = [[NSMutableDictionary alloc]init];
    }
    return self;
}

- (NSMutableArray<UMMTP3InstanceRoute *> *)getRouteArray:(UMMTP3PointCode *)pc
                                                    mask:(int) mask
{
    NSMutableArray<UMMTP3InstanceRoute *> *r = NULL;
    if((mask == pc.maxmask) || (mask == -1)) /* single pointcode */
    {
        r = _routesByPointCode[@(pc.pc)];
        if(r==NULL)
        {
            r = [[NSMutableArray alloc]init];
            _routesByPointCode[@(pc.pc)] = r;
        }
    }
    else
    {
        [_logFeed minorErrorText:[NSString stringWithFormat:@"Can not handle routes with masks yet pc=%@ mask=%d",pc,mask]];
        r = NULL;
    }
    return r;
}

- (UMMTP3InstanceRoute *)findRouteForDestination:(UMMTP3PointCode *)pc
                                            mask:(int)mask
                              excludeLinkSetName:(NSString *)linksetName
                                           exact:(BOOL)exact

{
    NSArray<UMMTP3InstanceRoute *> *a = [self findRoutesForDestination:pc mask:mask excludeLinkSetName:linksetName exact:exact];
    if(a.count<1)
    {
        return NULL;
    }
    else if(a.count==1)
    {
        return a[0];
    }
    a = [a sortedArrayUsingSelector:@selector(routingPreference:)];
    return a[a.count-1];
}


- (NSArray<UMMTP3InstanceRoute *> *)findRoutesForDestination:(UMMTP3PointCode *)pc
                                                        mask:(int)mask
                                          excludeLinkSetName:(NSString *)linksetName
                                                       exact:(BOOL)exact
{
    [_lock lock];
    NSMutableArray<UMMTP3InstanceRoute *> *r = [[self getRouteArray:pc mask:mask] mutableCopy];
    if(linksetName.length > 0)
    {
        NSInteger n = r.count;
        for(NSInteger i=0;i<n;i++)
        {
            UMMTP3InstanceRoute *route = r[i];
            if([route.linksetName isEqualToString:linksetName])
            {
                [r removeObjectAtIndex:i--];
                n--;
            }
        }
    }
    [_lock unlock];
    return r;
}

- (NSArray<UMMTP3InstanceRoute *> *)findRoutesForDestination:(UMMTP3PointCode *)pc
                                                       mask:(int)mask
                                            onlyLinksetName:(NSString *)linksetName
{
    [_lock lock];
    NSMutableArray<UMMTP3InstanceRoute *> *r = [[self getRouteArray:pc mask:mask] mutableCopy];
    if(linksetName.length > 0)
    {
        NSInteger n = r.count;
        for(NSInteger i=0;i<n;i++)
        {
            UMMTP3InstanceRoute *route = r[i];
            if(![route.linksetName isEqualToString:linksetName])
            {
                [r removeObjectAtIndex:i--];
                n--;
            }
        }
    }
    else
    {
        r = [[NSMutableArray alloc]init];
    }
    [_lock unlock];
    return r;
}


- (BOOL)updateDynamicRouteAvailable:(UMMTP3PointCode *)pc
                               mask:(int)mask
                        linksetName:(NSString *)linkset
                           priority:(UMMTP3RoutePriority)prio
{
    [_lock lock];
    NSMutableArray<UMMTP3InstanceRoute *> *r = [self getRouteArray:pc mask:mask];

    NSInteger n = r.count;
    BOOL found=NO;
    for(NSInteger i=0;i<n;i++)
    {
        UMMTP3InstanceRoute *route = r[i];
        if (([route.linksetName isEqualToString:linkset]) && (route.priority == prio))
        {
            route.status = UMMTP3_ROUTE_ALLOWED;
            found = YES;
        }
    }
    if(found==NO)
    {
        UMMTP3InstanceRoute *route = [[UMMTP3InstanceRoute alloc]init];
        route.linksetName = linkset;
        route.pointcode = pc;
        route.mask = mask;
        route.priority = prio;
        route.staticRoute = NO;
        route.status = UMMTP3_ROUTE_ALLOWED;
        [r addObject:route];
    }
    [_lock unlock];
    return found;
}

- (BOOL)updateDynamicRouteRestricted:(UMMTP3PointCode *)pc
                                mask:(int)mask
                         linksetName:(NSString *)linkset
                            priority:(UMMTP3RoutePriority)prio
{
    BOOL changed=YES;
    [_lock lock];
    NSMutableArray<UMMTP3InstanceRoute *> *r = [self getRouteArray:pc mask:mask];

    NSInteger n = r.count;
    BOOL found=NO;
    for(NSInteger i=0;i<n;i++)
    {
        UMMTP3InstanceRoute *route = r[i];
        if (([route.linksetName isEqualToString:linkset]) && (route.priority == prio))
        {
            if(route.status == UMMTP3_ROUTE_RESTRICTED)
            {
                changed = NO;
            }
            route.status = UMMTP3_ROUTE_RESTRICTED;
            found = YES;
        }
    }
    if(found==NO)
    {
        UMMTP3InstanceRoute *route = [[UMMTP3InstanceRoute alloc]init];
        route.linksetName = linkset;
        route.pointcode = pc;
        route.mask = mask;
        route.priority = prio;
        route.staticRoute = NO;
        route.status = UMMTP3_ROUTE_RESTRICTED;
        [r addObject:route];
    }
    [_lock unlock];
    return changed;
}

- (NSArray *)linksetNamesWhichHaveStaticRoutesForPointcode:(UMMTP3PointCode *)pc mask:(int)mask excluding:(NSString *)excluded
{
    NSMutableArray *arr = [[NSMutableArray alloc]init];
    [_lock lock];
    NSMutableArray<UMMTP3InstanceRoute *> *r = [self getRouteArray:pc mask:mask];
    NSInteger n = r.count;
    for(NSInteger i=0;i<n;i++)
    {
        UMMTP3InstanceRoute *route = r[i];
        if ((![route.linksetName isEqualToString:excluded]) && (route.staticRoute))
        {
            [arr addObject:route.linksetName];
        }
    }
    [_lock unlock];
    return arr;
}

- (BOOL)updateDynamicRouteUnavailable:(UMMTP3PointCode *)pc
                                 mask:(int)mask
                          linksetName:(NSString *)linkset
                             priority:(UMMTP3RoutePriority)prio
{
    BOOL changed = YES;
    [_lock lock];
    NSMutableArray<UMMTP3InstanceRoute *> *r = [self getRouteArray:pc mask:mask];

    NSInteger n = r.count;
    BOOL found=NO;
    for(NSInteger i=0;i<n;i++)
    {
        UMMTP3InstanceRoute *route = r[i];
        if (([route.linksetName isEqualToString:linkset]) && (route.priority == prio))
        {
            if(route.status != UMMTP3_ROUTE_PROHIBITED)
            {
                changed = YES;
            }
            route.status = UMMTP3_ROUTE_PROHIBITED;
            found = YES;
        }
    }
    if(found==NO)
    {
        UMMTP3InstanceRoute *route = [[UMMTP3InstanceRoute alloc]init];
        route.linksetName = linkset;
        route.pointcode = pc;
        route.mask = mask;
        route.priority = prio;
        route.staticRoute = NO;
        route.status = UMMTP3_ROUTE_PROHIBITED;
        changed = YES;
        [r addObject:route];
    }
    [_lock unlock];
    return changed;
}

- (BOOL) addStaticRoute:(UMMTP3PointCode *)pc
                   mask:(int)mask
            linksetName:(NSString *)linkset
               priority:(UMMTP3RoutePriority)prio
{
    [_lock lock];
    NSMutableArray<UMMTP3InstanceRoute *> *r = [self getRouteArray:pc mask:mask];

    NSInteger n = r.count;
    BOOL found=NO;
    for(NSInteger i=0;i<n;i++)
    {
        UMMTP3InstanceRoute *route = r[i];
        if (([route.linksetName isEqualToString:linkset]) && (route.priority == prio) && (route.staticRoute==YES))
        {
            found = YES;
            route.status = UMMTP3_ROUTE_ALLOWED;
            route.tstatus = UMMTP3_TEST_STATUS_UNKNOWN;
            break;
        }
    }
    if(found==NO)
    {
        UMMTP3InstanceRoute *route = [[UMMTP3InstanceRoute alloc]init];
        route.linksetName = linkset;
        route.pointcode = pc;
        route.mask = mask;
        route.priority = prio;
        route.staticRoute = YES;
        route.status = UMMTP3_ROUTE_ALLOWED;
        route.tstatus = UMMTP3_TEST_STATUS_UNKNOWN;
        [r addObject:route];
    }
    [_lock unlock];
    return found;
}


- (BOOL) removeStaticRoute:(UMMTP3PointCode *)pc
                      mask:(int)mask
               linksetName:(NSString *)linkset
                  priority:(UMMTP3RoutePriority)prio
{
    [_lock lock];
    NSMutableArray<UMMTP3InstanceRoute *> *r = [self getRouteArray:pc mask:mask];

    NSInteger n = r.count;
    BOOL found=NO;
    for(NSInteger i=0;i<n;i++)
    {
        UMMTP3InstanceRoute *route = r[i];
        if (([route.linksetName isEqualToString:linkset]) && (route.priority == prio) && (route.staticRoute==YES))
        {
            found = YES;
            [r removeObjectAtIndex:i];
            break;
        }
    }
    [_lock unlock];
    return found;
}

- (void)updateLinksetUnavailable:(NSString *)linkset
{
    [_lock lock];

    NSArray *pointcodes = [_routesByPointCode allKeys];
    for(id pointcode in pointcodes)
    {
        NSArray<UMMTP3InstanceRoute *>*routes = _routesByPointCode[pointcode];
        for(UMMTP3InstanceRoute *route in routes)
        {
            if([route.linksetName isEqualToString:linkset])
            {
                route.status = UMMTP3_ROUTE_PROHIBITED;
            }
        }
    }
    [_lock unlock];
}

- (void)updateLinksetRestricted:(NSString *)linkset
{
    [_lock lock];

    NSArray *pointcodes = [_routesByPointCode allKeys];
    for(id pointcode in pointcodes)
    {
        NSArray<UMMTP3InstanceRoute *>*routes = _routesByPointCode[pointcode];
        for(UMMTP3InstanceRoute *route in routes)
        {
            if([route.linksetName isEqualToString:linkset])
            {
                route.status = UMMTP3_ROUTE_RESTRICTED;
            }
        }
    }
    [_lock unlock];
}

- (void)updateLinksetAvailable:(NSString *)linkset
{
    [_lock lock];

    NSArray *pointcodes = [_routesByPointCode allKeys];
    for(id pointcode in pointcodes)
    {
        NSArray<UMMTP3InstanceRoute *>*routes = _routesByPointCode[pointcode];
        for(UMMTP3InstanceRoute *route in routes)
        {
            if([route.linksetName isEqualToString:linkset])
            {
                route.status = UMMTP3_ROUTE_ALLOWED;
            }
        }
    }
    [_lock unlock];
}

- (UMSynchronizedSortedDictionary *)routeStatus
{
    return self.objectValue;
}

- (BOOL) isRouteAvailable:(UMMTP3PointCode *)pc mask:(int)mask linkset:(NSString *)ls
{
    NSArray<UMMTP3InstanceRoute *> *routes = [self findRoutesForDestination:pc
                                                                      mask:mask
                                                           onlyLinksetName:ls];
    if(routes.count == 0)
    {
        return YES;
    }
    for(UMMTP3InstanceRoute *route in routes)
    {
        if(route.status == UMMTP3_ROUTE_ALLOWED)
        {
            return YES;
        }
    }
    return NO;
}

- (UMSynchronizedSortedDictionary *)objectValue
{
    UMSynchronizedSortedDictionary *dict = [[UMSynchronizedSortedDictionary alloc]init];
    [_lock lock];
    NSArray *pointcodes = [_routesByPointCode allKeys];
    pointcodes = [pointcodes sortedArrayUsingSelector:@selector(compare:)];
    for(NSNumber *pointcode in pointcodes)
    {
        NSArray<UMMTP3InstanceRoute *>*routes = _routesByPointCode[pointcode];
        routes = [routes sortedArrayUsingSelector:@selector(routingPreference:)];
        NSMutableArray *a = [[NSMutableArray alloc]init];
        for(UMMTP3InstanceRoute *route in routes)
        {
            UMSynchronizedSortedDictionary *rdict = [[UMSynchronizedSortedDictionary alloc]init];
            rdict[@"linkset"] = route.linksetName;
            switch(route.status)
            {
                case UMMTP3_ROUTE_UNUSED:
                    rdict[@"status"] = @"unused";
                    break;
                case UMMTP3_ROUTE_UNKNOWN:
                    rdict[@"status"] = @"unknown";
                    break;
                case UMMTP3_ROUTE_PROHIBITED:
                    rdict[@"status"] = @"prohibited";
                    break;
                case UMMTP3_ROUTE_RESTRICTED:
                    rdict[@"status"] = @"restricted";
                    break;
                case UMMTP3_ROUTE_ALLOWED:
                    rdict[@"status"] = @"allowed";
                    break;
                default:
                    rdict[@"status"] = @"undefined";
                    break;
            }
            rdict[@"metrics"] = route.metrics.objectValue;
            switch(route.tstatus)
            {
                case UMMTP3_TEST_STATUS_UNKNOWN:
                    rdict[@"test-status"] = @"unknown";
                    break;
                case UMMTP3_TEST_STATUS_RUNNING:
                    rdict[@"test-status"] = @"running";
                    break;
                case UMMTP3_TEST_STATUS_SUCCESS:
                    rdict[@"test-status"] = @"success";
                    break;
                case UMMTP3_TEST_STATUS_FAILED:
                    rdict[@"test-status"] = @"failed";
                    break;
                default:
                    rdict[@"test-status"] = @"undefined";
                    break;
            }
            rdict[@"priority"] = @(route.priority);
            rdict[@"queue-count"] = @(route.deliveryQueue.count);
            rdict[@"static-route"] = @(route.staticRoute);
            [a addObject:rdict];
        }
        dict[pointcode.stringValue] = a;
    }
    [_lock unlock];
    return dict;

}


@end
