//
//  UMMTP3InstanceRoutingTable.m
//  ulibmtp3
//
//  Created by Andreas Fink on 26.01.17.
//  Copyright © 2017 Andreas Fink. All rights reserved.
//

#import "UMMTP3InstanceRoutingTable.h"
#import "UMMTP3LinkRoutingTable.h"
#import "UMMTP3LinkSet.h"
#import "UMMTP3Route.h"
#import "UMMTP3RouteMetrics.h"

@implementation UMMTP3InstanceRoutingTable

- (UMMTP3InstanceRoutingTable *)initWithLinkSetSortedDict:(UMSynchronizedSortedDictionary *)linksets
{
    self = [super init];
    if(self)
    {
        routingTablesByLinkset = [[UMSynchronizedSortedDictionary alloc]init];
        NSArray *keys = [linksets allKeys];
        for (id key in keys)
        {
            UMMTP3LinkSet *ls = linksets[key];
            routingTablesByLinkset[ls.name] = ls.routingTable;
        }
    }
    return self;
}

-(UMMTP3InstanceRoutingTable *)init
{
    self = [super init];
    if(self)
    {
        routingTablesByLinkset = [[UMSynchronizedSortedDictionary alloc]init];
    }
    return self;
}

- (UMMTP3Route *)findRouteForDestination:(UMMTP3PointCode *)pc linksetName:(NSString *)linksetName
{
    if(linksetName)
    {
        UMMTP3LinkRoutingTable *lrt = routingTablesByLinkset[linksetName];
        return [lrt findRouteForDestination:pc linksetName:linksetName];
    }

    UMMTP3Route *bestRoute = NULL;
    NSArray *keys = [routingTablesByLinkset allKeys];
    for(NSString *ls in keys)
    {
        UMMTP3LinkRoutingTable *lrt = routingTablesByLinkset[ls];
        UMMTP3Route *nextRoute = [lrt findRouteForDestination:pc linksetName:ls];
        if(nextRoute == NULL)
        {
            continue;
        }
        if((bestRoute == NULL) && ((nextRoute.status == UMMTP3_ROUTE_RESTRICTED) || (nextRoute.status == UMMTP3_ROUTE_ALLOWED)))
        {
            bestRoute = nextRoute;
        }
        else
        {
            if((bestRoute.status == UMMTP3_ROUTE_RESTRICTED) && (nextRoute.status == UMMTP3_ROUTE_ALLOWED))
            {
                bestRoute = nextRoute;
            }
            else if((bestRoute.status == UMMTP3_ROUTE_RESTRICTED) && (nextRoute.status == UMMTP3_ROUTE_RESTRICTED))
            {
                if(nextRoute.metrics.combinedMetricsValue > bestRoute.metrics.combinedMetricsValue)
                {
                    bestRoute = nextRoute;
                }
            }
            else if((bestRoute.status == UMMTP3_ROUTE_RESTRICTED) && (nextRoute.status == UMMTP3_ROUTE_ALLOWED))
            {
                bestRoute = nextRoute;
            }
            else if((bestRoute.status == UMMTP3_ROUTE_ALLOWED) && (nextRoute.status == UMMTP3_ROUTE_ALLOWED))
            {
                if(nextRoute.metrics.combinedMetricsValue > bestRoute.metrics.combinedMetricsValue)
                {
                    bestRoute = nextRoute;
                }
            }
        }
    }
    return bestRoute;
}

- (UMMTP3Route *)findRouteForDestination:(UMMTP3PointCode *)pc excludeLinksetName:(NSString *)linkset
{
    UMMTP3Route *bestRoute = NULL;
    NSArray *keys = [routingTablesByLinkset allKeys];
    for(NSString *ls in keys)
    {
        if([ls isEqualToString: linkset])
        {
            continue;
        }
        UMMTP3LinkRoutingTable *lrt = routingTablesByLinkset[ls];
        UMMTP3Route *nextRoute = [lrt findRouteForDestination:pc linksetName:ls];
        if(nextRoute == NULL)
        {
            continue;
        }
        if((bestRoute == NULL) && ((nextRoute.status == UMMTP3_ROUTE_RESTRICTED) || (nextRoute.status == UMMTP3_ROUTE_ALLOWED)))
        {
            bestRoute = nextRoute;
        }
        else
        {
            if((bestRoute.status == UMMTP3_ROUTE_RESTRICTED) && (nextRoute.status == UMMTP3_ROUTE_ALLOWED))
            {
                bestRoute = nextRoute;
            }
            else if((bestRoute.status == UMMTP3_ROUTE_RESTRICTED) && (nextRoute.status == UMMTP3_ROUTE_RESTRICTED))
            {
                if(nextRoute.metrics.combinedMetricsValue > bestRoute.metrics.combinedMetricsValue)
                {
                    bestRoute = nextRoute;
                }
            }
            else if((bestRoute.status == UMMTP3_ROUTE_RESTRICTED) && (nextRoute.status == UMMTP3_ROUTE_ALLOWED))
            {
                bestRoute = nextRoute;
            }
            else if((bestRoute.status == UMMTP3_ROUTE_ALLOWED) && (nextRoute.status == UMMTP3_ROUTE_ALLOWED))
            {
                if(nextRoute.metrics.combinedMetricsValue > bestRoute.metrics.combinedMetricsValue)
                {
                    bestRoute = nextRoute;
                }
            }
        }
    }
    return bestRoute;
}

- (NSArray *)findRoutesForDestination:(UMMTP3PointCode *)pc linksetName:(NSString *)linkset
{
    if(linkset)
    {
        UMMTP3LinkRoutingTable *table = routingTablesByLinkset[linkset];
        return [table findRoutesForDestination:pc linksetName:linkset];
    }
    else
    {
        NSArray *keys = [routingTablesByLinkset allKeys];
        NSMutableArray *result = [[NSMutableArray alloc]init];
        for(id key in keys)
        {
            UMMTP3LinkRoutingTable *table = routingTablesByLinkset[key];
            UMMTP3Route *r = [table findRouteForDestination:pc linksetName:key];
            if(r)
            {
                [result addObject:r];
            }
        }
        return result;
    }
    return NULL;
}

- (NSArray *)findRoutesForDestination:(UMMTP3PointCode *)pc excludeLinksetName:(NSString *)linkset
{
    if(linkset==NULL)
    {
        return [self findRoutesForDestination:pc linksetName:NULL];
    }
    else
    {
        
        NSArray *keys = [routingTablesByLinkset allKeys];
        NSMutableArray *result = [[NSMutableArray alloc]init];
        for(id key in keys)
        {
            if(![key isEqualToString:linkset])
            {
                UMMTP3LinkRoutingTable *table = routingTablesByLinkset[key];
                UMMTP3Route *r = [table findRouteForDestination:pc linksetName:key];
                if(r)
                {
                    [result addObject:r];
                }
            }
        }
        return result;
    }
    return NULL;
}

- (UMSynchronizedSortedDictionary *)objectValue
{
    UMSynchronizedSortedDictionary *d = [[UMSynchronizedSortedDictionary alloc]init];

    NSArray *keys = [routingTablesByLinkset allKeys];
    for(id key in keys)
    {
        UMMTP3LinkRoutingTable *table = routingTablesByLinkset[key];
        d[key] = [table objectValue];
    }
    return d;
}

@end
