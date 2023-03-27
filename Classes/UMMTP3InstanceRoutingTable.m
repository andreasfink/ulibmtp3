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
        _routingTableLock = [[UMMutex alloc]initWithName: @"mtp3-instance-routing-table-lock"];
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

- (void)setRouteArray:(NSMutableArray<UMMTP3InstanceRoute *> *) arr forPointcode:(UMMTP3PointCode *)pc mask:(int) mask
{
    NSMutableArray<UMMTP3InstanceRoute *> *r = NULL;
    if((mask == pc.maxmask) || (mask == -1)) /* single pointcode */
    {
        _routesByPointCode[@(pc.pc)] = arr;
    }
    else
    {
        [_logFeed minorErrorText:[NSString stringWithFormat:@"Can not handle routes with masks yet pc=%@ mask=%d",pc,mask]];
        r = NULL;
    }
}

- (UMMTP3InstanceRoute *)findRouteForDestination:(UMMTP3PointCode *)pc
                                            mask:(int)mask
                              excludeLinkSetName:(NSString *)linksetName
                                           exact:(BOOL)exact

{
    NSArray<UMMTP3InstanceRoute *> *a = [self findRoutesForDestination:pc
                                                                  mask:mask
                                                    excludeLinkSetName:linksetName
                                                                 exact:exact];
    if(a.count < 1)
    {
        return _defaultRoute;
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
    UMMUTEX_LOCK(_routingTableLock);
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
    UMMUTEX_UNLOCK(_routingTableLock);
    if(r.count == 0)
    {
        if(![_defaultRoute.linksetName isEqualToString:linksetName])
        {
            r = [[NSMutableArray alloc]init];
            if(_defaultRoute)
            {
                [r addObject:_defaultRoute];
            }
        }
    }
    return r;
}

- (NSArray<UMMTP3InstanceRoute *> *)findRoutesForDestination:(UMMTP3PointCode *)pc
                                                       mask:(int)mask
                                            onlyLinksetName:(NSString *)linksetName
{
    UMMUTEX_LOCK(_routingTableLock);
    NSMutableArray *validRoutes = [[NSMutableArray alloc]init];
    NSMutableArray<UMMTP3InstanceRoute *> *r = [self getRouteArray:pc mask:mask];
    for(UMMTP3InstanceRoute *route in r)
    {
        if(linksetName.length > 0)
        {
            if([linksetName isEqualToString:route.linksetName])
            {
                [validRoutes addObject:r];
            }
        }
        else
        {
            [validRoutes addObject:r];
        }
    }
    if(r.count == 0)
    {
        if(linksetName.length > 0)
        {
            if([linksetName isEqualToString:_defaultRoute.linksetName])
            {
                [validRoutes addObject:_defaultRoute];
            }
        }
        else
        {
            [validRoutes addObject:_defaultRoute];
        }
    }
    UMMUTEX_UNLOCK(_routingTableLock);
    return r;
}


- (BOOL)updateDynamicRouteAvailable:(UMMTP3PointCode *)pc
                               mask:(int)mask
                        linksetName:(NSString *)linkset
                           priority:(UMMTP3RoutePriority)prio
                         hasChanged:(BOOL *)hasChanged
{
    BOOL    found = NO;
    UMMUTEX_LOCK(_routingTableLock);
    NSMutableArray<UMMTP3InstanceRoute *> *r = [self getRouteArray:pc mask:mask];
    UMMTP3InstanceRoute *oldBestRoute = [self bestRoute:pc routeArray:r];
    if(r==NULL)
    {
        r = [[NSMutableArray alloc]init];
    }
    for(UMMTP3InstanceRoute *route in r)
    {
        if ([route.linksetName isEqualToString:linkset])
        {
            route.status = UMMTP3_ROUTE_ALLOWED;
            found = YES;
        }
    }
    if(found==NO)
    {
        UMMTP3InstanceRoute *route = [[UMMTP3InstanceRoute alloc] initWithPc:pc
                                                                 linksetName:linkset
                                                                    priority:prio
                                                                        mask:pc.maxmask];
        route.priority = prio;
        route.staticRoute = NO;
        route.status = UMMTP3_ROUTE_ALLOWED;
        [r addObject:route];
    }
    UMMTP3InstanceRoute *newBestRoute = [self bestRoute:pc routeArray:r];
    if(*hasChanged)
    {
        if(oldBestRoute != newBestRoute)
        {
            *hasChanged = YES;
        }
        else
        {
            *hasChanged = NO;
        }
    }
    
    [self setRouteArray:r forPointcode:pc mask:mask];
    UMMUTEX_UNLOCK(_routingTableLock);
    return found;
}

- (NSDictionary  *)statusOfPointcodes /* key is NSNumber of pc, value is nsnumber of UMMTP3RouteStatus */
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
    UMMUTEX_LOCK(_routingTableLock);
    NSArray *pointcodes = [_routesByPointCode allKeys];
    for(NSNumber *pointcode in pointcodes)
    {
        UMMTP3PointCode *pc = [[UMMTP3PointCode alloc]initWitPc:pointcode.intValue
                                                        variant:UMMTP3Variant_Undefined];
        UMMTP3RouteStatus status = [self statusOfRoute:pc];
        dict[pointcode] = @(status);
    }
    UMMUTEX_UNLOCK(_routingTableLock);
    return dict;
}

