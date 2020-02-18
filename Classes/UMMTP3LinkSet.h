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
#import "UMMTP3RoutePriority.h"

@class UMMTP3Link;
@class UMLayerMTP3;
@class UMMTP3Label;
@class UMMTP3PointCode;
@class UMMTP3WhiteList;
@class UMMTP3BlackList;
@class UMMTP3RoutingTable;
@class UMMTP3TranslationTableMap;
@class UMMTP3PointCodeTranslationTable;

@interface UMMTP3LinkSet : UMObject
{
    UMLayerMTP3                 *_mtp3;
    NSString                    *_name;
    UMSynchronizedSortedDictionary *_linksByName;
    UMSynchronizedSortedDictionary *_linksBySlc;
    UMMutex                     *_linksLock;
    UMMutex                     *_slsLock;
    UMLogLevel                  _logLevel;
    UMMTP3Variant               _variant;
    UMMTP3PointCode             *_localPointCode;
    UMMTP3PointCode             *_adjacentPointCode;
    NSNumber                    *_overrideNetworkIndicator;
    int                         _linkSelector;
    unsigned long               _nationalOptions;
    UMMTP3WhiteList             *_incomingWhiteList;
    UMMTP3BlackList             *_incomingBlackList;
    int                         _tra_sent;
    int                         _trw_received;
    BOOL                        _sendTRA;

    int                         _outstandingSLTA;
    int                         _activeLinks;
    int                         _inactiveLinks;
    int                         _readyLinks;
    int                         _totalLinks;
    int                         _congestionLevel;
    double                      _speed;
    int                         _last_sls;
    BOOL                        _sendExtendedAttributes;
    NSString                    *_ttmap_in_name;
    NSString                    *_ttmap_out_name;
    UMMTP3TranslationTableMap   *_ttmap_in;
    UMMTP3TranslationTableMap   *_ttmap_out;
    NSString                    *_linkNamesBySlc[16];
    UMMTP3PointCodeTranslationTable *_pointcodeTranslationTable;
    NSString                    *_pointcodeTranslationTableName;
    id<UMLayerMTP3ApplicationContextProtocol>  _appdel;
}

/*
@property(readwrite,assign,atomic)      int     tra_sent;
@property(readwrite,assign,atomic)      int     trw_received;
@property(readwrite,assign,atomic)      double  speed;
*/

@property(readwrite,assign) int congestionLevel;
//@property(readwrite,strong) UMLogFeed   *log;
@property(readwrite,assign) UMLogLevel logLevel;
@property(readwrite,strong) NSString *name;
@property(readwrite,strong) UMSynchronizedSortedDictionary *linksByName;
@property(readwrite,strong) UMSynchronizedSortedDictionary *linksBySlc;
@property(readwrite,strong) UMLayerMTP3 *mtp3;
@property(readwrite,assign) UMMTP3Variant variant;
@property(readwrite,strong) UMMTP3PointCode *localPointCode;
@property(readwrite,strong) UMMTP3PointCode *adjacentPointCode;
@property(readwrite,strong) NSNumber *overrideNetworkIndicator;

@property(readwrite,strong) UMMTP3WhiteList *incomingWhiteList;
@property(readwrite,strong) UMMTP3BlackList *incomingBlackList;
@property(readwrite,strong) UMMTP3RoutingTable *routingTable;

@property(readonly,assign) int activeLinks;
@property(readonly,assign) int inactiveLinks;
@property(readonly,assign) int readyLinks;
@property(readonly,assign) int totalLinks;

@property(readonly,assign) int tra_sent;
@property(readonly,assign) int trw_received;
@property(readwrite,assign) double speed;
@property(readwrite,assign) BOOL  sendExtendedAttributes;
@property(readwrite,strong) UMMTP3PointCodeTranslationTable *pointcodeTranslationTable;
@property(readwrite,assign) int outstandingSLTA;

- (void)addLink:(UMMTP3Link *)lnk;
- (void)removeLink:(UMMTP3Link *)lnk;
- (void)removeAllLinks;
- (UMMTP3Link *)getLinkByName:(NSString *)n;
- (UMMTP3Link *)getLinkBySlc:(int)slc;
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
    ackRequest:(NSDictionary *)ackRequest
       options:(NSDictionary *)options;


-(void)sendPdu:(NSData *)data
         label:(UMMTP3Label *)label
       heading:(int)heading
            ni:(int)ni
            mp:(int)mp
            si:(int)si
    ackRequest:(NSDictionary *)ackRequest
 correlationId:(uint32_t)correlation_id
       options:(NSDictionary *)options;

 /*
-(void)sendPdu:(NSData *)data
         label:(UMMTP3Label *)label
       heading:(int)heading
          link:(UMMTP3Link *)link
           slc:(int)slc
            ni:(int)ni
            mp:(int)mp
            si:(int)si
    ackRequest:(NSDictionary *)ackRequest;

*/
/*
-(void)sendPdu:(NSData *)data
         label:(UMMTP3Label *)label
       heading:(int)heading
            ni:(int)ni
            mp:(int)mp
            si:(int)si
    ackRequest:(NSDictionary *)ackRequest
 correlationId:(uint32_t)correlation_id
options:(NSDictionary *)options;
*/


/* this version automatically selects any link in the linkset and gets the SLC from the link */
/*
-(void)sendPdu:(NSData *)data
         label:(UMMTP3Label *)label
       heading:(int)heading
            ni:(int)ni
            mp:(int)mp
            si:(int)si
    ackRequest:(NSDictionary *)ackRequest;
*/

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
- (void)updateLinkSetStatus;

- (void)advertizePointcodeAvailable:(UMMTP3PointCode *)pc mask:(int)mask;
- (void)advertizePointcodeRestricted:(UMMTP3PointCode *)pc mask:(int)mask;
- (void)advertizePointcodeUnavailable:(UMMTP3PointCode *)pc mask:(int)mask;
- (void)stopDetachAndDestroy;
- (NSString *)webStatus;

- (void)updateRouteUnavailable:(UMMTP3PointCode *)pc
                          mask:(int)mask
                      priority:(UMMTP3RoutePriority)prio; /* returns YES if status has changed */

- (void)updateRouteAvailable:(UMMTP3PointCode *)pc
                        mask:(int)mask
                    priority:(UMMTP3RoutePriority)prio; /* returns YES if status has changed */

- (void)updateRouteRestricted:(UMMTP3PointCode *)pc
                         mask:(int)mask
                     priority:(UMMTP3RoutePriority)prio; /* returns YES if status has changed */

-(UMMTP3PointCode *)remoteToLocalPointcode:(UMMTP3PointCode *)pc;
-(UMMTP3PointCode *)localToRemotePointcode:(UMMTP3PointCode *)pc;
-(UMMTP3Label *)remoteToLocalLabel:(UMMTP3Label *)label;
-(UMMTP3Label *)localToRemoteLabel:(UMMTP3Label *)label;
-(int)remoteToLocalNetworkIndicator:(int)ni;
-(int)localToRemoteNetworkIndicator:(int)ni;

@end
