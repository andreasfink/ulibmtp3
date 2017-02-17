//
//  UMMTP3LinkSet.h
//  ulibmtp3
//
//  Created by Andreas Fink on 04/12/14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import <ulib/ulib.h>
#import <ulibm2pa/ulibm2pa.h>
#import "UMMTP3Variant.h"
#import "UMMTP3TransitPermission.h"
#import "UMLayerMTP3ApplicationContextProtocol.h"

@class UMMTP3Link;
@class UMLayerMTP3;
@class UMMTP3Label;
@class UMMTP3PointCode;
@class UMMTP3WhiteList;
@class UMMTP3BlackList;
@class UMMTP3RoutingTable;
@class UMMTP3LinkRoutingTable;

@interface UMMTP3LinkSet : UMObject
{
    UMLayerMTP3 __weak          *mtp3;
    NSString                    *name;
    UMSynchronizedSortedDictionary *links;
    UMLogLevel                  logLevel;
    UMMTP3Variant               variant;
    UMMTP3PointCode             *localPointCode;
    UMMTP3PointCode             *adjacentPointCode;
    int                         networkIndicator;
    int                         linkSelector;
    unsigned long               nationalOptions;
    UMMTP3WhiteList             *incomingWhiteList;
    UMMTP3BlackList             *incomingBlackList;
    UMMTP3LinkRoutingTable      *routingTable;
    int                         tra_sent;
    int                         trw_received;
    BOOL                        sendTRA;
    int                         activeLinks;
    int                         inactiveLinks;
    int                         readyLinks;
    int                         totalLinks;
    int                         congestionLevel;
    double                      speed;
    int                         last_sls;
}

@property(readwrite,assign) int congestionLevel;
@property(readwrite,strong) UMLogFeed   *log;
@property(readwrite,assign) UMLogLevel logLevel;
@property(readwrite,strong) NSString *name;
@property(readwrite,strong) UMSynchronizedSortedDictionary *links;
@property(readwrite,weak)   UMLayerMTP3 *mtp3;
@property(readwrite,assign) UMMTP3Variant variant;
@property(readwrite,strong) UMMTP3PointCode *localPointCode;
@property(readwrite,strong) UMMTP3PointCode *adjacentPointCode;
@property(readwrite,assign) int networkIndicator;
@property(readwrite,strong) UMMTP3WhiteList *incomingWhiteList;
@property(readwrite,strong) UMMTP3BlackList *incomingBlackList;
@property(readwrite,strong) UMMTP3RoutingTable *routingTable;

@property(readonly,assign) int activeLinks;
@property(readonly,assign) int inactiveLinks;
@property(readonly,assign) int readyLinks;
@property(readonly,assign) int totalLinks;


- (void)addLink:(UMMTP3Link *)lnk;
- (void)removeLink:(UMMTP3Link *)lnk;
- (void)removeLinkByName:(NSString *)n;
- (void)removeAllLinks;
- (UMMTP3Link *)getLinkByName:(NSString *)n;
- (UMMTP3Link *)getAnyLink;

- (void)logDebug:(NSString *)s;
- (void)logWarning:(NSString *)s;
- (void)logInfo:(NSString *)s;
- (void) logPanic:(NSString *)s;
- (void)logMajorError:(NSString *)s;
- (void)logMinorError:(NSString *)s;

/* these are called from the link */
- (void)dataIndication:(NSData *)dataIn slc:(int)slc;
- (UMMTP3TransitPermission_result)screenIncomingLabel:(UMMTP3Label *)label error:(NSError **)err;

/* pass slc from the PDU in the link, not the one assigned in the linkset */
- (void)processSLTM:(UMMTP3Label *)label
            pattern:(NSData *)pattern
                 ni:(int)ni
                 mp:(int)mp
                slc:(int)slc
               link:(UMMTP3Link *)link;

- (void)processSLTA:(UMMTP3Label *)label
            pattern:(NSData *)pattern
                 ni:(int)ni
                 mp:(int)mp
                slc:(int)slc
               link:(UMMTP3Link *)link;
- (void)processSSLTM:(UMMTP3Label *)label
             pattern:(NSData *)pattern
                  ni:(int)ni
                  mp:(int)mp
                 slc:(int)slc
                link:(UMMTP3Link *)link;

