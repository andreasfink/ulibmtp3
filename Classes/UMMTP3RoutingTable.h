//
//  UMMTP3RoutingTable.h
//  ulibmtp3
//
//  Created by Andreas Fink on 04/12/14.
//  Copyright (c) 2016 Andreas Fink
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import <ulib/ulib.h>

@class UMMTP3Route;
@class UMMTP3PointCode;

@interface UMMTP3RoutingTable : UMLayer
{
    UMSynchronizedDictionary *routesByPointCode;
}

- (UMMTP3Route *)findRouteForDestination:(UMMTP3PointCode *)pc;

@end
