//
//  UMMTP3Route.m
//  ulibmtp3
//
//  Created by Andreas Fink on 04/12/14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
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
@synthesize mask;
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
                       mask:(int)xmask
{
    self = [super init];
    if(self)
    {

        name = [self description];
        linksetName = lsName;
        pointcode = [pc maskedPointcode:xmask];
        mask = xmask;
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
        speedometer = [[UMThroughputCounter alloc]initWithResolutionInSeconds: 1.0 maxDuration: 1260.0];
    }
    return self;
}

- (UMSynchronizedSortedDictionary *)objectValue
{
    UMSynchronizedSortedDictionary *dict = [[UMSynchronizedSortedDictionary alloc]init];

    if(self.name)
    {
        dict[@"name"] = self.name;
    }
    if(self.linksetName)
    {
        dict[@"linkset-name"] = self.linksetName;
    }
    if(self.pointcode)
    {
        dict[@"pointcode"] = self.pointcode.stringValue;
    }
    dict[@"mask"] = @(self.mask);
    if(self.metrics)
    {
        dict[@"metrics"] = self.metrics.objectValue;
    }
    switch(self.status)
    {
        case UMMTP3_ROUTE_UNUSED:
            dict[@"status"] = @"unused";
            break;
        case UMMTP3_ROUTE_UNKNOWN:
            dict[@"status"] = @"unknown";
            break;
        case UMMTP3_ROUTE_PROHIBITED:
            dict[@"status"] = @"prohibited";
            break;
        case UMMTP3_ROUTE_RESTRICTED:
            dict[@"status"] = @"restricted";
            break;
        case UMMTP3_ROUTE_ALLOWED:
            dict[@"status"] = @"allowed";
            break;
    }

    switch(self.tstatus)
    {
        case UMMTP3_TEST_STATUS_UNKNOWN:
            dict[@"test-status"] = @"unused";
            break;
        case UMMTP3_TEST_STATUS_RUNNING:
            dict[@"test-status"] = @"running";
            break;
        case UMMTP3_TEST_STATUS_SUCCESS:
            dict[@"test-status"] = @"success";
            break;
        case UMMTP3_TEST_STATUS_FAILED:
            dict[@"test-status"] = @"failed";
            break;
    }
    if(self.last_test)
    {
        NSDate *d = [NSDate dateWithTimeIntervalSince1970:(self.last_test)];
        dict[@"last-test"] = d.description;
    }
    else
    {
        dict[@"last-test"] = @"never";
    }
    if(self.speedometer)
    {
        dict[@"speedometer"] = [speedometer getSpeedStringTriple];
    }
    return dict;
}

- (NSString *)routingTableKey
{
    return [pointcode maskedPointcodeString:mask];
}

@end
