//
//  UMMTP3InstanceRoute.h
//  ulibmtp3
//
//  Created by Andreas Fink on 17.02.20.
//  Copyright © 2020 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/ulib.h>
#import <ulibmtp3/UMMTP3RoutePriority.h>
#import <ulibmtp3/UMLayerMTP3ApplicationContextProtocol.h>
#import <ulibmtp3/UMMTP3RouteStatus.h>
#import <ulibmtp3/UMMTP3RouteCongestionLevel.h>
#import <ulibmtp3/UMMTP3RouteTestStatus.h>

@class UMMTP3PointCode;
@class UMMTP3LinkSet;
@class UMMTP3RouteMetrics;



@interface UMMTP3InstanceRoute : UMObject
{
    NSString                    *_name;
    NSString                    *_linksetName;
    UMMTP3PointCode             *_pointcode;
    int                         _mask;
    UMMTP3RouteMetrics          *_metrics;
    UMQueueSingle               *_deliveryQueue;
    UMMTP3RouteStatus           _status;
    UMMTP3RouteTestStatus       _tstatus;
    time_t                      _last_test;
    UMMTP3RouteCongestionLevel  _congestion;
    UMTimer                     *_t15;
    UMThroughputCounter         *_speedometer;
    UMMTP3RoutePriority         _priority;
    BOOL                        _staticRoute;
    BOOL                        _isClone;
}

@property(readwrite,strong) NSString        *name;
@property(readwrite,strong,atomic) NSString *linksetName;
@property(readwrite,strong) UMMTP3PointCode *pointcode;
@property(readwrite,assign,atomic) int      mask;
@property(readwrite,strong) UMQueueSingle   *deliveryQueue;
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
@property(readwrite,assign) UMMTP3RoutePriority priority;
@property(readwrite,assign) BOOL staticRoute;
@property(readwrite,assign) BOOL isClone;

- (NSComparisonResult)routingPreference:(UMMTP3InstanceRoute *)other;

- (UMMTP3InstanceRoute *)initWithPc:(UMMTP3PointCode *)pc
                        linksetName:(NSString *)lsName
                           priority:(UMMTP3RoutePriority)prio
                               mask:(int)xmask
                             weight:(NSNumber *)weight
                    localPreference:(NSNumber *)localpref;

- (UMMTP3InstanceRoute *)initWithPc:(UMMTP3PointCode *)pc
                        linksetName:(NSString *)linksetName
                           priority:(UMMTP3RoutePriority)prio
                               mask:(int)mask;

- (UMSynchronizedSortedDictionary *)objectValue;
- (NSString *)routingTableKey;
@end
