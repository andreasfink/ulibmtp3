//
//  UMMTP3SyslogClient.m
//  ulibmtp3
//
//  Created by Andreas Fink on 29.11.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMMTP3SyslogClient.h"
#import "UMMTP3PointCode.h"
#import "UMMTP3Label.h"
#include <time.h>

@implementation UMMTP3SyslogClient

- (void)logPacket:(NSData *)data
              opc:(UMMTP3PointCode *)opc
              dpc:(UMMTP3PointCode *)dpc
              sls:(int)sls
               ni:(int)ni
               si:(int)si
{
    [self logPacket:data opc:opc
                dpc:dpc
                sls:sls
                 ni:ni
                 si:si
           severity:-1
           facility:-1];
}

- (void)logPacket:(NSData *)data
              opc:(UMMTP3PointCode *)opc
              dpc:(UMMTP3PointCode *)dpc
              sls:(int)sls
               ni:(int)ni
               si:(int)si
         severity:(int)severity
{
    [self logPacket:data opc:opc
                dpc:dpc
                sls:sls
                 ni:ni
                 si:si
           severity:severity
           facility:-1];
}

- (void)logPacket:(NSData *)data
              opc:(UMMTP3PointCode *)opc
              dpc:(UMMTP3PointCode *)dpc
              sls:(int)sls
               ni:(int)ni
               si:(int)si
         severity:(int)severity
         facility:(int)facility
{
    [_lock lock];
    _seq++;
    _seq = _seq % 100000000;

    UMMTP3Label *label = [[UMMTP3Label alloc]init];
    label.opc = opc;
    label.dpc = dpc;
    label.sls = sls;

    NSMutableData *data2 = [[NSMutableData alloc]init];
    int sio = ((ni & 0x03) << 6) | (si & 0x0F);
    [data2 appendByte:sio];
    [label appendToMutableData:data2];

    NSString *msgId = [NSString stringWithFormat:@"%08ld",_seq];
    NSString *msgString =  [NSString stringWithFormat:@"msu=%@",[data2 hexString]];
    [_syslogClient logMessageId:msgId
                        message:msgString
                       facility:facility
                       severity:severity];
    [_lock unlock];
}

- (void)logRawPacket:(NSData *)data
{
    [self logRawPacket:data
              severity:-1
              facility:-1];
}

- (void)logRawPacket:(NSData *)data
            severity:(int)severity
            facility:(int)facility
{
    [_lock lock];
    _seq++;
    _seq = _seq % 100000000;

    NSString *msgId = [NSString stringWithFormat:@"%08ld",_seq];
    NSString *msgString =  [NSString stringWithFormat:@"msu=%@",[data hexString]];
    [_syslogClient logMessageId:msgId
                        message:msgString
                       facility:facility
                       severity:severity];
    [_lock unlock];
}


@end
