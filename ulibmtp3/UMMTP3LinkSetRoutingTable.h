//
//  UMMTP3LinkSetRoutingTable.h
//  ulibmtp3
//
//  Created by Andreas Fink on 04.10.22.
//  Copyright © 2022 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/ulib.h>
#import <ulibmtp3/UMMTP3RoutePriority.h>

@class UMMTP3PointCode;

@interface UMMTP3LinkSetRoutingTable : UMObject
{
    UMSynchronizedDictionary    *_entriesPerPointcode; /* this dictionary contains UMSynchronizedArray of UMInstanceRoute objects */
}


- (void)addStaticRoute:(UMMTP3PointCode *)pc     priority:(UMMTP3RoutePriority)prio;
- (void)removeStaticRoute:(UMMTP3PointCode *)pc  priority:(UMMTP3RoutePriority)prio;
- (void)addDynamicRoute:(UMMTP3PointCode *)pc    priority:(UMMTP3RoutePriority)prio;
- (void)removeDynamicRoute:(UMMTP3PointCode *)pc priority:(UMMTP3RoutePriority)prio;

- (void)updateDynamicRouteAvailable:(UMMTP3PointCode *)pc;
- (void)updateDynamicRouteRestricted:(UMMTP3PointCode *)pc;
- (void)updateDynamicRouteUnavailable:(UMMTP3PointCode *)pc;


@end
