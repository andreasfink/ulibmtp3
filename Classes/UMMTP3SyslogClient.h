//
//  UMMTP3SyslogClient.h
//  ulibmtp3
//
//  Created by Andreas Fink on 29.11.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

/*
    This object is a destination to send decoding errors to.
    it will send it to a syslog destination in Cisco ITP style
    so wireshark can be used to capture it.
*/
#import <ulib/ulib.h>

@class UMMTP3PointCode;

@interface UMMTP3SyslogClient : UMObject
{
    UMSyslogClient *_syslogClient;
    long _seq;
    UMMutex *_lock;
}

@property(readwrite,strong) UMSyslogClient *syslogClient;
@property(readwrite,assign) int     defaultFacility;
@property(readwrite,assign) int     defaultSeverity;


- (void)logPacket:(NSData *)data
              opc:(UMMTP3PointCode *)opc
              dpc:(UMMTP3PointCode *)dpc
              sls:(int)sls
               ni:(int)ni
               si:(int)si;
- (void)logPacket:(NSData *)data
              opc:(UMMTP3PointCode *)opc
              dpc:(UMMTP3PointCode *)dpc
              sls:(int)sls
               ni:(int)ni
               si:(int)si
         severity:(int)severity;

- (void)logPacket:(NSData *)data
              opc:(UMMTP3PointCode *)opc
              dpc:(UMMTP3PointCode *)dpc
              sls:(int)sls
               ni:(int)ni
               si:(int)si
         severity:(int)severity
         facility:(int)facility;

- (void)logRawPacket:(NSData *)data;

- (void)logRawPacket:(NSData *)data
            severity:(int)severity
            facility:(int)facility;
@end
