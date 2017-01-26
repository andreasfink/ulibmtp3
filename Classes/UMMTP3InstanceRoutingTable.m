//
//  UMMTP3InstanceRoutingTable.m
//  ulibmtp3
//
//  Created by Andreas Fink on 26.01.17.
//  Copyright © 2017 Andreas Fink. All rights reserved.
//

#import "UMMTP3InstanceRoutingTable.h"
#import "UMMTP3LinkRoutingTable.h"

@implementation UMMTP3InstanceRoutingTable

-(UMMTP3RoutingTable *)init
{
    self = [super init];
    if(self)
    {
        routingTablesByLinkset = [[UMSynchronizedDictionary alloc]init];
    }
    return self;
}

- (UMMTP3Route *)findRouteForDestination:(UMMTP3PointCode *)pc linksetName:(NSString *)linkset
{
    return NULL;
}

- (UMMTP3Route *)findRouteForDestination:(UMMTP3PointCode *)pc excludeLinksetName:(NSString *)linkset
{
    return NULL;
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
    }
    return NULL;
}

@end
