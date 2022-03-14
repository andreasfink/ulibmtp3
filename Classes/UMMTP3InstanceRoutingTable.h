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
    UMMutex                             *_lock;
    UMMTP3InstanceRoute                 *_defaultRoute;
}

@property(readwrite,assign) UMLogLevel logLevel;

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
                           priority:(UMMTP3RoutePriority)prio;

- (BOOL)updateDynamicRouteRestricted:(UMMTP3PointCode *)pc
                                mask:(int)mask
                         linksetName:(NSString *)linkset
                            priority:(UMMTP3RoutePriority)prio;


- (BOOL)updateDynamicRouteUnavailable:(UMMTP3PointCode *)pc
                                 mask:(int)mask
                          linksetName:(NSString *)linkset
                             priority:(UMMTP3RoutePriority)prio;

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
- (BOOL) isRouteAvailable:(UMMTP3PointCode *)pc mask:(int)mask linkset:(NSString *)ls;
- (UMSynchronizedSortedDictionary *)routeStatus;
- (UMSynchronizedSortedDictionary *)objectValue;
- (NSArray<UMMTP3InstanceRoute *>*)prohibitedOrRestrictedRoutes;
@end


