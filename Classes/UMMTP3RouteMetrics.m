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

- (UMMTP3RouteMetrics *)init
{
    self = [super init];
    if(self)
    {
        _local_preference = 50;
        _weight = 100;
    }
    return self;
}
- (int)combinedMetricsValue
{
    return _weight * _local_preference;
}

- (UMSynchronizedSortedDictionary *)objectValue
{
    UMSynchronizedSortedDictionary *dict = [[UMSynchronizedSortedDictionary alloc] init];
    dict[@"weight"] = @(_weight);
    dict[@"local-preference"] = @(_local_preference);
    dict[@"aggregate"] = @(_aggregate);
    dict[@"as-path-length"] = @(_as_path_legnth);
    dict[@"origin-type"] = @(_origin_type);
    dict[@"multi-exit-discrimators"] = @(_multi_exit_discrimators);
    return dict;
}


- (UMMTP3RouteMetrics *)copyWithZone:(NSZone *)zone
{
    UMMTP3RouteMetrics *r = [[UMMTP3RouteMetrics allocWithZone:zone]init];
    r.weight = _weight;
    r.local_preference = _local_preference;
    r.aggregate = _aggregate;
    r.as_path_legnth = _as_path_legnth;
    r.origin_type = _origin_type;
    r.origin = _origin;
    r.multi_exit_discrimators = _multi_exit_discrimators;
    return r;
}



@end
