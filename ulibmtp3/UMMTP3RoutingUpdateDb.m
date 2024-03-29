//
//  UMMTP3RoutingUpdateDb.m
//  ulibmtp3
//
//  Created by Andreas Fink on 13.04.23.
//  Copyright © 2023 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMMTP3RoutingUpdateDb.h"
#import "UMMTP3RoutingUpdateDbRecord.h"

@implementation UMMTP3RoutingUpdateDb


static dbFieldDef UMMTP3RoutingUpdateDb_fields[] =
{
    {"dbkey",               "AUTO_INCREMENT",       NO,     DB_PRIMARY_INDEX,   DB_FIELD_TYPE_INTEGER,             255,   0,NULL,NULL,1},
    {"timestamp",           NULL,                   NO,     DB_INDEXED,         DB_FIELD_TYPE_VARCHAR,             32,    0,NULL,NULL,2},
    {"instance",            NULL,                   NO,     DB_INDEXED,         DB_FIELD_TYPE_VARCHAR,             255,   0,NULL,NULL,2},
    {"inbound_linkset",     NULL,                   NO,     DB_INDEXED,         DB_FIELD_TYPE_VARCHAR,             255,   0,NULL,NULL,2},
    {"outbound_linkset",    NULL,                   NO,     DB_INDEXED,         DB_FIELD_TYPE_VARCHAR,             255,   0,NULL,NULL,2},
    {"dpc",                 NULL,                   NO,     DB_INDEXED,         DB_FIELD_TYPE_VARCHAR,             255,   0,NULL,NULL,2},
    {"status",              NULL,                   NO,     DB_NOT_INDEXED,     DB_FIELD_TYPE_VARCHAR,             255,   0,NULL,NULL,2},
    {"reason",              NULL,                   NO,     DB_NOT_INDEXED,     DB_FIELD_TYPE_VARCHAR,             255,   0,NULL,NULL,2},
    { "",                   NULL,                   NO,     DB_NOT_INDEXED,     DB_FIELD_TYPE_END,                 0,     0,NULL,NULL,0},
};

 
- (UMMTP3RoutingUpdateDb *)initWithPoolName:(NSString *)poolName
                                  tableName:(NSString *)table
                                 appContext:(id<UMLayerMTP3ApplicationContextProtocol>)appContext
                                 autocreate:(BOOL)autocreate
                                   instance:(NSString *)instance
{
    @autoreleasepool
    {
        self = [super initWithName:@"UMMTP3RoutingUpdateDb" workSleeper:NULL];
        if(self)
        {
            NSDictionary *config =@{   @"enable"     : @(YES),
                                       @"table-name" : table,
                                       @"autocreate" : @(autocreate),
                                       @"pool-name"  : poolName };
            _poolName = poolName;
            _pool = [appContext dbPools][_poolName];
            _appContext = appContext;
            _table = [[UMDbTable alloc]initWithConfig:config andPools:[appContext dbPools]];
            _instance = instance;
            _recordsToBeInserted = [[UMSynchronizedArray alloc]init];
        }
        return self;
    }
}

- (void)doAutocreate
{
    if(_table.pools == NULL)
    {
        _table.pools = [_appContext dbPools];
    }
    if(_pool==NULL)
    {
        _pool = _table.pools[_poolName];
    }
    UMDbSession *session = [_pool grabSession:__FILE__ line:__LINE__ func:__func__];
    [_table autoCreate:UMMTP3RoutingUpdateDb_fields session:session];
    [_pool returnSession:session file:__FILE__ line:__LINE__ func:__func__];
}

- (void)logInboundLinkset:(NSString *)inboundLinkset
          outboundLinkset:(NSString *)outboundLinkset
                      dpc:(UMMTP3PointCode *)dpc
                   status:(NSString *)status
                   reason:(NSString *)reason  /* returns YES on success */
{
    UMMTP3RoutingUpdateDbRecord *r = [[UMMTP3RoutingUpdateDbRecord alloc]init];
    r.instance = _instance;
    r.inboundLinkset = inboundLinkset;
    r.outboundLinkset = outboundLinkset;
    r.dpc = dpc;
    r.status = status;
    r.reason = reason;
    [_recordsToBeInserted addObject:r];
    [_workSleeper wakeUp];
}

- (int)work
{
    int i = 0;
    UMMTP3RoutingUpdateDbRecord *r  = NULL;
    do
    {
        r = [_recordsToBeInserted removeFirst];
        if(r)
        {
            i++;
            [r insertIntoDb:_pool table:_table];
        }
    } while(r);
    return i;
}

@end
