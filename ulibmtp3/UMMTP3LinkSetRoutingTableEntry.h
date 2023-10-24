//
//  UMMTP3LinkSetRoutingTableEntry.h
//  ulibmtp3
//
//  Created by Andreas Fink on 04.10.22.
//  Copyright © 2022 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/ulib.h>
#import <ulibmtp3/UMMTP3RoutePriority.h>

@class UMMTP3PointCode;
typedef enum UMMTP3LinkSetRoutingTableStatus
{
    UMMTP3LinkSetRoutingTableStatus_unavailable = 1,
    UMMTP3LinkSetRoutingTableStatus_available = 2,
    UMMTP3LinkSetRoutingTableStatus_restricted = 3,
} UMMTP3LinkSetRoutingTableStatus;

@interface UMMTP3LinkSetRoutingTableEntry : UMObject
{
    UMMTP3PointCode     *_pc;
    UMMTP3RoutePriority _prio;
    BOOL                _isStatic;
    UMMTP3LinkSetRoutingTableStatus _status;
}

@property(readwrite,strong,atomic)  UMMTP3PointCode                 *pc;
@property(readwrite,assign,atomic)  UMMTP3RoutePriority             prio;
@property(readwrite,assign,atomic)  BOOL                            isStatic;
@property(readwrite,assign,atomic)  UMMTP3LinkSetRoutingTableStatus status;

@end