- (NSDictionary  *)statusOfStaticOrDirectlyConnectedPointcodesExcludingLinkset:(NSString *)lsname /* key is NSNumber of pc, value is nsnumber of UMMTP3RouteStatus */
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
    UMMUTEX_LOCK(_routingTableLock);
    NSArray *pointcodes = [_routesByPointCode allKeys];
    for(NSNumber *pointcode in pointcodes)
    {
        UMMTP3PointCode *pc = [[UMMTP3PointCode alloc]initWitPc:pointcode.intValue
                                                        variant:UMMTP3Variant_Undefined];
        UMMTP3RouteStatus status = [self statusOfStaticOrDirectlyConnectedRoute:pc excludingLinkset:lsname];
        dict[pointcode] = @(status);
    }
    UMMUTEX_UNLOCK(_routingTableLock);
    return dict;
}

- (BOOL)updateDynamicRouteRestricted:(UMMTP3PointCode *)pc
                                mask:(int)mask
                         linksetName:(NSString *)linkset
                            priority:(UMMTP3RoutePriority)prio
                          hasChanged:(BOOL *)hasChanged
{
    BOOL found = NO;
    UMMUTEX_LOCK(_routingTableLock);
    NSMutableArray<UMMTP3InstanceRoute *> *r = [self getRouteArray:pc mask:mask];
    UMMTP3InstanceRoute *oldBestRoute = [self bestRoute:pc routeArray:r];
    if(r==NULL)
    {
        r = [[NSMutableArray alloc]init];
    }
    
    for(UMMTP3InstanceRoute *route in r)
    {
        if ([route.linksetName isEqualToString:linkset])
        {
            route.status = UMMTP3_ROUTE_RESTRICTED;
            found = YES;
        }
    }
    if(found==NO)
    {
        UMMTP3InstanceRoute *route = [[UMMTP3InstanceRoute alloc] initWithPc:pc
                                                                 linksetName:linkset
                                                                    priority:prio
                                                                        mask:pc.maxmask];
        route.staticRoute = NO;
        route.status = UMMTP3_ROUTE_RESTRICTED;
        [r addObject:route];
    }
    UMMTP3InstanceRoute *newBestRoute = [self bestRoute:pc routeArray:r];
    if(*hasChanged)
    {
        if(oldBestRoute != newBestRoute)
        {
            *hasChanged = YES;
        }
        else
        {
            *hasChanged = NO;
        }
    }
    [self setRouteArray:r forPointcode:pc mask:mask];
    UMMUTEX_UNLOCK(_routingTableLock);
    return found;
}


- (BOOL)updateDynamicRouteUnavailable:(UMMTP3PointCode *)pc
                                 mask:(int)mask
                          linksetName:(NSString *)linkset
                             priority:(UMMTP3RoutePriority)prio
                           hasChanged:(BOOL *)hasChanged
{
    UMMUTEX_LOCK(_routingTableLock);
    NSMutableArray<UMMTP3InstanceRoute *> *r = [self getRouteArray:pc mask:mask];
    UMMTP3InstanceRoute *oldBestRoute = [self bestRoute:pc routeArray:r];
    if(r==NULL)
    {
        r = [[NSMutableArray alloc]init];
    }
    BOOL found=NO;
    
    for(UMMTP3InstanceRoute *route in r)
    {
        if ([route.linksetName isEqualToString:linkset])
        {
            route.status = UMMTP3_ROUTE_PROHIBITED;
            found = YES;
        }
    }
    if(found==NO)
    {
        UMMTP3InstanceRoute *route = [[UMMTP3InstanceRoute alloc] initWithPc:pc
                                                                 linksetName:linkset
                                                                    priority:prio
                                                                        mask:pc.maxmask];
        route.staticRoute = NO;
        route.status = UMMTP3_ROUTE_PROHIBITED;
        [r addObject:route];
    }
    UMMTP3InstanceRoute *newBestRoute = [self bestRoute:pc routeArray:r];
    if(*hasChanged)
    {
        if(oldBestRoute != newBestRoute)
        {
            *hasChanged = YES;
        }
        else
        {
            *hasChanged = NO;
        }
    }
    [self setRouteArray:r forPointcode:pc mask:mask];
    UMMUTEX_UNLOCK(_routingTableLock);
    return found;
}


