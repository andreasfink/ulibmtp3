//
//  UMMTP3RouteMetrics.h
//  ulibmtp3
//
//  Created by Andreas Fink on 04/12/14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import <ulib/ulib.h>

@interface UMMTP3RouteMetrics : UMObject
{
    int _weight;
    int _local_preference;
    int _aggregate;
    int _as_path_legnth;
    int _origin_type;
    int _origin;
    int _multi_exit_discrimators;
}


@property (readwrite,assign) int weight;
@property (readwrite,assign) int local_preference;
@property (readwrite,assign) int aggregate;
@property (readwrite,assign) int as_path_legnth;
@property (readwrite,assign) int origin_type;
@property (readwrite,assign) int origin;
@property (readwrite,assign) int multi_exit_discrimators;

- (int)combinedMetricsValue;
- (UMSynchronizedSortedDictionary *)objectValue;
- (UMMTP3RouteMetrics *)copyWithZone:(NSZone *)zone;

@end
