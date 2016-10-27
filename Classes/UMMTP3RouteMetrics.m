//
//  UMMTP3RouteMetrics.m
//  ulibmtp3
//
//  Created by Andreas Fink on 04/12/14.
//  Copyright (c) 2016 Andreas Fink
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


- (int)combinedMetricsValue
{
    return weight * local_preference;
}
@end
