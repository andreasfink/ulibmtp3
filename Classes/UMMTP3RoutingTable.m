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
                      excludeLinksetName:(NSString *)linksetName
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
                   excludeLinksetName:(NSString *)linksetName
                                exact:(BOOL)exact;
{
    return NULL;
}


- (void)updateRouteAvailable:(UMMTP3PointCode *)pc
                        mask:(int)mask
                 linksetName:(NSString *)linkset
{

}

- (void)updateRouteRestricted:(UMMTP3PointCode *)pc
                         mask:(int)mask
                  linksetName:(NSString *)linkset
{

}

- (void)updateRouteUnavailable:(UMMTP3PointCode *)pc
                          mask:(int)mask
                   linksetName:(NSString *)linkset
{

}

- (UMSynchronizedSortedDictionary *)objectValue
{
    return NULL;
}

@end
