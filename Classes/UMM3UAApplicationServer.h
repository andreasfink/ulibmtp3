//
//  UMM3UALink.h
//  ulibmtp3
//
//  Created by Andreas Fink on 25.11.16.
//  Copyright © 2016 Andreas Fink. All rights reserved.
//

#import <ulib/ulib.h>
#import <ulibsctp/ulibsctp.h>


#import "UMMTP3LinkSet.h"
#import "UMM3UATrafficMode.h"
#import "UMM3UAStatus.h"
#import "UMLayerMTP3ApplicationContextProtocol.h"
/* note: a M3UA "link" is the same as what in traditional SS7 is called a linkset */
/* it corresponds to an association of two MTP nodes */
/* while a traditional linkset has multiple physical links separated with SLC's */
/* this is not necessary in M3UA. So think of UMM3UALink as a linkset with */
/* a fixed prebuiltin link with SLC = 0*/

#define	M3UA_DEFAULT_REOPEN1_TIMER	  3.000	/* reopen SCTP link after 3 seconds of being down */
#define	M3UA_DEFAULT_REOPEN2_TIMER	120.000	/* once reopen order has been given, wait up to 2 minutes
for the link to be in ALIGNED_READY, if not, power it down again, wait Reopen1 timer and power it on again */
#define	M3UA_DEFAULT_LINKTEST_TIMER	25-000 /* every so many miliseconds we send out a SLTM */
#define M3UA_DEFAULT_SPEED      100;        /* default speed limit */

@interface UMM3UAApplicationServer : UMMTP3LinkSet<UMLayerSctpUserProtocol>
{
    /* config params */
    UMM3UATrafficMode   trafficMode;
    NSInteger			routingKey;
    NSInteger           networkAppearance;
    UMM3UA_Status       m3ua_status;
    UMSynchronizedSortedDictionary *applicationServerProcesses;
}

@property(readwrite,assign,atomic)  UMM3UA_Status       m3ua_status;
@property(readwrite,assign,atomic)  UMM3UATrafficMode   trafficMode;


/* UMSCTP callbacks */
- (NSString *)layerName;

- (void) sctpStatusIndication:(UMLayer *)caller
                       userId:(id)uid
                       status:(SCTP_Status)s;

- (void) sctpDataIndication:(UMLayer *)caller
                     userId:(id)uid
                   streamId:(uint16_t)sid
                 protocolId:(uint32_t)pid
                       data:(NSData *)d;

- (void) sctpMonitorIndication:(UMLayer *)caller
                        userId:(id)uid
                      streamId:(uint16_t)sid
                    protocolId:(uint32_t)pid
                          data:(NSData *)d
                      incoming:(BOOL)in;

- (void) adminAttachConfirm:(UMLayer *)attachedLayer
                     userId:(id)uid;

- (void) adminAttachFail:(UMLayer *)attachedLayer
                  userId:(id)uid
                  reason:(NSString *)reason;

- (void) adminDetachConfirm:(UMLayer *)attachedLayer
                     userId:(id)uid;

- (void) adminDetachFail:(UMLayer *)attachedLayer
                  userId:(id)uid
                  reason:(NSString *)reason;

- (void)sentAckConfirmFrom:(UMLayer *)sender
                  userInfo:(NSDictionary *)userInfo;

- (void)sentAckFailureFrom:(UMLayer *)sender
                  userInfo:(NSDictionary *)userInfo
                     error:(NSString *)err
                    reason:(NSString *)reason
                 errorInfo:(NSDictionary *)ei;

- (void) addAsp:(UMM3UAApplicationServerProcess *)asp;

- (void)setDefaultValues;
- (void)setDefaultValuesFromMTP3;
- (void)setConfig:(NSDictionary *)cfg applicationContext:(id<UMLayerMTP3ApplicationContextProtocol>)appContext;

- (void)m3uaCongestion:(UMM3UAApplicationServerProcess *)asp
     affectedPointCode:(UMMTP3PointCode *)pc
                  mask:(int)mask
     networkAppearance:(int)network_appearance
    concernedPointcode:(UMMTP3PointCode *)concernedPc
   congestionIndicator:(int)congestionIndicator;

- (void)start;
- (void)stop;

@end
