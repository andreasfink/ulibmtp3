//
//  UMMTP3StatisticDb.h
//  ulibmtp3
//
//  Created by Andreas Fink on 01.06.20.
//  Copyright © 2020 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/ulib.h>
#import <ulibdb/ulibdb.h>
#import "UMLayerMTP3ApplicationContextProtocol.h"

@interface UMMTP3StatisticDb : UMObject
{
    UMDbPool *_pool;
    UMDbTable *_table;
    UMMutex *_statisticDbLock;
    UMSynchronizedDictionary *_entries;
    NSDateFormatter *_ymdhDateFormatter;
    NSString *_instance;
    NSString *_poolName;
}

- (UMMTP3StatisticDb *)initWithPoolName:(NSString *)pool
                              tableName:(NSString *)table
                             appContext:(id<UMLayerMTP3ApplicationContextProtocol>)appContext
                             autocreate:(BOOL)autocreate
                               instance:(NSString *)instance;

- (void)addByteCount:(int)byteCount
     incomingLinkset:(NSString *)incomingLinkset
     outgoingLinkset:(NSString *)outgoingLinkset
                 opc:(int)opc
                 dpc:(int)dpc
                  si:(int)si;
- (void)doAutocreate;
- (void)flush;

@end