- (NSArray *)linksetNamesWhichHaveStaticRoutesForPointcode:(UMMTP3PointCode *)pc mask:(int)mask excluding:(NSString *)excluded
{
    NSMutableArray *arr = [[NSMutableArray alloc]init];
    UMMUTEX_LOCK(_routingTableLock);
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
    UMMUTEX_UNLOCK(_routingTableLock);
    return arr;
}

- (BOOL) addStaticRoute:(UMMTP3PointCode *)pc
                   mask:(int)mask
            linksetName:(NSString *)linkset
               priority:(UMMTP3RoutePriority)prio
{
    return [self addStaticRoute:pc mask:mask linksetName:linkset priority:prio weight:NULL localPreference:NULL];
}

- (BOOL) addStaticRoute:(UMMTP3PointCode *)pc
                   mask:(int)mask
            linksetName:(NSString *)linkset
               priority:(UMMTP3RoutePriority)prio
                 weight:(NSNumber *)weight
        localPreference:(NSNumber *)localpref
{
    BOOL found=NO;
    UMMUTEX_LOCK(_routingTableLock);
    if((pc.pc == 0) && (mask == 0))
    {
        UMMTP3InstanceRoute *route = [[UMMTP3InstanceRoute alloc] initWithPc:pc
                                                                 linksetName:linkset
                                                                    priority:prio
                                                                        mask:pc.maxmask
                                                                      weight:weight
                                                             localPreference:localpref];
        route.linksetName = linkset;
        route.pointcode = 0;
        route.mask = 0;
        route.priority = prio;
        route.staticRoute = YES;
        route.status = UMMTP3_ROUTE_ALLOWED;
        route.tstatus = UMMTP3_TEST_STATUS_UNKNOWN;
        _defaultRoute = route;
    }
    else
    {
        NSMutableArray<UMMTP3InstanceRoute *> *r = [self getRouteArray:pc mask:mask];
        NSInteger n = r.count;
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
            UMMTP3InstanceRoute *route = [[UMMTP3InstanceRoute alloc] initWithPc:pc
                                                                     linksetName:linkset
                                                                        priority:prio
                                                                            mask:pc.maxmask];
            route.linksetName = linkset;
            route.pointcode = pc;
            route.mask = mask;
            route.priority = prio;
            route.staticRoute = YES;
            route.status = UMMTP3_ROUTE_ALLOWED;
            route.tstatus = UMMTP3_TEST_STATUS_UNKNOWN;
            [r addObject:route];
        }
    }
    UMMUTEX_UNLOCK(_routingTableLock);
    return found;
}


- (BOOL) removeStaticRoute:(UMMTP3PointCode *)pc
                      mask:(int)mask
               linksetName:(NSString *)linkset
                  priority:(UMMTP3RoutePriority)prio
{
    UMMUTEX_LOCK(_routingTableLock);
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
    UMMUTEX_UNLOCK(_routingTableLock);
    return found;
}

- (void)updateLinksetUnavailable:(NSString *)linkset
{
    UMMUTEX_LOCK(_routingTableLock);
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
    UMMUTEX_UNLOCK(_routingTableLock);
}

- (void)updateLinksetRestricted:(NSString *)linkset
{
    UMMUTEX_LOCK(_routingTableLock);
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
    UMMUTEX_UNLOCK(_routingTableLock);
}

- (void)updateLinksetAvailable:(NSString *)linkset
{
    UMMUTEX_LOCK(_routingTableLock);

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
    UMMUTEX_UNLOCK(_routingTableLock);
}

- (NSArray<UMMTP3InstanceRoute *>*)prohibitedOrRestrictedRoutes
{
    UMMUTEX_LOCK(_routingTableLock);
    NSMutableArray *r = [[NSMutableArray alloc]init];
    NSArray *pointcodes = [_routesByPointCode allKeys];
    for(id pointcode in pointcodes)
    {
        NSArray<UMMTP3InstanceRoute *>*routes = _routesByPointCode[pointcode];
        for(UMMTP3InstanceRoute *route in routes)
        {
            if((route.status == UMMTP3_ROUTE_PROHIBITED) || (route.status == UMMTP3_ROUTE_RESTRICTED))
            {
                [r addObject:route];
            }
        }
    }
    UMMUTEX_UNLOCK(_routingTableLock);
    return r;
}

- (UMSynchronizedSortedDictionary *)routeStatus
{
    return self.objectValue;
}