- (void)processSSLTA:(UMMTP3Label *)label
             pattern:(NSData *)pattern
                  ni:(int)ni
                  mp:(int)mp
                 slc:(int)slc
                link:(UMMTP3Link *)link;

/* Group CHM */
- (void)processCOO:(UMMTP3Label *)label lastFSN:(int)fsn ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)processCOA:(UMMTP3Label *)label lastFSN:(int)fsn ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)processCBD:(UMMTP3Label *)label changeBackCode:(int)cbc ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)processCBA:(UMMTP3Label *)label changeBackCode:(int)cbc ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
/* Group ECM */
- (void)processECO:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)processECA:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
/* Group FCM */
- (void)processRCT:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link; /* national option */
- (void)processTFC:(UMMTP3Label *)label destination:(UMMTP3PointCode *)pc status:(int)status ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
/* Group TFM */
- (void)processTFP:(UMMTP3Label *)label destination:(UMMTP3PointCode *)pc ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)processTFR:(UMMTP3Label *)label destination:(UMMTP3PointCode *)pc ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)processTFA:(UMMTP3Label *)label destination:(UMMTP3PointCode *)pc ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
/* Group RSM */
- (void)processRST:(UMMTP3Label *)label destination:(UMMTP3PointCode *)pc ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)processRSR:(UMMTP3Label *)label destination:(UMMTP3PointCode *)pc ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
/* Group MIM */
- (void)processLIN:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)processLUN:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)processLIA:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)processLUA:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)processLID:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)processLFU:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)processLLT:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)processLRT:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
/* Group TRM */
- (void)processTRA:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;

/* ANSI only */
- (void)processTRW:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)processTCP:(UMMTP3Label *)label destination:(UMMTP3PointCode *)pc ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)processTCR:(UMMTP3Label *)label destination:(UMMTP3PointCode *)pc ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)processTCA:(UMMTP3Label *)label destination:(UMMTP3PointCode *)pc ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)processRCP:(UMMTP3Label *)label destination:(UMMTP3PointCode *)pc ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)processRCR:(UMMTP3Label *)label destination:(UMMTP3PointCode *)pc ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;

/* group DLM */
- (void)processDLC:(UMMTP3Label *)label cic:(int)cic ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)processCSS:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)processCNS:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)processCNP:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
/* group UFC */
- (void)processUPU:(UMMTP3Label *)label destination:(UMMTP3PointCode *)pc userpartId:(int)upid cause:(int)cause ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;


-(void)sendPdu:(NSData *)data
         label:(UMMTP3Label *)label
       heading:(int)heading
          link:(UMMTP3Link *)link
           slc:(int)slc
            ni:(int)ni
            mp:(int)mp
            si:(int)si
    ackRequest:(NSDictionary *)ackRequest;


-(void)sendPdu:(NSData *)data
         label:(UMMTP3Label *)label
       heading:(int)heading
            ni:(int)ni
            mp:(int)mp
            si:(int)si
    ackRequest:(NSDictionary *)ackRequest
 correlationId:(uint32_t)correlation_id;

/* this version automatically selects any link in the linkset and gets the SLC from the link */
-(void)sendPdu:(NSData *)data
         label:(UMMTP3Label *)label
       heading:(int)heading
            ni:(int)ni
            mp:(int)mp
            si:(int)si
    ackRequest:(NSDictionary *)ackRequest;


//****
- (void)sendSLTM:(UMMTP3Label *)label
         pattern:(NSData *)pattern
              ni:(int)ni
              mp:(int)mp
             slc:(int)slc
            link:(UMMTP3Link *)link;
- (void)sendSLTA:(UMMTP3Label *)label
         pattern:(NSData *)pattern
              ni:(int)ni
              mp:(int)mp
             slc:(int)slc
            link:(UMMTP3Link *)link;
- (void)sendSSLTM:(UMMTP3Label *)label
          pattern:(NSData *)pattern
               ni:(int)ni
               mp:(int)mp
              slc:(int)slc
             link:(UMMTP3Link *)link;
