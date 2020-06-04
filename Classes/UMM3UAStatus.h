//
//  UMM3UA_Status.h
//  ulibmtp3
//
//  Created by Andreas Fink on 24.01.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//


typedef enum UMM3UA_Status
{
    M3UA_STATUS_UNUSED      = 0, /* undefined state */
    M3UA_STATUS_OFF         = 1, /* sctp is down */
    M3UA_STATUS_OOS         = 2, /* sctp is down, but connection is requested */
    M3UA_STATUS_BUSY        = 3, /* sctp is up but ASPUP is not received */
    M3UA_STATUS_INACTIVE    = 4, /* sctp is up, ASPUP received but not in active state */
    M3UA_STATUS_IS          = 5, /* up and active */
} UMM3UA_Status;
