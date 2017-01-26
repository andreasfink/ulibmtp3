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
    return NULL;
}

- (NSArray *)findRoutesForDestination:(UMMTP3PointCode *)pc excludeLinksetName:(NSString *)linkset
{
    return NULL;
}

- (void)updateRouteAvailable:(UMMTP3PointCode *)pc linksetName:(NSString *)linkset
{
}

- (void)updateRouteRestricted:(UMMTP3PointCode *)pc linksetName:(NSString *)linkset
{
}

- (void)updateRouteUnavailable:(UMMTP3PointCode *)pc linksetName:(NSString *)linkset
{
}

- (void) addRoute:(UMMTP3Route *)route linksetName:(UMMTP3LinkSet *)linkset
{
}

- (void) removeRoute:(UMMTP3PointCode *)pc linksetName:(UMMTP3LinkSet *)linkset
{
}

- (void) updateRoute:(UMMTP3Route *)route linksetName:(UMMTP3LinkSet *)linkset
{
}


@end
