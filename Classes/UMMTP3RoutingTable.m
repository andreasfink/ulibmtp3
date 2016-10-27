//
//  UMMTP3RoutingTable.m
//  ulibmtp3
//
//  Created by Andreas Fink on 04/12/14.
//  Copyright (c) 2016 Andreas Fink
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import "UMMTP3RoutingTable.h"
#import "UMMTP3PointCode.h"
#import "UMMTP3Route.h"

@implementation UMMTP3RoutingTable


-(UMMTP3RoutingTable *)init
{
    self = [super init];
    if(self)
    {
        routesByPointCode = [[UMSynchronizedDictionary alloc]init];
    }
    return self;
}

- (UMMTP3Route *)findRouteForDestination:(UMMTP3PointCode *)pc
{
    
    UMSynchronizedArray *routes = routesByPointCode[pc.description];
    if(routes == NULL)
    {
        routes = routesByPointCode[@"default"];
        if(routes == NULL)
        {
            return NULL;
        }
    }
    NSMutableArray *r = [routes mutableCopy];
    [r sortUsingSelector:@selector(routingPreference:)];
    return (UMMTP3Route *)[r lastObject];
}

@end
