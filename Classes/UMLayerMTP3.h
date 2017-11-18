//
//  UMLayerMTP3.h
//  ulibmtp3
//
//  Created by Andreas Fink on 04/12/14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import <ulib/ulib.h>
#import <ulibsctp/ulibsctp.h>
#import <ulibm2pa/ulibm2pa.h>

#import "UMMTP3Variant.h"
#import "UMLayerMTP3ApplicationContextProtocol.h"

@class UMMTP3LinkSet;
@class UMMTP3Link;
@class UMMTP3Route;
@class UMMTP3PointCode;
@class UMMTP3Task_m2paStatusIndication;
@class UMMTP3Task_m2paSctpStatusIndication;
@class UMMTP3Task_m2paDataIndication;
@class UMMTP3Task_m2paCongestion;
@class UMMTP3Task_m2paCongestionCleared;
@class UMMTP3Task_m2paProcessorOutage;
@class UMMTP3Task_m2paProcessorRestored;
@class UMMTP3Task_m2paSpeedLimitReached;
@class UMMTP3Task_m2paSpeedLimitReachedCleared;
@class UMMTP3Task_adminAttachOrder;
@class UMMTP3Task_adminCreateLinkset;
@class UMMTP3Task_adminCreateLink;
@class UMMTP3Label;
@class UMMTP3RoutingTable;
@class UMM3UAApplicationServer;
@class UMMTP3InstanceRoutingTable;

#import "UMLayerMTP3UserProtocol.h"
typedef enum UMMTP3_Error
{
    UMMTP3_no_error = 0,
    UMMTP3_error_pdu_too_big = 1,
    UMMTP3_error_no_route_to_destination = 2,
    UMMTP3_error_invalid_variant = 3,
} UMMTP3_Error;

@interface UMLayerMTP3 : UMLayer<UMLayerM2PAUserProtocol>
{
    UMSynchronizedSortedDictionary  *linksets;
    UMMutex                         *_linksetLock;
    UMMTP3Variant                   variant;
    int                             networkIndicator;
    UMMTP3PointCode                 *opc;
    UMMTP3InstanceRoutingTable      *routingTable;
    UMSynchronizedSortedDictionary  *userPart;
    UMMTP3Route *defaultRoute;
    BOOL ready; /* currently a quick & dirty flag to wait for at startup. set by TRA */
}
@property (readwrite,assign)    int                 networkIndicator;
@property (readwrite,assign)    UMMTP3Variant       variant;
@property (readwrite,strong)    UMMTP3PointCode     *opc;
@property (readwrite,strong)    UMMTP3Route         *defaultRoute;
@property (readwrite,assign)    BOOL                ready;

- (UMLayerMTP3 *)initWithTaskQueueMulti:(UMTaskQueueMulti *)tq;


#pragma mark -
#pragma mark Sending from Layer 3


- (UMMTP3Route *)findRouteForDestination:(UMMTP3PointCode *)dpc;

/* Layer3 access methods */


- (UMMTP3_Error)sendPDU:(NSData *)pdu
                    opc:(UMMTP3PointCode *)fopc
                    dpc:(UMMTP3PointCode *)fdpc
                     si:(int)si
                     mp:(int)mp;
- (UMMTP3_Error)forwardPDU:(NSData *)pdu
                       opc:(UMMTP3PointCode *)fopc
                       dpc:(UMMTP3PointCode *)fdpc
                        si:(int)si
                        mp:(int)mp
                     route:(UMMTP3Route *)route;

#pragma mark -
#pragma mark Linkset Handling

- (void)addLinkset:(UMMTP3LinkSet *)ls;
- (void)removeLinkset:(UMMTP3LinkSet *)ls;
- (void)removeLinksetByName:(NSString *)n;
- (void)removeAllLinksets;
- (UMMTP3LinkSet *)getLinksetByName:(NSString *)name;
- (UMMTP3Link *)getLinkByName:(id)userId;

#pragma mark -
#pragma mark M2PA callbacks

- (void) adminAttachConfirm:(UMLayer *)attachedLayer
                        slc:(int)slc
                     userId:(id)uid;

- (void) adminAttachFail:(UMLayer *)attachedLayer
                     slc:(int)slc
                  userId:(id)uid
                  reason:(NSString *)r;

- (void)adminAttachOrder:(UMLayerM2PA *)m2pa_layer
                     slc:(int)slc
                 linkset:(NSString *)linkset;


- (void) adminCreateLinkset:(NSString *)linkset;
- (void) adminCreateLink:(NSString *)name
                     slc:(int)slc
                    link:(NSString *)link;

- (void) sentAckConfirmFrom:(UMLayer *)sender
                   userInfo:(NSDictionary *)userInfo;
- (void) sentAckFailureFrom:(UMLayer *)sender
                   userInfo:(NSDictionary *)userInfo
                      error:(NSString *)err
                     reason:(NSString *)reason
                  errorInfo:(NSDictionary *)ei;

- (void) m2paStatusIndication:(UMLayer *)caller
                          slc:(int)xslc
                       userId:(id)uid
                       status:(M2PA_Status)s;

