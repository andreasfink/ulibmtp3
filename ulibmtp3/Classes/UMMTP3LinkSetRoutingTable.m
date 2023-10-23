//
//  UMMTP3LinkSetRoutingTable.c
//  ulibmtp3
//
//  Created by Andreas Fink on 04.10.22.
//  Copyright © 2022 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMMTP3LinkSetRoutingTable.h"
#import "UMMTP3PointCode.h"


@implementation UMMTP3LinkSetRoutingTable

- (UMMTP3LinkSetRoutingTable *)init
{
    self = [super init];
    if(self)
    {
        _entriesPerPointcode = [[UMSynchronizedDictionary alloc]init];
    }
    return self;
}


- (void)addStaticRoute:(UMMTP3PointCode *)pc priority:(UMMTP3RoutePriority)prio
{
    
}

- (void)removeStaticRoute:(UMMTP3PointCode *)pc priority:(UMMTP3RoutePriority)prio;
{
    
}

- (void)addDynamicRoute:(UMMTP3PointCode *)pc priority:(UMMTP3RoutePriority)prio
{
    
}

- (void)removeDynamicRoute:(UMMTP3PointCode *)pc priority:(UMMTP3RoutePriority)prio
{
    
}

- (void)updateDynamicRouteAvailable:(UMMTP3PointCode *)pc
{
    
}

- (void)updateDynamicRouteRestricted:(UMMTP3PointCode *)pc
{
    
}

- (void)updateDynamicRouteUnavailable:(UMMTP3PointCode *)pc
{
    
}

@end

