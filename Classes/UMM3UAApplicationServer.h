//
//  UMM3UAApplicatoinServer.h
//  ulibmtp3
//
//  Created by Andreas Fink on 25.11.16.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/ulib.h>
#import <ulibsctp/ulibsctp.h>


#import "UMMTP3LinkSet.h"
#import "UMM3UATrafficMode.h"
#import "UMM3UAStatus.h"
#import "UMMTP3RouteStatus.h"
#import "UMM3UAApplicationServerMode.h"

#import "UMLayerMTP3ApplicationContextProtocol.h"
/* note: a M3UA "link" is the same as what in traditional SS7 is called a linkset */
/* it corresponds to an association of two MTP nodes */
/* while a traditional linkset has multiple physical links separated with SLC's */
/* this is not necessary in M3UA. So think of UMM3UALink as a linkset with */
/* a fixed prebuiltin link with SLC = 0*/

#define	M3UA_DEFAULT_REOPEN1_TIMER	   6.000	/* reopen SCTP link after 6 seconds of being down */
#define	M3UA_DEFAULT_REOPEN2_TIMER	 120.000	/* once reopen order has been given, wait up to 2 minutes
for the link to be in ALIGNED_READY, if not, power it down again, wait Reopen1 timer and power it on again */
#define	M3UA_DEFAULT_LINKTEST_TIMER	25.000 /* every so many seconds we send out a SLTM */
#define M3UA_DEFAULT_SPEED      100;        /* default speed limit */

@interface UMM3UAApplicationServer : UMMTP3LinkSet
{
    /* config params */
    UMM3UATrafficMode   _trafficMode;
    NSNumber			*_routingContext;
    NSNumber            *_networkAppearance;
    UMM3UA_Status       _m3ua_status;
    UMSynchronizedSortedDictionary *_applicationServerProcesses;
    int                 upCount;
    int                 activeCount;
    BOOL                _useRoutingKey;
    BOOL                _send_aspup;
    BOOL                _send_aspac;
    UMM3UAApplicationServerMode _mode;
}

@property(readwrite,assign,atomic)  UMM3UA_Status       m3ua_status;
@property(readwrite,assign,atomic)  UMM3UATrafficMode   trafficMode;
@property(readwrite,strong,atomic)  NSNumber			*routingContext;
@property(readwrite,strong,atomic)  NSNumber            *networkAppearance;
@property(readwrite,assign,atomic)  BOOL send_aspup;
@property(readwrite,assign,atomic)  BOOL send_aspac;
@property(readwrite,assign,atomic)  UMM3UAApplicationServerMode mode;

/* UMSCTP callbacks */
- (NSString *)layerName;
- (NSArray <NSString *>*)aspNames;


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

- (void) addAsp:(UMM3UAApplicationServerProcess *)asp;

- (void)setConfig:(NSDictionary *)cfg applicationContext:(id<UMLayerMTP3ApplicationContextProtocol>)appContext;

- (void)m3uaCongestion:(UMM3UAApplicationServerProcess *)asp
     affectedPointCode:(UMMTP3PointCode *)pc
                  mask:(uint32_t)mask
     networkAppearance:(uint32_t)network_appearance
    concernedPointcode:(UMMTP3PointCode *)concernedPc
   congestionIndicator:(uint32_t)congestionIndicator;


- (void)updateRouteAvailable:(UMMTP3PointCode *)pc
                        mask:(int)mask
                      forAsp:(UMM3UAApplicationServerProcess *)asp
                    priority:(UMMTP3RoutePriority)prio
                      reason:(NSString *)reason;

- (void)updateRouteUnavailable:(UMMTP3PointCode *)pc
                          mask:(int)mask
                        forAsp:(UMM3UAApplicationServerProcess *)asp
                      priority:(UMMTP3RoutePriority)prio
                        reason:(NSString *)reason;

- (void)updateRouteRestricted:(UMMTP3PointCode *)pc
                         mask:(int)mask
                       forAsp:(UMM3UAApplicationServerProcess *)asp
                     priority:(UMMTP3RoutePriority)prio
                       reason:(NSString *)reason;


- (void)advertizePointcodeAvailable:(UMMTP3PointCode *)pc mask:(int)mask;
- (void)advertizePointcodeRestricted:(UMMTP3PointCode *)pc mask:(int)mask;
- (void)advertizePointcodeUnavailable:(UMMTP3PointCode *)pc mask:(int)mask;

- (void)aspUp:(UMM3UAApplicationServerProcess *)asp  reason:(NSString *)reason;
- (void)aspDown:(UMM3UAApplicationServerProcess *)asp  reason:(NSString *)reason;
- (void)aspActive:(UMM3UAApplicationServerProcess *)asp  reason:(NSString *)reason;
- (void)aspInactive:(UMM3UAApplicationServerProcess *)asp reason:(NSString *)reason;
- (void)aspPending:(UMM3UAApplicationServerProcess *)asp reason:(NSString *)reason;
- (void)powerOn;
- (void)powerOff;


-(void)sendPdu:(NSData *)data
         label:(UMMTP3Label *)label
       heading:(int)heading
            ni:(int)ni
            mp:(int)mp
            si:(int)si
    ackRequest:(NSDictionary *)ackRequest
 correlationId:(uint32_t)correlation_id
       options:(NSDictionary *)options;

-(UMMTP3RouteStatus)isRouteAvailable:(UMMTP3PointCode *)pc
                                mask:(int)mask
                              forAsp:(UMM3UAApplicationServerProcess *)asp;
- (NSString *)statusString;

- (UMSynchronizedSortedDictionary *)m3uaStatusDict;

- (void)activate;
- (void)deactivate;
+ (NSString *)statusString:(UMM3UA_Status)value;

@end