- (void) m2paSctpStatusIndication:(UMLayer *)caller
                              slc:(int)xslc
                           userId:(id)uid
                           status:(SCTP_Status)s;

- (void) m2paDataIndication:(UMLayer *)caller
                        slc:(int)xslc
                     userId:(id)ui
                       data:(NSData *)d;

- (void) m2paCongestion:(UMLayer *)caller
                    slc:(int)xslc
                 userId:(id)ui;

- (void) m2paCongestionCleared:(UMLayer *)caller
                           slc:(int)xslc
                        userId:(id)ui;

- (void) m2paProcessorOutage:(UMLayer *)caller
                         slc:(int)xslc
                      userId:(id)ui;

- (void) m2paProcessorRestored:(UMLayer *)caller
                           slc:(int)xslc
                        userId:(id)ui;

- (void) m2paSpeedLimitReached:(UMLayer *)caller
                           slc:(int)xslc
                        userId:(id)ui;
- (void) m2paSpeedLimitReachedCleared:(UMLayer *)caller
                                  slc:(int)xslc
                               userId:(id)ui;

- (void) m3uaCongestion:(UMM3UAApplicationServer *)m3ualink
      affectedPointCode:(UMMTP3PointCode *)pc
                   mask:(uint32_t)mask
      networkAppearance:(uint32_t)network_appearance
     concernedPointcode:(UMMTP3PointCode *)concernedPc
    congestionIndicator:(uint32_t)congestionIndicator;

- (void) m3uaCongestionCleared:(UMM3UAApplicationServer *)m3ualink
      affectedPointCode:(UMMTP3PointCode *)pc
                   mask:(uint32_t)mask
      networkAppearance:(uint32_t)network_appearance
     concernedPointcode:(UMMTP3PointCode *)concernedPc
    congestionIndicator:(uint32_t)congestionIndicator;

#pragma mark -


- (void) _adminCreateLinksetTask:(UMMTP3Task_adminCreateLinkset *)linkset;
- (void) _adminCreateLinkTask:(UMMTP3Task_adminCreateLink *)task;

- (void) _adminAttachOrderTask:(UMMTP3Task_adminAttachOrder *)task;
- (void) _m2paStatusIndicationTask:(UMMTP3Task_m2paStatusIndication *)task;
- (void) _m2paSctpStatusIndicationTask:(UMMTP3Task_m2paSctpStatusIndication *)task;
- (void) _m2paDataIndicationTask:(UMMTP3Task_m2paDataIndication *)task;
- (void) _m2paCongestionTask:(UMMTP3Task_m2paCongestion*)task;
- (void) _m2paCongestionClearedTask:(UMMTP3Task_m2paCongestionCleared *)task;
- (void) _m2paProcessorOutageTask:(UMMTP3Task_m2paProcessorOutage *)task;
- (void) _m2paProcessorRestoredTask:(UMMTP3Task_m2paProcessorRestored *)task;
- (void) _m2paSpeedLimitReachedTask:(UMMTP3Task_m2paSpeedLimitReached *)task;
- (void) _m2paSpeedLimitReachedClearedTask:(UMMTP3Task_m2paSpeedLimitReachedCleared *)task;

- (void)processIncomingPdu:(UMMTP3Label *)label
                      data:(NSData *)data
                userpartId:(int)upid
                        ni:(int)ni
                        mp:(int)mp
               linksetName:(NSString *)linksetName;

- (void)processIncomingPduForward:(UMMTP3Label *)label
                             data:(NSData *)data
                       userpartId:(int)upid
                               ni:(int)ni
                               mp:(int)mp
                      linksetName:(NSString *)linksetName;


- (void)processIncomingPduLocal:(UMMTP3Label *)label
                           data:(NSData *)data
                     userpartId:(int)upid
                             ni:(int)ni
                             mp:(int)mp
                    linksetName:(NSString *)linksetName;

- (void)processUserPart:(UMMTP3Label *)label
                   data:(NSData *)data
             userpartId:(int)upid
                     ni:(int)ni
                     mp:(int)mp
            linksetName:(NSString *)linksetName;


#pragma mark -
#pragma mark Config Management


- (void)setConfig:(NSDictionary *)cfg applicationContext:(id<UMLayerMTP3ApplicationContextProtocol>)appContext;
- (NSDictionary *)config;
- (void)start;
- (void)stop;
- (void)_start;
- (void)_stop;

- (void)setUserPart:(int)upid user:(id<UMLayerMTP3UserProtocol>)user;
- (int)maxPduSize;


- (void)updateRouteAvailable:(UMMTP3PointCode *)pc mask:(int)mask linksetName:(NSString *)name;
- (void)updateRouteRestricted:(UMMTP3PointCode *)pc mask:(int)mask linksetName:(NSString *)name;
- (void)updateRouteUnavailable:(UMMTP3PointCode *)pc mask:(int)mask linksetName:(NSString *)name;
- (UMMTP3RoutingTable *)routingTable;

@end
