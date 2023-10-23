//
//  UMMTP3RoutingUpdateDbRecord.m
//  ulibmtp3
//
//  Created by Andreas Fink on 13.04.23.
//  Copyright © 2023 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulibdb/ulibdb.h>
#import "UMMTP3RoutingUpdateDbRecord.h"

@implementation UMMTP3RoutingUpdateDbRecord

- (UMMTP3RoutingUpdateDbRecord *)init
{
    self = [super init];
    if(self)
    {
        _timestamp = UMTimeStampDT();
    }
    return self;
}

- (BOOL)insertIntoDb:(UMDbPool *)pool table:(UMDbTable *)dbt /* returns YES on success */
{
    BOOL success = NO;
    @autoreleasepool
    {
        @try
        {
            UMDbQuery *query = [UMDbQuery queryForFile:__FILE__ line: __LINE__];
            if(!query.isInCache)
            {
                NSArray *fields = @[
                                    @"timestamp",
                                    @"instance",
                                    @"inbound_linkset",
                                    @"outbound_linkset",
                                    @"dpc",
                                    @"status",
                                    @"reason"];
                [query setType:UMDBQUERYTYPE_INSERT];
                [query setTable:dbt];
                [query setFields:fields];
                [query addToCache];
            }
            NSArray *params  = [NSArray arrayWithObjects:
                                STRING_NONEMPTY(_timestamp),
                                STRING_NONEMPTY(_instance),
                                STRING_NONEMPTY(_inboundLinkset),
                                STRING_NONEMPTY(_outboundLinkset),
                                (_dpc ? [NSString stringWithFormat:@"%d",_dpc.pc] : @""),
                                STRING_NONEMPTY(_status),
                                STRING_NONEMPTY(_reason),
                                NULL];
            UMDbSession *session = [pool grabSession:FLF];
            unsigned long long affectedRows = 0;
            success = [session cachedQueryWithNoResult:query parameters:params allowFail:YES primaryKeyValue:NULL affectedRows:&affectedRows];
            [pool returnSession:session file:FLF];
        }
        @catch (NSException *e)
        {
            NSLog(@"Exception: %@",e);
        }
    }
    return success;
}

@end
