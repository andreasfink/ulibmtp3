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
@synthesize linksetName;
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

- (UMMTP3Route *)initWithPc:(UMMTP3PointCode *)pc
                linksetName:(NSString *)lsName
                   priority:(UMMTP3RoutePriority)prio
{
    self = [super init];
    if(self)
    {
        name = [self description];
        linksetName = lsName;
        pointcode = pc;
        metrics = [[UMMTP3RouteMetrics alloc]init];
        switch(prio)
        {
            case UMMTP3RoutePriority_1:
                metrics.local_preference = 800;
                break;
            case UMMTP3RoutePriority_2:
                metrics.local_preference = 400;
                break;
            case UMMTP3RoutePriority_3:
                metrics.local_preference = 200;
                break;
            case UMMTP3RoutePriority_4:
            case UMMTP3RoutePriority_undefined:
                metrics.local_preference = 100;
                break;
            case UMMTP3RoutePriority_5:
                metrics.local_preference = 50;
                break;
            case UMMTP3RoutePriority_6:
                metrics.local_preference = 25;
                break;
            case UMMTP3RoutePriority_7:
                metrics.local_preference = 12;
                break;
            case UMMTP3RoutePriority_8:
                metrics.local_preference = 6;
                break;
            case UMMTP3RoutePriority_9:
                metrics.local_preference = 3;
                break;
        }
        deliveryQueue = [[UMQueue alloc]init];
        status = UMMTP3_ROUTE_UNKNOWN;
        tstatus = UMMTP3_TEST_STATUS_UNKNOWN;
        last_test = 0;
        t15 = [[UMTimer alloc]init];
        speedometer = [[UMThroughputCounter alloc]init];
    }
    return self;
}
@end
