//
//  UMMTP3InstanceRoutingTable.m
//  ulibmtp3
//
//  Created by Andreas Fink on 26.01.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
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
        routingTablesByLinkSet = [[UMSynchronizedSortedDictionary alloc]init];
        NSArray *keys = [linksets allKeys];
        for (id key in keys)
        {
            UMMTP3LinkSet *ls = linksets[key];
            routingTablesByLinkSet[ls.name] = ls.routingTable;
        }
    }
    return self;
}

-(UMMTP3InstanceRoutingTable *)init
{
    self = [super init];
    if(self)
    {
        routingTablesByLinkSet = [[UMSynchronizedSortedDictionary alloc]init];
    }
    return self;
}


- (UMMTP3Route *)findRouteForDestination:(UMMTP3PointCode *)pc
                                mask:(int)mask
                         linksetName:(NSString *)linksetName
                               exact:(BOOL)exact
{
    if(linksetName)
    {
        UMMTP3LinkRoutingTable *lrt = routingTablesByLinkSet[linksetName];
        return [lrt findRouteForDestination:pc mask:mask linksetName:linksetName exact:exact];
    }

    UMMTP3Route *bestRoute = NULL;
    NSArray *keys = [routingTablesByLinkSet allKeys];
    for(NSString *ls in keys)
    {
        UMMTP3LinkRoutingTable *lrt = routingTablesByLinkSet[ls];
        UMMTP3Route *nextRoute = [lrt findRouteForDestination:pc mask:mask linksetName:ls exact:exact];
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

- (UMMTP3Route *)findRouteForDestination:(UMMTP3PointCode *)pc mask:(int)mask excludeLinkSetName:(NSString *)linkset exact:(BOOL)exact
{
    UMMTP3Route *bestRoute = NULL;
    NSArray *keys = [routingTablesByLinkSet allKeys];
    for(NSString *ls in keys)
    {
        if([ls isEqualToString: linkset])
        {
            continue;
        }
        UMMTP3LinkRoutingTable *lrt = routingTablesByLinkSet[ls];
        UMMTP3Route *nextRoute = [lrt findRouteForDestination:pc  mask:mask linksetName:ls exact:exact];
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

- (NSArray *)findRoutesForDestination:(UMMTP3PointCode *)pc mask:(int)mask linksetName:(NSString *)linkset exact:(BOOL)exact
{
    if(linkset)
    {
        UMMTP3LinkRoutingTable *table = routingTablesByLinkSet[linkset];
        return [table findRoutesForDestination:pc mask:mask linksetName:linkset exact:exact];
    }
    else
    {
        NSArray *keys = [routingTablesByLinkSet allKeys];
        NSMutableArray *result = [[NSMutableArray alloc]init];
        for(id key in keys)
        {
            UMMTP3LinkRoutingTable *table = routingTablesByLinkSet[key];
            UMMTP3Route *r = [table findRouteForDestination:pc mask:mask linksetName:key exact:exact];
            if(r)
            {
                [result addObject:r];
            }
        }
        return result;
    }
    return NULL;
}

- (NSArray *)findRoutesForDestination:(UMMTP3PointCode *)pc mask:(int)mask excludeLinkSetName:(NSString *)linkset exact:(BOOL)exact
{
    if(linkset==NULL)
    {
        return [self findRoutesForDestination:pc mask:mask linksetName:NULL exact:exact];
    }
    else
    {
        NSArray *keys = [routingTablesByLinkSet allKeys];
        NSMutableArray *result = [[NSMutableArray alloc]init];
        for(id key in keys)
        {
            if(![key isEqualToString:linkset])
            {
                UMMTP3LinkRoutingTable *table = routingTablesByLinkSet[key];
                UMMTP3Route *r = [table findRouteForDestination:pc mask:mask linksetName:key exact:exact];
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

    NSArray *keys = [routingTablesByLinkSet allKeys];
    for(id key in keys)
    {
        UMMTP3LinkRoutingTable *table = routingTablesByLinkSet[key];
        d[key] = [table objectValue];
    }
    return d;
}

- (UMSynchronizedSortedDictionary *)routeStatus
{
    UMSynchronizedSortedDictionary *d = [[UMSynchronizedSortedDictionary alloc]init];

    NSArray *keys = [routingTablesByLinkSet allKeys];
    for(id key in keys)
    {
        UMMTP3LinkRoutingTable *table = routingTablesByLinkSet[key];
        d[key] = [table objectValue];
    }
    return d;

}

@end