- (void)sendSSLTA:(UMMTP3Label *)label
          pattern:(NSData *)pattern
               ni:(int)ni
               mp:(int)mp
              slc:(int)slc
             link:(UMMTP3Link *)link;

- (void)sendCOO:(UMMTP3Label *)label lastFSN:(int)fsn ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)sendCOA:(UMMTP3Label *)label lastFSN:(int)fsn ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)sendCBD:(UMMTP3Label *)label changeBackCode:(int)cbc ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)sendCBA:(UMMTP3Label *)label changeBackCode:(int)cbc ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)sendECO:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)sendECA:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)sendRCT:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)sendTFC:(UMMTP3Label *)label destination:(UMMTP3PointCode *)pc status:(int)status ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)sendTFP:(UMMTP3Label *)label destination:(UMMTP3PointCode *)pc ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)sendTFR:(UMMTP3Label *)label destination:(UMMTP3PointCode *)pc ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)sendTFA:(UMMTP3Label *)label destination:(UMMTP3PointCode *)pc ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)sendRST:(UMMTP3Label *)label destination:(UMMTP3PointCode *)pc ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)sendRSR:(UMMTP3Label *)label destination:(UMMTP3PointCode *)pc ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)sendLIN:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)sendLUN:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)sendLIA:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)sendLUA:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)sendLID:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)sendLFU:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)sendLLT:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)sendLRT:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)sendTRA:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)sendDLC:(UMMTP3Label *)label cic:(int)cic ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)sendCSS:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)sendCNS:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)sendCNP:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)sendUPU:(UMMTP3Label *)label
    destination:(UMMTP3PointCode *)pc
     userpartId:(int)upid
          cause:(int)cause
             ni:(int)ni
             mp:(int)mp
            slc:(int)slc
           link:(UMMTP3Link *)link;

- (void)sendUPA:(UMMTP3Label *)label
    destination:(UMMTP3PointCode *)pc
     userpartId:(int)upid
          cause:(int)cause
             ni:(int)ni
             mp:(int)mp
            slc:(int)slc
           link:(UMMTP3Link *)link;

- (void)sendUPT:(UMMTP3Label *)label
    destination:(UMMTP3PointCode *)pc
     userpartId:(int)upid
          cause:(int)cause
             ni:(int)ni
             mp:(int)mp
            slc:(int)slc
           link:(UMMTP3Link *)link;


- (NSDictionary *)config;
- (void)setConfig:(NSDictionary *)config applicationContext:(id<UMLayerMTP3ApplicationContextProtocol>)appContext;
- (void)setDefaultValues;
- (void)setDefaultValuesFromMTP3;



- (void)fisuIndication:(const unsigned char *)data maxlen:(size_t)maxlen slc:(int)slc;
- (void)lssuIndication:(const unsigned char *)data maxlen:(size_t)maxlen slc:(int)slc;
- (void)msuIndication:(const unsigned char *)data maxlen:(size_t)maxlen slc:(int)slc;

- (void)msuIndication2:(NSData *)pdu
                 label:(UMMTP3Label *)label
                    si:(int)si
                    ni:(int)ni
                    mp:(int)mp
                   slc:(int)slc
                  link:(UMMTP3Link *)link
     networkAppearance:(NSData *)network_appearance
         correlationId:(NSData *)correlation_id
        routingContext:(NSData *)routing_context;

- (BOOL) isFromAdjacentToLocal:(UMMTP3Label *)label;

- (void)powerOn;
- (void)powerOff;
- (void)start:(int)slc;
- (void)stop:(int)slc;
- (void)attachmentConfirmed:(int)slc;
- (void)attachmentFailed:(int)slc reason:(NSString *)r;
- (void)sctpStatusUpdate:(SCTP_Status)status slc:(int)slc;
- (void)m2paStatusUpdate:(M2PA_Status)status slc:(int)slc;
- (void)linktestTimeEventForLink:(UMMTP3Link *)link;
- (void)updateLinksetStatus;

- (void)advertizePointcodeAvailable:(UMMTP3PointCode *)pc mask:(int)mask;
- (void)advertizePointcodeRestricted:(UMMTP3PointCode *)pc mask:(int)mask;
- (void)advertizePointcodeUnavailable:(UMMTP3PointCode *)pc mask:(int)mask;

@end
