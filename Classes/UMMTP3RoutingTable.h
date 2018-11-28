//
//  UMMTP3RoutingTable.h
//  ulibmtp3
//
//  Created by Andreas Fink on 04/12/14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import <ulib/ulib.h>
#import "UMMTP3Route.h"
@class UMMTP3PointCode;
@class UMMTP3LinkSet;

@interface UMMTP3RoutingTable : UMObject 
{
    NSString                            *logFileName;
    UMLogLevel                          logLevel;
}

- (UMMTP3Route *)findRouteForDestination:(UMMTP3PointCode *)pc
                                    mask:(int)mask
                             linksetName:(NSString *)linksetName
                                   exact:(BOOL)exact;

- (UMMTP3Route *)findRouteForDestination:(UMMTP3PointCode *)pc
                                    mask:(int)mask
                      excludeLinkSetName:(NSString *)linksetName
                                   exact:(BOOL)exact;

- (NSArray *)findRoutesForDestination:(UMMTP3PointCode *)pc
                                 mask:(int)mask
                          linksetName:(NSString *)linksetName
                                exact:(BOOL)exact;

- (NSArray *)findRoutesForDestination:(UMMTP3PointCode *)pc
                                 mask:(int)mask
                   excludeLinkSetName:(NSString *)linksetName
                                exact:(BOOL)exact;

- (void)updateRouteAvailable:(UMMTP3PointCode *)pc
                        mask:(int)mask
                 linksetName:(NSString *)linkset;

- (void)updateRouteRestricted:(UMMTP3PointCode *)pc
                         mask:(int)mask
                  linksetName:(NSString *)linkset;

- (void)updateRouteUnavailable:(UMMTP3PointCode *)pc
                          mask:(int)mask
                   linksetName:(NSString *)linkset;

- (UMSynchronizedSortedDictionary *)objectValue;

- (UMMTP3RouteStatus)isRouteAvailable:(UMMTP3PointCode *)pc mask:(int)mask linksetName:(NSString *)linksetName;

//- (void)logDebug:(NSString *)s;
@end

