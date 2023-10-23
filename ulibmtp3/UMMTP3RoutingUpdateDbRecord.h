//
//  UMMTP3RoutingUpdateDbRecord.h
//  ulibmtp3
//
//  Created by Andreas Fink on 13.04.23.
//  Copyright © 2023 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulibdb/ulibdb.h>
#import "UMMTP3PointCode.h"

@interface UMMTP3RoutingUpdateDbRecord : UMObject
{
    NSString *_timestamp;
    NSString *_instance;
    NSString *_inboundLinkset;
    NSString *_outboundLinkset;
    UMMTP3PointCode *_dpc;
    NSString *_status;
    NSString *_reason;
}

@property(readwrite,strong,atomic)  NSString *timestamp;
@property(readwrite,strong,atomic)  NSString *instance;
@property(readwrite,strong,atomic)  NSString *inboundLinkset;
@property(readwrite,strong,atomic)  NSString *outboundLinkset;
@property(readwrite,strong,atomic)  UMMTP3PointCode *dpc;
@property(readwrite,strong,atomic)  NSString *status;
@property(readwrite,strong,atomic)  NSString *reason;

- (BOOL)insertIntoDb:(UMDbPool *)pool table:(UMDbTable *)dbt; /* returns YES on success */

//- (BOOL)insertIntoDb:(UMDbPool *)pool table:(UMDbTable *)dbt; /* returns YES on success */
//- (BOOL)updateDb:(UMDbPool *)pool table:(UMDbTable *)dbt /* returns YES on success */

@end
