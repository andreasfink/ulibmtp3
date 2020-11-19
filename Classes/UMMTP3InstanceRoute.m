//
//  UMMTP3InstanceRoute.m
//  ulibmtp3
//
//  Created by Andreas Fink on 17.02.20.
//  Copyright © 2020 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMMTP3InstanceRoute.h"
#import "UMMTP3PointCode.h"
#import "UMMTP3LinkSet.h"
#import "UMMTP3RouteMetrics.h"
#import "UMLayerMTP3.h"

@implementation UMMTP3InstanceRoute

- (NSComparisonResult)routingPreference:(UMMTP3InstanceRoute *)other
{
    if((_status == UMMTP3_ROUTE_PROHIBITED) && (other.status == UMMTP3_ROUTE_ALLOWED))
    {
        return NSOrderedAscending;
    }
    if((_status == UMMTP3_ROUTE_ALLOWED) && (other.status ==  UMMTP3_ROUTE_PROHIBITED))
    {
        return NSOrderedDescending;
    }
    if((_status == UMMTP3_ROUTE_RESTRICTED) && (other.status == UMMTP3_ROUTE_ALLOWED))
    {
        return NSOrderedAscending;
    }
    if((_status == UMMTP3_ROUTE_ALLOWED) && (other.status ==  UMMTP3_ROUTE_RESTRICTED))
    {
        return NSOrderedDescending;
    }
    if(_priority > other.priority)
    {
        return NSOrderedAscending;
    }
    if(_priority < other.priority)
    {
        return NSOrderedDescending;
    }
    if(_metrics.combinedMetricsValue > other.metrics.combinedMetricsValue)
    {
        return NSOrderedDescending;
    }
    if(_metrics.combinedMetricsValue < other.metrics.combinedMetricsValue)
    {
        return NSOrderedAscending;
    }


    double load1 = _current_speed / _current_max_speed;
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

- (UMMTP3InstanceRoute *)initWithPc:(UMMTP3PointCode *)pc
                linksetName:(NSString *)lsName
                   priority:(UMMTP3RoutePriority)prio
                       mask:(int)xmask
{
    self = [super init];
    if(self)
    {

        _priority = prio;
        _name = [self description];
        _linksetName = lsName;
        _pointcode = [pc maskedPointcode:xmask];
        _mask = xmask;
        _metrics = [[UMMTP3RouteMetrics alloc]init];
        switch(prio)
        {
            case UMMTP3RoutePriority_1:
                _metrics.local_preference = 800;
                break;
            case UMMTP3RoutePriority_2:
                _metrics.local_preference = 400;
                break;
            case UMMTP3RoutePriority_3:
                _metrics.local_preference = 200;
                break;
            case UMMTP3RoutePriority_4:
                _metrics.local_preference = 100;
                break;
            case UMMTP3RoutePriority_5:
            case UMMTP3RoutePriority_undefined:
                _metrics.local_preference = 50;
                break;
            case UMMTP3RoutePriority_6:
                _metrics.local_preference = 25;
                break;
            case UMMTP3RoutePriority_7:
                _metrics.local_preference = 12;
                break;
            case UMMTP3RoutePriority_8:
                _metrics.local_preference = 6;
                break;
            case UMMTP3RoutePriority_9:
                _metrics.local_preference = 3;
                break;
        }
        _deliveryQueue = [[UMQueueSingle alloc]init];
        _status = UMMTP3_ROUTE_UNKNOWN;
        _tstatus = UMMTP3_TEST_STATUS_UNKNOWN;
        _last_test = 0;
        _t15 = [[UMTimer alloc]init];
        _speedometer = [[UMThroughputCounter alloc]initWithResolutionInSeconds: 1.0 maxDuration: 1260.0];
    }
    return self;
}

- (UMSynchronizedSortedDictionary *)objectValue
{
    UMSynchronizedSortedDictionary *dict = [[UMSynchronizedSortedDictionary alloc]init];

    if(_name)
    {
        dict[@"name"] = _name;
    }
    if(_linksetName)
    {
        dict[@"linkset-name"] = _linksetName;
    }
    if(_pointcode)
    {
        dict[@"pointcode"] = _pointcode.stringValue;
    }
    dict[@"priority"] = @(_priority);

    dict[@"mask"] = @(_mask);
    if(self.metrics)
    {
        dict[@"metrics"] = self.metrics.objectValue;
    }
    switch(_status)
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

    switch(_tstatus)
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
        dict[@"speedometer"] = [_speedometer getSpeedStringTriple];
    }
    return dict;
}

- (NSString *)routingTableKey
{
    return [_pointcode maskedPointcodeString:_mask];
}

@end
