//
//  UMMTP3RouteStatus.h
//  ulibmtp3
//
//  Created by Andreas Fink on 17.02.20.
//  Copyright © 2020 Andreas Fink (andreas@fink.org). All rights reserved.
//

typedef enum UMMTP3RouteStatus
{
    UMMTP3_ROUTE_UNUSED         = 100,
    UMMTP3_ROUTE_UNKNOWN        = 101,
    UMMTP3_ROUTE_PROHIBITED     = 102,
    UMMTP3_ROUTE_RESTRICTED     = 103,
    UMMTP3_ROUTE_ALLOWED        = 104,
} UMMTP3RouteStatus;
