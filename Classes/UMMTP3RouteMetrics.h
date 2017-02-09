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
    int weight;
    int local_preference;
    int aggregate;
    int as_path_legnth;
    int origin_type;
    int origin;
    int multi_exit_discrimators;
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
@end
