//
//  UMMTP3StatisticDbRecord.h
//  ulibmtp3
//
//  Created by Andreas Fink on 01.06.20.
//  Copyright © 2020 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/ulib.h>

@interface UMMTP3StatisticDbRecord : UMObject
{
    NSString *_ymdh;
    NSString *_instance;
    NSString *_incoming_linkset;
    NSString *_outgoing_linkset;
    int     _opc;
    int     _dpc;
    int     _si;
    int     _msu_count;
    int     _bytes_count;
    UMMutex *_statisticDbRecordLock;
}

@property(readwrite,strong,atomic)  NSString *ymdh;
@property(readwrite,strong,atomic)  NSString *instance;
@property(readwrite,strong,atomic)  NSString *incoming_linkset;
@property(readwrite,strong,atomic)  NSString *outgoing_linkset;
@property(readwrite,assign,atomic)  int     opc;
@property(readwrite,assign,atomic)  int     dpc;
@property(readwrite,assign,atomic)  int     si;
@property(readwrite,assign,atomic)  int     msu_count;
@property(readwrite,assign,atomic)  int     bytes_count;


- (NSString *)keystring;
+ (NSString *)keystringFor:(NSString *)ymdh
           incomingLinkset:(NSString *)incomingLinkset
           outgoingLinkset:(NSString *)outgoingLinkset
                       opc:(int)opc
                       dpc:(int)dpc
                        si:(int)si
                  instance:(NSString *)instance;

- (void)increaseMsuCount:(int)msuCount byteCount:(int)byteCount;
- (void)flushToPool:(UMDbPool *)pool table:(UMDbTable *)table;

//- (BOOL)insertIntoDb:(UMDbPool *)pool table:(UMDbTable *)dbt; /* returns YES on success */
//- (BOOL)updateDb:(UMDbPool *)pool table:(UMDbTable *)dbt /* returns YES on success */

@end
