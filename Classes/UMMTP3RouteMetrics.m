//
//  UMMTP3RouteMetrics.m
//  ulibmtp3
//
//  Created by Andreas Fink on 04/12/14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import "UMMTP3RouteMetrics.h"

@implementation UMMTP3RouteMetrics

@synthesize weight;
@synthesize local_preference;
@synthesize aggregate;
@synthesize as_path_legnth;
@synthesize origin_type;
@synthesize origin;
@synthesize multi_exit_discrimators;

- (UMMTP3RouteMetrics *)init
{
    self = [super init];
    if(self)
    {
        local_preference = 50;
        weight = 100;
    }
    return self;
}
- (int)combinedMetricsValue
{
    return weight * local_preference;
}

- (UMSynchronizedSortedDictionary *)objectValue
{
    UMSynchronizedSortedDictionary *dict = [[UMSynchronizedSortedDictionary alloc] init];
    dict[@"weight"] = @(weight);
    dict[@"local-preference"] = @(local_preference);
    dict[@"aggregate"] = @(aggregate);
    dict[@"as-path-length"] = @(as_path_legnth);
    dict[@"origin-type"] = @(origin_type);
    dict[@"multi-exit-discrimators"] = @(multi_exit_discrimators);
    return dict;
}

@end
