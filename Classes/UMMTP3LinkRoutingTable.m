//
//  UMMTP3LinkRoutingTable.m
//  ulibmtp3
//
//  Created by Andreas Fink on 26.01.17.
//  Copyright © 2017 Andreas Fink. All rights reserved.
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

- (UMMTP3Route *)findRouteForDestination:(UMMTP3PointCode *)pc linksetName:(NSString *)linksetName
{
    UMMTP3Route *r = routesByPointCode[@(pc.integerValue)];
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
    return NULL;
}

- (UMMTP3Route *)findRouteForDestination:(UMMTP3PointCode *)pc excludeLinksetName:(NSString *)linksetName
{
    UMMTP3Route *r = routesByPointCode[@(pc.integerValue)];
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
    return NULL;
}

- (NSArray *)findRoutesForDestination:(UMMTP3PointCode *)pc linksetName:(NSString *)linksetName
{
    UMMTP3Route *r = [self findRouteForDestination:pc linksetName:linksetName];
    return @[r];
}

- (NSArray *)findRoutesForDestination:(UMMTP3PointCode *)pc excludeLinksetName:(NSString *)linksetName
{
    UMMTP3Route *r = [self findRouteForDestination:pc excludeLinksetName:linksetName];
    return @[r];
}


- (void)updateRouteAvailable:(UMMTP3PointCode *)pc linksetName:(NSString *)linksetName
{
    UMMTP3Route *r = [self findRouteForDestination:pc linksetName:linksetName];
    if(r)
    {
        r.status = UMMTP3_ROUTE_ALLOWED;
    }
    else
    {
        r = [[UMMTP3Route alloc]initWithPc:pc
                               linksetName:linksetName
                                  priority:UMMTP3RoutePriority_undefined];
        r.status = UMMTP3_ROUTE_ALLOWED;
        routesByPointCode[@(pc.integerValue)] = r;
    }
}
- (void)updateRouteRestricted:(UMMTP3PointCode *)pc linksetName:(NSString *)linksetName
{
    UMMTP3Route *r = [self findRouteForDestination:pc linksetName:linksetName];
    if(r)
    {
        r.status = UMMTP3_ROUTE_RESTRICTED;
    }
    else
    {
        r = [[UMMTP3Route alloc]initWithPc:pc
                               linksetName:linksetName
                                  priority:UMMTP3RoutePriority_undefined];
        r.status = UMMTP3_ROUTE_RESTRICTED;
        routesByPointCode[@(pc.integerValue)] = r;
    }
}
- (void)updateRouteUnavailable:(UMMTP3PointCode *)pc linksetName:(NSString *)linksetName
{
    UMMTP3Route *r = [self findRouteForDestination:pc linksetName:linksetName];
    if(r)
    {
        r.status = UMMTP3_ROUTE_PROHIBITED;
    }
    else
    {
        r = [[UMMTP3Route alloc]initWithPc:pc
                               linksetName:linksetName
                                  priority:UMMTP3RoutePriority_undefined];
        r.status = UMMTP3_ROUTE_PROHIBITED;
        routesByPointCode[@(pc.integerValue)] = r;
    }
}

/* for routing tables which have only one entry per DPC. Like on a linkset */
- (void) addDestination:(UMMTP3PointCode *)pc
            linksetName:(NSString *)linksetName
{
    UMMTP3Route *r = [[UMMTP3Route alloc]initWithPc:pc linksetName:linksetName priority:UMMTP3RoutePriority_undefined];
    routesByPointCode[@(pc.integerValue)] = r;
}

- (void) removeDestination:(UMMTP3PointCode *)pc
         linksetName:(NSString *)linksetName
{
    UMMTP3Route *r= routesByPointCode[@(pc.integerValue)];
    if(r)
    {
        if( (NULL == linksetName) || ([r.linksetName isEqualToString:linksetName]))
        {
            [routesByPointCode removeObjectForKey:@(pc.integerValue)];
        }
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
