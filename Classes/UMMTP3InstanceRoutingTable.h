//
//  UMMTP3InstanceRoutingTable.h
//  ulibmtp3
//
//  Created by Andreas Fink on 17.02.20.
//  Copyright © 2020 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/ulib.h>

#import "UMMTP3InstanceRoute.h"
#import "UMMTP3RoutePriority.h"

@interface UMMTP3InstanceRoutingTable : UMObject
{
    NSString                            *_logFileName;
    UMLogLevel                          _logLevel;
    NSMutableDictionary                 *_routesByPointCode;
    UMMutex                             *_routingTableLock;
    UMMTP3InstanceRoute                 *_defaultRoute;
}

@property(readwrite,assign) UMLogLevel logLevel;
@property(readonly)         UMMutex *routingTableLock;

- (void)lock;
- (void)unlock;

- (UMMTP3InstanceRoute *)findRouteForDestination:(UMMTP3PointCode *)pc
                                            mask:(int)mask
                              excludeLinkSetName:(NSString *)linksetName
                                           exact:(BOOL)exact;

- (NSArray<UMMTP3InstanceRoute *> *)findRoutesForDestination:(UMMTP3PointCode *)pc
                                                        mask:(int)mask
                                          excludeLinkSetName:(NSString *)linksetName
                                                       exact:(BOOL)exact;


- (BOOL)updateDynamicRouteAvailable:(UMMTP3PointCode *)pc
                               mask:(int)mask
                        linksetName:(NSString *)linkset
                           priority:(UMMTP3RoutePriority)prio
                         hasChanged:(BOOL *)hasChanged;

- (BOOL)updateDynamicRouteRestricted:(UMMTP3PointCode *)pc
                                mask:(int)mask
                         linksetName:(NSString *)linkset
                            priority:(UMMTP3RoutePriority)prio
                          hasChanged:(BOOL *)hasChanged;



- (BOOL)updateDynamicRouteUnavailable:(UMMTP3PointCode *)pc
                                 mask:(int)mask
                          linksetName:(NSString *)linkset
                             priority:(UMMTP3RoutePriority)prio
                           hasChanged:(BOOL *)hasChanged;

- (NSArray *)linksetNamesWhichHaveStaticRoutesForPointcode:(UMMTP3PointCode *)pc mask:(int)mask excluding:(NSString *)excluded;

- (BOOL) addStaticRoute:(UMMTP3PointCode *)pc   /* returns YES if found in table */
                   mask:(int)mask
            linksetName:(NSString *)linkset
               priority:(UMMTP3RoutePriority)prio;

- (BOOL) removeStaticRoute:(UMMTP3PointCode *)pc /* returns YES if found in table */
                      mask:(int)mask
               linksetName:(NSString *)linkset
                  priority:(UMMTP3RoutePriority)prio;

- (void)updateLinksetUnavailable:(NSString *)linkset;
- (void)updateLinksetRestricted:(NSString *)linkset;
- (void)updateLinksetAvailable:(NSString *)linkset;

- (UMMTP3RouteStatus) statusOfRoute:(UMMTP3PointCode *)pc;
- (UMMTP3RouteStatus) statusOfStaticOrDirectlyConnectedRoute:(UMMTP3PointCode *)pc excludingLinkset:(NSString *)lsname;

- (NSDictionary  *)statusOfPointcodes; /* key is NSNumber of pc, value is NSNumber of UMMTP3RouteStatus */
- (NSDictionary  *)statusOfStaticOrDirectlyConnectedPointcodesExcludingLinkset:(NSString *)lsname; /* key is NSNumber of pc, value is NSNumber of UMMTP3RouteStatus */

- (BOOL) isRouteAvailable:(UMMTP3PointCode *)pc mask:(int)mask linkset:(NSString *)ls;
- (UMSynchronizedSortedDictionary *)routeStatus;
- (UMSynchronizedSortedDictionary *)objectValue;
- (NSArray<UMMTP3InstanceRoute *>*)prohibitedOrRestrictedRoutes;

/* this assumes the routing table lock is already engaged */
- (UMMTP3InstanceRoute *) bestRoute:(UMMTP3PointCode *)pc
                         routeArray:(NSMutableArray<UMMTP3InstanceRoute *> *)r;

- (UMMTP3InstanceRoute *) bestRoute:(UMMTP3PointCode *)pc
                         routeArray:(NSMutableArray<UMMTP3InstanceRoute *> *)r
                 staticOrDirectOnly:(BOOL)staticOrDirectOnly
                   excludingLinkset:(NSString *)ls;

@end


