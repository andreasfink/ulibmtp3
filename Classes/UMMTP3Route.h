//
//  UMMTP3Route.h
//  ulibmtp3
//
//  Created by Andreas Fink on 04/12/14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import <ulib/ulib.h>
#import "UMMTP3RoutePriority.h"
@class UMMTP3PointCode;
@class UMMTP3LinkSet;
@class UMMTP3RouteMetrics;

typedef enum UMMTP3RouteStatus
{
    UMMTP3_ROUTE_UNUSED         = 100,
    UMMTP3_ROUTE_UNKNOWN		= 101,
    UMMTP3_ROUTE_PROHIBITED     = 102,
    UMMTP3_ROUTE_RESTRICTED     = 103,
    UMMTP3_ROUTE_ALLOWED		= 104,
} UMMTP3RouteStatus;

typedef	enum	UMMTP3RouteCongestionLevel
{
    UMMTP3_CONGESTION_LEVEL_0 = 0,
    UMMTP3_CONGESTION_LEVEL_1 = 1,
    UMMTP3_CONGESTION_LEVEL_2 = 2,
    UMMTP3_CONGESTION_LEVEL_3 = 3,
    UMMTP3_CONGESTION_LEVEL_4 = 4,
    UMMTP3_CONGESTION_LEVEL_5 = 5,
    UMMTP3_CONGESTION_LEVEL_6 = 6,
    UMMTP3_CONGESTION_LEVEL_7 = 7,
    UMMTP3_CONGESTION_LEVEL_8 = 8,
    UMMTP3_CONGESTION_LEVEL_9 = 9,
    UMMTP3_CONGESTION_LEVEL_10 = 10,
    UMMTP3_CONGESTION_LEVEL_11 = 11,
    UMMTP3_CONGESTION_LEVEL_12 = 12,
    UMMTP3_CONGESTION_LEVEL_13 = 13,
    UMMTP3_CONGESTION_LEVEL_14 = 14,
    UMMTP3_CONGESTION_LEVEL_15 = 15,
    UMMTP3_CONGESTION_LEVEL_16 = 16,
    UMMTP3_CONGESTION_LEVEL_17 = 17,
    UMMTP3_CONGESTION_LEVEL_18 = 18,
    UMMTP3_CONGESTION_LEVEL_19 = 19,
    UMMTP3_CONGESTION_LEVEL_20 = 20,
    UMMTP3_CONGESTION_LEVEL_21 = 21,
    UMMTP3_CONGESTION_LEVEL_22 = 22,
    UMMTP3_CONGESTION_LEVEL_23 = 23,
    UMMTP3_CONGESTION_LEVEL_24 = 24,
    UMMTP3_CONGESTION_LEVEL_25 = 25,
    UMMTP3_CONGESTION_LEVEL_26 = 26,
    UMMTP3_CONGESTION_LEVEL_27 = 27,
    UMMTP3_CONGESTION_LEVEL_28 = 28,
    UMMTP3_CONGESTION_LEVEL_29 = 29,
    UMMTP3_CONGESTION_LEVEL_30 = 30,
    UMMTP3_CONGESTION_LEVEL_31 = 31,
    UMMTP3_CONGESTION_LEVEL_32 = 32,
    UMMTP3_CONGESTION_LEVEL_33 = 33,
    UMMTP3_CONGESTION_LEVEL_34 = 34,
    UMMTP3_CONGESTION_LEVEL_35 = 35,
    UMMTP3_CONGESTION_LEVEL_36 = 36,
    UMMTP3_CONGESTION_LEVEL_37 = 37,
    UMMTP3_CONGESTION_LEVEL_38 = 38,
    UMMTP3_CONGESTION_LEVEL_39 = 39,
    UMMTP3_CONGESTION_LEVEL_40 = 40,
    UMMTP3_CONGESTION_LEVEL_41 = 41,
    UMMTP3_CONGESTION_LEVEL_42 = 42,
    UMMTP3_CONGESTION_LEVEL_43 = 43,
    UMMTP3_CONGESTION_LEVEL_44 = 44,
    UMMTP3_CONGESTION_LEVEL_45 = 45,
    UMMTP3_CONGESTION_LEVEL_46 = 46,
    UMMTP3_CONGESTION_LEVEL_47 = 47,
    UMMTP3_CONGESTION_LEVEL_48 = 48,
    UMMTP3_CONGESTION_LEVEL_49 = 49,
    UMMTP3_CONGESTION_LEVEL_50 = 50,
    UMMTP3_CONGESTION_LEVEL_START = UMMTP3_CONGESTION_LEVEL_30,
    UMMTP3_CONGESTION_LEVEL_MAX = UMMTP3_CONGESTION_LEVEL_50,
} UMMTP3RouteCongestionLevel;

typedef enum UMMTP3RouteTestStatus
{
    UMMTP3_TEST_STATUS_UNKNOWN		= 0,
    UMMTP3_TEST_STATUS_RUNNING		= 1,
    UMMTP3_TEST_STATUS_SUCCESS		= 2,
    UMMTP3_TEST_STATUS_FAILED		= 3,
} UMMTP3RouteTestStatus;


@interface UMMTP3Route : UMObject
{
    NSString                    *name;
    NSString                    *linksetName;

    UMMTP3PointCode             *pointcode;
    int                         mask;               
    UMMTP3RouteMetrics          *metrics;
    UMQueue                     *deliveryQueue;
    UMMTP3RouteStatus           status;
    UMMTP3RouteTestStatus       tstatus;
    time_t                      last_test;
    UMMTP3RouteCongestionLevel  congestion;
    UMTimer                     *t15;
    UMThroughputCounter         *speedometer;

//    double                      max_speed;
//    double                      speed[UMMTP3_CONGESTION_LEVEL_MAX+10];		 /* in messages per sec */;
//    double                      current_max_speed;
//    double                      current_speed;
//  int                         limit_has_been_hit;
//  int                         speedup_counter;
}

@property(readwrite,strong) NSString *name;
@property(readwrite,strong) UMMTP3PointCode *pointcode;
@property(readwrite,assign,atomic) int mask;
@property(readwrite,strong,atomic) NSString *linksetName;


@property(readwrite,strong) UMQueue *deliveryQueue;
@property(readwrite,assign,atomic) UMMTP3RouteStatus           status;
@property(readwrite,assign) UMMTP3RouteTestStatus       tstatus;
@property(readwrite,assign) UMMTP3RouteCongestionLevel  congestion;
@property(readwrite,assign) time_t last_test;
@property(readwrite,strong) UMTimer *t15;
@property(readwrite,assign) double max_speed;
@property(readwrite,assign) double current_max_speed;
@property(readwrite,assign) double current_speed;
@property(readwrite,strong) UMThroughputCounter *speedometer;
@property(readwrite,assign) int limit_has_been_hit;
@property(readwrite,assign) int speedup_counter;
@property(readwrite,strong) UMMTP3RouteMetrics *metrics;

- (NSComparisonResult)routingPreference:(UMMTP3Route *)other;

- (UMMTP3Route *)initWithPc:(UMMTP3PointCode *)pc
                linksetName:(NSString *)linksetName
                   priority:(UMMTP3RoutePriority)prio
                       mask:(int)mask;

- (UMSynchronizedSortedDictionary *)objectValue;
- (NSString *)routingTableKey;

@end