/* this assumes the routing table lock is engaged */
- (UMMTP3InstanceRoute *) bestRoute:(UMMTP3PointCode *)pc
                         routeArray:(NSMutableArray<UMMTP3InstanceRoute *> *)r
{
    return [self bestRoute:pc
                routeArray:r
        staticOrDirectOnly:NO
          excludingLinkset:NULL];
}
- (UMMTP3InstanceRoute *) bestRoute:(UMMTP3PointCode *)pc
                         routeArray:(NSMutableArray<UMMTP3InstanceRoute *> *)r
                 staticOrDirectOnly:(BOOL)staticOrDirectOnly
                   excludingLinkset:(NSString *)ls
{
    if(r==NULL)
    {
        r = [self getRouteArray:pc mask:pc.maxmask];
    }
    UMMTP3InstanceRoute *bestRoute = NULL;
    if(r.count == 0)
    {
        return NULL;
    }
    for(UMMTP3InstanceRoute *route in r)
    {
        if((staticOrDirectOnly==YES) && (!((route.staticRoute) || (route.priority==1))))
        {
            continue;
        }
        if([ls isEqualToString:route.linksetName])
        {
            continue;
        }
        switch(route.status)
        {
            case UMMTP3_ROUTE_ALLOWED:
                if(bestRoute==NULL)
                {
                    bestRoute=route;
                }
                else if(bestRoute.status == UMMTP3_ROUTE_ALLOWED)
                {
                    if(bestRoute.priority > route.priority)
                    {
                        bestRoute = route;
                    }
                }
                else
                {
                    bestRoute = route;
                }
                break;
            case UMMTP3_ROUTE_RESTRICTED:
                if(bestRoute==NULL)
                {
                    bestRoute=route;
                }
                else
                {
                    switch(bestRoute.status)
                    {
                        case UMMTP3_ROUTE_ALLOWED:
                            continue;
                        case UMMTP3_ROUTE_UNUSED:
                        case UMMTP3_ROUTE_UNKNOWN:
                            bestRoute = route;
                            break;
                        case UMMTP3_ROUTE_RESTRICTED:
                            if(bestRoute.priority == route.priority)
                            {
                                /* in tie case, we prefer the static route */
                                if(route.staticRoute)
                                {
                                    bestRoute = route;
                                }
                            }
                            else if(bestRoute.priority > route.priority)
                            {
                                bestRoute = route;
                            }
                            break;
                        case UMMTP3_ROUTE_PROHIBITED:
                            bestRoute = route;
                            break;
                    }
                }
                break;
            case UMMTP3_ROUTE_PROHIBITED:
                if(bestRoute==NULL)
                {
                    bestRoute=route;
                }
                else
                {
                    switch(bestRoute.status)
                    {

                        case UMMTP3_ROUTE_ALLOWED:
                        case UMMTP3_ROUTE_RESTRICTED:
                            continue;
                        case UMMTP3_ROUTE_PROHIBITED:
                            if(bestRoute.priority == route.priority)
                            {
                                /* in tie case, we prefer the static route */
                                if(route.staticRoute)
                                {
                                    bestRoute = route;
                                }
                            }
                            else if(bestRoute.priority > route.priority)
                            {
                                bestRoute = route;
                            }
                            break;
                        case UMMTP3_ROUTE_UNUSED:
                        case UMMTP3_ROUTE_UNKNOWN:
                            bestRoute = route;
                            break;
                    }
                }
                break;
            case UMMTP3_ROUTE_UNUSED:
            case UMMTP3_ROUTE_UNKNOWN:
                if(bestRoute==NULL)
                {
                    bestRoute=route;
                }
                break;
        }
    }
    return bestRoute;
}

/* this assumes routing table lock is engaged */

- (UMMTP3RouteStatus) statusOfRoute:(UMMTP3PointCode *)pc
{
    
    UMMTP3InstanceRoute *route = [self bestRoute:pc routeArray:NULL];
    if(route == NULL)
    {
        return UMMTP3_ROUTE_UNKNOWN;
    }
    return route.status;
}



- (UMMTP3RouteStatus) statusOfStaticOrDirectlyConnectedRoute:(UMMTP3PointCode *)pc excludingLinkset:(NSString *)ls
{
    
    UMMTP3InstanceRoute *route = [self bestRoute:pc routeArray:NULL staticOrDirectOnly:YES excludingLinkset:ls];
    if(route == NULL)
    {
        return UMMTP3_ROUTE_UNKNOWN;
    }
    return route.status;
}

- (BOOL) isRouteAvailable:(UMMTP3PointCode *)pc mask:(int)mask linkset:(NSString *)ls
{
    NSArray<UMMTP3InstanceRoute *> *routes = [self findRoutesForDestination:pc
                                                                       mask:mask
                                                            onlyLinksetName:ls];
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
    UMMUTEX_LOCK(_routingTableLock);
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
    UMMUTEX_UNLOCK(_routingTableLock);
    return dict;
}

- (void)lock
{
    UMMUTEX_LOCK(_routingTableLock);
}

- (void)unlock
{
    UMMUTEX_UNLOCK(_routingTableLock);
}

@end
