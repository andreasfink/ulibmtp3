//
//  UMMTP3Route.m
//  ulibmtp3
//
//  Created by Andreas Fink on 04/12/14.
//  Copyright (c) 2016 Andreas Fink
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import "UMMTP3Route.h"

#import "UMMTP3PointCode.h"
#import "UMMTP3LinkSet.h"
#import "UMMTP3RouteMetrics.h"

@implementation UMMTP3Route


@synthesize name;
@synthesize pointcode;
@synthesize deliveryQueue;
@synthesize status;
@synthesize tstatus;
@synthesize congestion;
@synthesize last_test;
@synthesize t15;
@synthesize max_speed;
@synthesize current_max_speed;
@synthesize current_speed;
@synthesize speedometer;
@synthesize limit_has_been_hit;
@synthesize speedup_counter;
@synthesize linkset;
@synthesize metrics;

- (NSComparisonResult)routingPreference:(UMMTP3Route *)other
{
    if((status == UMMTP3_ROUTE_PROHIBITED) && (other.status == UMMTP3_ROUTE_ALLOWED))
    {
        return NSOrderedAscending;
    }
    if((status == UMMTP3_ROUTE_ALLOWED) && (other.status ==  UMMTP3_ROUTE_PROHIBITED))
    {
        return NSOrderedDescending;
    }
    if((status == UMMTP3_ROUTE_RESTRICTED) && (other.status == UMMTP3_ROUTE_ALLOWED))
    {
        return NSOrderedAscending;
    }
    if((status == UMMTP3_ROUTE_ALLOWED) && (other.status ==  UMMTP3_ROUTE_RESTRICTED))
    {
        return NSOrderedDescending;
    }

    if(metrics.combinedMetricsValue > other.metrics.combinedMetricsValue)
    {
        return NSOrderedDescending;
    }
    if(metrics.combinedMetricsValue < other.metrics.combinedMetricsValue)
    {
        return NSOrderedAscending;
    }
    double load1 = current_speed / current_max_speed;
    double load2 = other.current_speed / other.current_max_speed;
    if(load1 > load2)
    {
        return NSOrderedDescending;
    }
    if(load1 < load2)
    {
        return NSOrderedAscending;
    }
    return NSOrderedSame;
}
@end
