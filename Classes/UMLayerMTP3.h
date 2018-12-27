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
@class UMMTP3Task_adminCreateLinkSet;
@class UMMTP3Task_adminCreateLink;
@class UMMTP3Label;
@class UMMTP3RoutingTable;
@class UMM3UAApplicationServer;
@class UMMTP3InstanceRoutingTable;
@class UMMTP3SyslogClient;

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
	UMSynchronizedSortedDictionary  *_linksets;
	UMSynchronizedSortedDictionary  *_links;
    UMMutex                         *_linksetLock;
    UMMTP3Variant                   _variant;
    int                             _networkIndicator;
    UMMTP3PointCode                 *_opc;
    UMMTP3InstanceRoutingTable      *_routingTable;
    UMSynchronizedSortedDictionary  *_userPart;
    UMMTP3Route                     *_defaultRoute;
    BOOL                            _ready; /* currently a quick & dirty flag to wait for at startup. set by TRA */
    UMMTP3SyslogClient              *_problematicPacketDumper;
    BOOL                            _stpMode;
}
@property (readwrite,assign,atomic) int                 networkIndicator;
@property (readwrite,assign,atomic) UMMTP3Variant       variant;
@property (readwrite,strong,atomic) UMMTP3PointCode     *opc;
@property (readwrite,strong,atomic) UMMTP3Route         *defaultRoute;
@property (readwrite,assign,atomic) BOOL                ready;
@property (readwrite,strong,atomic) UMMTP3SyslogClient  *problematicPacketDumper;
@property (readwrite,assign,atomic) BOOL                stpMode;
@property (readwrite,strong,atomic) UMMTP3RoutingTable  *routingTable;

- (UMLayerMTP3 *)initWithTaskQueueMulti:(UMTaskQueueMulti *)tq;


#pragma mark -
#pragma mark Sending from Layer 3


- (UMMTP3Route *)findRouteForDestination:(UMMTP3PointCode *)dpc;

/* Layer3 access methods */


- (UMMTP3_Error)sendPDU:(NSData *)pdu
                    opc:(UMMTP3PointCode *)fopc
                    dpc:(UMMTP3PointCode *)fdpc
                     si:(int)si
                     mp:(int)mp
                options:(NSDictionary *)options;

- (UMMTP3_Error)forwardPDU:(NSData *)pdu
                       opc:(UMMTP3PointCode *)fopc
                       dpc:(UMMTP3PointCode *)fdpc
                        si:(int)si
                        mp:(int)mp
                     route:(UMMTP3Route *)route
                   options:(NSDictionary *)options;


#pragma mark -
#pragma mark LinkSet Handling

- (void)addLinkSet:(UMMTP3LinkSet *)ls;
- (void)removeLinkSet:(UMMTP3LinkSet *)ls;
- (void)removeLinkSetByName:(NSString *)n;
- (void)removeAllLinkSets;
- (UMMTP3LinkSet *)getLinkSetByName:(NSString *)name;

- (void)addLink:(UMMTP3Link *)lnk;
- (void)removeLink:(UMMTP3Link *)lnk;

- (UMMTP3Link *)getLinkByName:(NSString *)linkName;

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
			 linkSetName:(NSString *)linkSetName
				linkName:(NSString *)linkName;


- (void) adminCreateLinkSet:(NSString *)linkset;
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
			   mtp3linkName:(NSString *)linkName
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


- (void) _adminCreateLinkSetTask:(UMMTP3Task_adminCreateLinkSet *)linkset;
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
- (NSDictionary *)apiStatus;

- (void)stopDetachAndDestroy;

- (UMMTP3PointCode *)adjacentPointCodeOfLinkSet:(NSString *)asname;

@end
