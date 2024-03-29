//
//  UMMTP3StatisticDbRecord.m
//  ulibmtp3
//
//  Created by Andreas Fink on 01.06.20.
//  Copyright © 2020 Andreas Fink (andreas@fink.org). All rights reserved.
//
#import <ulibdb/ulibdb.h>

#import "UMMTP3StatisticDbRecord.h"


@implementation UMMTP3StatisticDbRecord


- (UMMTP3StatisticDbRecord *)init
{
    self = [super init];
    if(self)
    {
        _statisticDbRecordLock = [[UMMutex alloc]initWithName:@"UMMTP3StatisticDbRecord-lock"];
    }
    return self;
}

- (NSString *)keystring
{
    return [NSString stringWithFormat:@"%@:%@:%d:%@:%d:%d:%@",_ymdh,_incoming_linkset,_opc,_outgoing_linkset,_dpc,_si,_instance];
}

+ (NSString *)keystringFor:(NSString *)ymdh
           incomingLinkset:(NSString *)incomingLinkset
           outgoingLinkset:(NSString *)outgoingLinkset
                       opc:(int)opc
                       dpc:(int)dpc
                        si:(int)si
                  instance:(NSString *)instance
{
    return [NSString stringWithFormat:@"%@:%@:%d:%@:%d:%d:%@",ymdh,incomingLinkset,opc,outgoingLinkset,dpc,si,instance];
}

- (BOOL)insertIntoDb:(UMDbPool *)pool table:(UMDbTable *)dbt /* returns YES on success */
{
    BOOL success = NO;
    @autoreleasepool
    {
        @try
        {
            [_statisticDbRecordLock lock];
            UMDbQuery *query = [UMDbQuery queryForFile:__FILE__ line: __LINE__];
            if(!query.isInCache)
            {
                NSArray *fields = @[
                                    @"dbkey",
                                    @"ymdh",
                                    @"instance",
                                    @"incoming_linkset",
                                    @"outgoing_linkset",
                                    @"opc",
                                    @"dpc",
                                    @"si",
                                    @"msu_count",
                                    @"bytes_count"];
                [query setType:UMDBQUERYTYPE_INSERT];
                [query setTable:dbt];
                [query setFields:fields];
                [query addToCache];
            }
            NSString *key = [self keystring];
            NSArray *params  = [NSArray arrayWithObjects:
                                STRING_NONEMPTY(key),
                                STRING_NONEMPTY(_ymdh),
                                STRING_NONEMPTY(_instance),
                                STRING_NONEMPTY(_incoming_linkset),
                                STRING_NONEMPTY(_outgoing_linkset),
                                STRING_FROM_INT(_opc),
                                STRING_FROM_INT(_dpc),
                                STRING_FROM_INT(_si),
                                STRING_FROM_INT(_msu_count),
                                STRING_FROM_INT(_bytes_count),
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
        @finally
        {
            [_statisticDbRecordLock unlock];
        }
    }
    return success;
}

- (BOOL)updateDb:(UMDbPool *)pool table:(UMDbTable *)dbt /* returns YES on success */
{
    BOOL success = NO;
    @autoreleasepool
    {
        @try
        {
            [_statisticDbRecordLock lock];
            
            UMDbQuery *query = [UMDbQuery queryForFile:__FILE__ line: __LINE__];
            if(!query.isInCache)
            {
                [query setType:UMDBQUERYTYPE_INCREASE_BY_KEY];
                [query setTable:dbt];
                [query setFields:@[@"msu_count",@"bytes_count"]];
                [query setPrimaryKeyName:@"dbkey"];
                [query addToCache];
            }
            NSArray *params = [NSArray arrayWithObjects:
                                [NSNumber numberWithInt:_msu_count],
                                [NSNumber numberWithInt:_bytes_count],
                                 NULL];
            NSString *key = [self keystring];
            UMDbSession *session = [pool grabSession:__FILE__ line:__LINE__ func:__func__];
            unsigned long long rowCount;
            success = [session cachedQueryWithNoResult:query
                                            parameters:params
                                             allowFail:YES
                                       primaryKeyValue:key
                                          affectedRows:&rowCount];
            if(rowCount==0)
            {
                success = NO;
            }
            [pool returnSession:session file:__FILE__ line:__LINE__ func:__func__];
        }
        @catch (NSException *e)
        {
            NSLog(@"Exception: %@",e);
        }
        @finally
        {
            [_statisticDbRecordLock unlock];
        }
    }
    return success;
}

- (void)increaseMsuCount:(int)msuCount byteCount:(int)byteCount
{
    [_statisticDbRecordLock lock];
    _msu_count += msuCount;
    _bytes_count += byteCount;
    [_statisticDbRecordLock unlock];
}

- (void)flushToPool:(UMDbPool *)pool table:(UMDbTable *)table
{
    [_statisticDbRecordLock lock];
    if([self updateDb:pool table:table] == NO)
    {
        if([self insertIntoDb:pool table:table])
        {
            _msu_count = 0;
            _bytes_count = 0;
        }
    }
    [_statisticDbRecordLock unlock];
}

@end
