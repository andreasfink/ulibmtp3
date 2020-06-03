//
//  UMMTP3StatisticDb.m
//  ulibmtp3
//
//  Created by Andreas Fink on 01.06.20.
//  Copyright © 2020 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMMTP3StatisticDb.h"

#import "UMMTP3StatisticDbRecord.h"
#define UMMTP3_STATISTICS_DEBUG 1

static dbFieldDef UMMTP3StatisticDb_fields[] =
{
    {"dbkey",               NULL,       NO,     DB_PRIMARY_INDEX,   DB_FIELD_TYPE_VARCHAR,             255,   0,NULL,NULL,1},
    {"ymdh",                NULL,       NO,     DB_INDEXED,         DB_FIELD_TYPE_VARCHAR,             32,    0,NULL,NULL,2},
    {"instance",            NULL,       NO,     DB_INDEXED,         DB_FIELD_TYPE_VARCHAR,             32,    0,NULL,NULL,2},
    {"incoming_linkset",    NULL,       NO,     DB_INDEXED,         DB_FIELD_TYPE_VARCHAR,             32,    0,NULL,NULL,2},
    {"outgoing_linkset",    NULL,       NO,     DB_INDEXED,         DB_FIELD_TYPE_VARCHAR,             32,    0,NULL,NULL,2},
    {"opc",                 NULL,       NO,     DB_INDEXED,         DB_FIELD_TYPE_INTEGER,             0,     0,NULL,NULL,2},
    {"dpc",                 NULL,       NO,     DB_INDEXED,         DB_FIELD_TYPE_INTEGER,             0,     0,NULL,NULL,2},
    {"si",                  NULL,       NO,     DB_INDEXED,         DB_FIELD_TYPE_INTEGER,             0,     0,NULL,NULL,2},
    {"msu_count",           NULL,       NO,     DB_INDEXED,         DB_FIELD_TYPE_INTEGER,             0,     0,NULL,NULL,2},
    {"bytes_count",         NULL,       NO,     DB_INDEXED,         DB_FIELD_TYPE_INTEGER,             0,     0,NULL,NULL,2},
    { "",                   NULL,       NO,     DB_NOT_INDEXED,     DB_FIELD_TYPE_END,                 0,     0,NULL,NULL,0},
};

@implementation UMMTP3StatisticDb

- (UMMTP3StatisticDb *)initWithPoolName:(NSString *)poolName
                              tableName:(NSString *)table
                             appContext:(id<UMLayerMTP3ApplicationContextProtocol>)appContext
                             autocreate:(BOOL)autocreate
                               instance:(NSString *)instance
{
    @autoreleasepool
    {
        self = [super init];
        if(self)
        {
            NSDictionary *config =@{   @"enable"     : @(YES),
                                       @"table-name" : table,
                                       @"autocreate" : @(autocreate),
                                       @"pool-name"  : poolName };
            _poolName = poolName;
            _pool = [appContext dbPools][_poolName];
            _table = [[UMDbTable alloc]initWithConfig:config andPools:[appContext dbPools]];
            _lock = [[UMMutex alloc]initWithName:@"UMMTP3StatisticDb-lock"];
            _entries = [[UMSynchronizedDictionary alloc]init];
            _instance = instance;
            
            NSTimeZone *tz = [NSTimeZone timeZoneWithName:@"UTC"];
            _ymdhDateFormatter= [[NSDateFormatter alloc]init];
            NSLocale *ukLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"];
            [_ymdhDateFormatter setLocale:ukLocale];
            [_ymdhDateFormatter setDateFormat:@"yyyyMMddHH"];
            [_ymdhDateFormatter setTimeZone:tz];
        }
        return self;
    }
}

- (void)doAutocreate
{
    if(_pool==NULL)
    {
        _pool = _table.pools[_poolName];
    }
    UMDbSession *session = [_pool grabSession:__FILE__ line:__LINE__ func:__func__];
    [_table autoCreate:UMMTP3StatisticDb_fields session:session];
    [_pool returnSession:session file:__FILE__ line:__LINE__ func:__func__];
}

- (void)addByteCount:(int)byteCount
     incomingLinkset:(NSString *)incomingLinkset
     outgoingLinkset:(NSString *)outgoingLinkset
                 opc:(int)opc
                 dpc:(int)dpc
                  si:(int)si
{
#if defined(UMMTP3_STATISTICS_DEBUG)
    NSLog(@"UMMTP3_STATISTICS_DEBUG: addByteCount:%d\n"
          @"                      incomingLinkset:%@\n"
          @"                      outgoingLinkset:%@\n"
          @"                                  opc:%d\n"
          @"                                  dpc:%d\n"
          @"                                   si:%d\n"
          ,byteCount,incomingLinkset,outgoingLinkset,opc,dpc,si);
#endif

    @autoreleasepool
    {
#if defined(UMMTP3_STATISTICS_DEBUG)
        NSDate *d = [NSDate date];
        NSLog(@"UMMTP3_STATISTICS_DEBUG: d:%@",d);
#endif

        NSString *ymdh = [_ymdhDateFormatter stringFromDate:d];
#if defined(UMMTP3_STATISTICS_DEBUG)
        NSLog(@"UMMTP3_STATISTICS_DEBUG: ymdh:%@",ymdh);
#endif

        NSString *key = [UMMTP3StatisticDbRecord keystringFor:ymdh
                                              incomingLinkset:incomingLinkset
                                              outgoingLinkset:outgoingLinkset
                                                          opc:opc
                                                          dpc:dpc
                                                           si:si
                                                     instance:_instance];
        
#if defined(UMMTP3_STATISTICS_DEBUG)
        NSLog(@"UMMTP3_STATISTICS_DEBUG: key:%@\n"
              @"                        ymdh:%@",key,ymdh);
#endif


        [_lock lock];
        UMMTP3StatisticDbRecord *rec = _entries[key];
        if(rec == NULL)
        {
            NSLog(@"UMMTP3_STATISTICS_DEBUG: creating new record");

            rec = [[UMMTP3StatisticDbRecord alloc]init];
            rec.ymdh = ymdh;
            rec.incoming_linkset = incomingLinkset;
            rec.outgoing_linkset = outgoingLinkset;
            rec.opc = opc;
            rec.dpc = dpc;
            rec.si = si;
            rec.instance = _instance;
            _entries[key] = rec;
        }
#if defined(UMMTP3_STATISTICS_DEBUG)
        else
        {
            NSLog(@"UMMTP3_STATISTICS_DEBUG: using existing record");
        }
#endif
        [_lock unlock];
        [rec increaseMsuCount:1 byteCount:byteCount];
    }
}

- (void)flush
{
    @autoreleasepool
    {
#if defined(UMMTP3_STATISTICS_DEBUG)
    NSLog(@"UMMTP3_STATISTICS_DEBUG: flush");
#endif
        [_lock lock];
        UMSynchronizedDictionary *tmp = _entries;
        _entries = [[UMSynchronizedDictionary alloc]init];
        [_lock unlock];
        
        NSArray *keys = [tmp allKeys];
        for(NSString *key in keys)
        {
            UMMTP3StatisticDbRecord *rec = tmp[key];
            [rec flushToPool:_pool table:_table];
        }
    }
}
@end
