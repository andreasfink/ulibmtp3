//
//  UMMTP3RoutingUpdateDb.h
//  ulibmtp3
//
//  Created by Andreas Fink on 13.04.23.
//  Copyright © 2023 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulibdb/ulibdb.h>
#import "UMLayerMTP3ApplicationContextProtocol.h"
#import "UMMTP3PointCode.h"

@interface UMMTP3RoutingUpdateDb : UMObject
{
    UMDbPool    *_pool;
    UMDbTable   *_table;
    NSString    *_instance;
    NSString    *_poolName;
    id<UMLayerMTP3ApplicationContextProtocol>   _appContext;
}

@property(readwrite,strong) UMDbPool    *pool;
@property(readwrite,strong) UMDbTable   *table;
@property(readwrite,strong) NSString    *instance;
@property(readwrite,strong) NSString    *poolName;

- (UMMTP3RoutingUpdateDb *)initWithPoolName:(NSString *)poolName
                                  tableName:(NSString *)table
                                 appContext:(id<UMLayerMTP3ApplicationContextProtocol>)appContext
                                 autocreate:(BOOL)autocreate
                                   instance:(NSString *)instance;

- (void)doAutocreate;

- (BOOL)logInboundLinkset:(NSString *)inboundLinkset
          outboundLinkset:(NSString *)outboundLinkset
                      dpc:(UMMTP3PointCode *)dpc
                   status:(NSString *)status
                   reason:(NSString *)reason;  /* returns YES on success */
@end
