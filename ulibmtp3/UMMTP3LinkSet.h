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
#import <ulibmtp3/UMMTP3Variant.h>
#import <ulibmtp3/UMMTP3TransitPermission.h>
#import <ulibmtp3/UMLayerMTP3ApplicationContextProtocol.h>
#import <ulibmtp3/UMMTP3RoutePriority.h>
#import <ulibmtp3/UMMTP3LinkSetPrometheusData.h>

@class UMMTP3Link;
@class UMLayerMTP3;
@class UMMTP3Label;
@class UMMTP3PointCode;
@class UMMTP3WhiteList;
@class UMMTP3BlackList;
@class UMMTP3TranslationTableMap;
@class UMMTP3PointCodeTranslationTable;
@class SccpNumberTranslation;

@protocol UMMTP3ScreeningPluginProtocol
-(UMMTP3TransitPermission_result) screenIncomingLabel:(UMMTP3Label *)label
                                                error:(NSError **)e
                                              linkset:(NSString *)linksetName;
- (NSError *)loadConfigFromFile:(NSString *)config;
- (NSError *)reloadConfig;
- (void)close;
@end

@protocol UMMTP3SCCPScreeningPluginProtocol
- (int)screenSccpPacketInbound:(id)packet /* really returns UMSccpScreening_result */
                         error:(NSError **)err;
- (NSError *)loadConfigFromFile:(NSString *)filename;
- (NSError *)reloadConfig;
- (void)close;
@end

typedef enum UMMTP3ScreeningTraceLevel
{
    UMMTP3ScreeningTraceLevel_none = 0,
    UMMTP3ScreeningTraceLevel_rejected_only = 1,
    UMMTP3ScreeningTraceLevel_everything = 2,
} UMMTP3ScreeningTraceLevel;

@interface UMMTP3LinkSet : UMObject
{
    UMLayerMTP3                     *_mtp3;
    NSString                        *_name;
    UMSynchronizedSortedDictionary  *_linksBySlc;
    UMMutex                         *_slsLock;
    UMLogLevel                      _logLevel;
    UMMTP3Variant                   _variant;
    UMMTP3PointCode                 *_localPointCode;
    UMMTP3PointCode                 *_adjacentPointCode;
    UMMTP3PointCode                 *_adjacentPointCodeTranslated;
    NSNumber                        *_overrideNetworkIndicator;
    int                             _linkSelector;
    unsigned long                   _nationalOptions;
    UMMTP3WhiteList             *_incomingWhiteList;
    UMMTP3BlackList             *_incomingBlackList;
    int                         _tra_sent;
    int                         _trw_received;
    NSUInteger                  _activeLinksCount;
    NSUInteger                  _inactiveLinksCount;
    NSUInteger                  _readyLinksCount;
    NSUInteger                  _processorOutageLinksCount;
    NSUInteger                  _totalLinksCount;
    
    UMMutex         *_currentLinksMutex;
    NSMutableArray *_currentInactiveLinks;
    NSMutableArray *_currentActiveLinks;
    NSMutableArray *_currentReadyLinks;
    NSMutableArray *_currentProcessorOutageLinks;

    int                         _congestionLevel;
    double                      _speed;
    int                         _last_sls;
    BOOL                        _sendExtendedAttributes;
    NSString                    *_ttmap_in_name;
    NSString                    *_ttmap_out_name;
    UMMTP3TranslationTableMap   *_ttmap_in;
    UMMTP3TranslationTableMap   *_ttmap_out;
    
    NSString                    *_cga_number_translation_in_name;
    NSString                    *_cda_number_translation_in_name;
    NSString                    *_cga_number_translation_out_name;
    NSString                    *_cda_number_translation_out_name;
    SccpNumberTranslation       *_cga_number_translation_in;
    SccpNumberTranslation       *_cda_number_translation_in;
    SccpNumberTranslation       *_cga_number_translation_out;
    SccpNumberTranslation       *_cda_number_translation_out;

    NSString                    *_linkNamesBySlc[16];
    UMMTP3PointCodeTranslationTable *_pointcodeTranslationTableBidi;
    UMMTP3PointCodeTranslationTable *_pointcodeTranslationTableIn;
    UMMTP3PointCodeTranslationTable *_pointcodeTranslationTableOut;
    NSString                    *_pointcodeTranslationTableNameBidi;
    NSString                    *_pointcodeTranslationTableNameIn;
    NSString                    *_pointcodeTranslationTableNameOut;
    id<UMLayerMTP3ApplicationContextProtocol>  _appdel; 
    UMSynchronizedSortedDictionary *_advertizedPointcodes;
    BOOL                        _dontAdvertizeRoutes;
    NSString                    *_lastError;
    UMThroughputCounter         *_speedometerRx;
    UMThroughputCounter         *_speedometerTx;
    UMThroughputCounter         *_speedometerRxBytes;
    UMThroughputCounter         *_speedometerTxBytes;

    UMPlugin<UMMTP3ScreeningPluginProtocol> *_mtp3_screeningPlugin;
    NSString                                *_mtp3_screeningPluginName;
    NSString                                *_mtp3_screeningPluginConfigFileName;
    NSString                                *_mtp3_screeningPluginTraceFileName;
    FILE                                    *_mtp3_screeningPluginTraceFile;

    UMPlugin<UMMTP3SCCPScreeningPluginProtocol>*_sccp_screeningPlugin;
    NSString                                *_sccp_screeningPluginName;
    NSString                                *_sccp_screeningPluginConfigFileName;
    NSString                                *_sccp_screeningPluginTraceFileName;
    FILE                                    *_sccp_screeningPluginTraceFile;

    UMMutex                                 *_mtp3_traceLock;
    UMMutex                                 *_sccp_traceLock;

    NSArray                     *_permittedPointcodesInRoutingUpdates;
    NSArray                     *_deniedPointcodesInRoutingUpdates;
    BOOL                        _permittedPointcodesInRoutingUpdatesAll;
    BOOL                        _deniedPointcodesInRoutingUpdatesAll;
    NSArray                     *_allowedAdvertizedPointcodes;
    NSArray                     *_deniedAdvertizedPointcodes;

    UMMTP3ScreeningTraceLevel _sccpScreeningTraceLevel;  /* 0 = dont log. 1 = log blocked, 2 = log all */
    UMMTP3ScreeningTraceLevel _mtp3ScreeningTraceLevel;  /* 0 = dont log. 1 = log blocked, 2 = log all */
    UMMTP3LinkSetPrometheusData *_prometheusMetrics;
    NSDate                      *_lastLinksetUp;
    NSDate                      *_lastLinksetDown;
    UMTimer                     *_routeRetestTimer; /* timer T10 */
    UMHistoryLog                *_layerHistory;
}

- (void)addToLayerHistoryLog:(NSString *)s;

/*
@property(readwrite,assign,atomic)      int     tra_sent;
@property(readwrite,assign,atomic)      int     trw_received;
@property(readwrite,assign,atomic)      double  speed;
*/

@property(readwrite,assign) int congestionLevel;
//@property(readwrite,strong) UMLogFeed   *log;
@property(readwrite,assign) UMLogLevel logLevel;

@property(readwrite,strong) UMMutex *slsLock;
@property(readwrite,strong) NSString *name;
@property(readwrite,strong) UMSynchronizedSortedDictionary *linksByName;
@property(readwrite,strong) UMSynchronizedSortedDictionary *linksBySlc;
@property(readwrite,strong) UMLayerMTP3 *mtp3;
@property(readwrite,assign) UMMTP3Variant variant;
@property(readwrite,strong) UMMTP3PointCode *localPointCode;
@property(readwrite,strong) UMMTP3PointCode *adjacentPointCode;
@property(readwrite,strong) UMMTP3PointCode *adjacentPointCodeTranslated;

@property(readwrite,strong) NSNumber *overrideNetworkIndicator;

@property(readwrite,strong) UMMTP3WhiteList *incomingWhiteList;
@property(readwrite,strong) UMMTP3BlackList *incomingBlackList;

@property(readonly,assign) int activeLinks;
@property(readonly,assign) int inactiveLinks;
@property(readonly,assign) int readyLinks;
@property(readonly,assign) int totalLinks;

@property(readonly,assign) int tra_sent;
@property(readonly,assign) int trw_received;
@property(readwrite,assign) double speed;
@property(readwrite,strong) UMThroughputCounter *speedometerRx;
@property(readwrite,strong) UMThroughputCounter *speedometerTx;
@property(readwrite,strong) UMThroughputCounter *speedometerRxBytes;
@property(readwrite,strong) UMThroughputCounter *speedometerTxBytes;
@property(readwrite,assign) BOOL  sendExtendedAttributes;
@property(readwrite,strong) UMMTP3PointCodeTranslationTable *pointcodeTranslationTableIn;
@property(readwrite,strong) UMMTP3PointCodeTranslationTable *pointcodeTranslationTableOut;
@property(readwrite,strong) UMMTP3PointCodeTranslationTable *pointcodeTranslationTableBidi;
@property(readwrite,strong) NSString *pointcodeTranslationTableNameBidi;
@property(readwrite,strong) NSString *pointcodeTranslationTableNameIn;
@property(readwrite,strong) NSString *pointcodeTranslationTableNameOut;
@property(readwrite,strong) NSString *ttmap_in_name;
@property(readwrite,strong) NSString *ttmap_out_name;
@property(readwrite,strong) UMMTP3TranslationTableMap   *ttmap_in;
@property(readwrite,strong) UMMTP3TranslationTableMap   *ttmap_out;


@property(readwrite,strong) NSString                    *cga_number_translation_in_name;
@property(readwrite,strong) NSString                    *cda_number_translation_in_name;
@property(readwrite,strong) NSString                    *cga_number_translation_out_name;
@property(readwrite,strong) NSString                    *cda_number_translation_out_name;
@property(readwrite,strong) SccpNumberTranslation       *cga_number_translation_in;
@property(readwrite,strong) SccpNumberTranslation       *cda_number_translation_in;
@property(readwrite,strong) SccpNumberTranslation       *cga_number_translation_out;
@property(readwrite,strong) SccpNumberTranslation       *cda_number_translation_out;


@property(readwrite,strong) NSString                    *lastError;


@property(readwrite,strong) UMPlugin<UMMTP3ScreeningPluginProtocol> *mtp3_screeningPlugin;
@property(readwrite,strong) NSString                                *mtp3_screeningPluginName;
@property(readwrite,strong) NSString                                *mtp3_screeningPluginConfigFileName;
@property(readwrite,strong) NSString                                *mtp3_screeningPluginTraceFileName;

@property(readwrite,strong) UMPlugin<UMMTP3SCCPScreeningPluginProtocol>*sccp_screeningPlugin;
@property(readwrite,strong) NSString                                *sccp_screeningPluginName;
@property(readwrite,strong) NSString                                *sccp_screeningPluginConfigFileName;
@property(readwrite,strong) NSString                                *sccp_screeningPluginTraceFileName;

@property(readwrite,strong) UMMutex                                 *traceLock;
@property(readwrite,strong,atomic) UMSynchronizedSortedDictionary *advertizedPointcodes;

@property(readwrite,strong,atomic) NSArray                     *permittedPointcodesInRoutingUpdates;
@property(readwrite,strong,atomic) NSArray                     *deniedPointcodesInRoutingUpdates;
@property(readwrite,assign,atomic) BOOL                        permittedPointcodesInRoutingUpdatesAll;
@property(readwrite,assign,atomic) BOOL                        deniedPointcodesInRoutingUpdatesAll;
@property(readwrite,strong,atomic) NSArray                     *allowedAdvertizedPointcodes;
@property(readwrite,strong,atomic) NSArray                     *deniedAdvertizedPointcodes;
@property(readwrite,assign,atomic) BOOL                        dontAdvertizeRoutes;
@property(readwrite,assign,atomic) UMMTP3ScreeningTraceLevel    sccpScreeningTraceLevel;
@property(readwrite,assign,atomic) UMMTP3ScreeningTraceLevel    mtp3ScreeningTraceLevel;
@property(readwrite,strong,atomic) UMMTP3LinkSetPrometheusData *prometheusMetrics;
@property(readwrite,strong,atomic) NSDate                      *lastLinksetUp;
@property(readwrite,strong,atomic) NSDate                      *lastLinksetDown;

- (void)addLink:(UMMTP3Link *)lnk;
- (void)removeAllLinks;
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
- (void)processXCO:(UMMTP3Label *)label lastFSN:(int)fsn ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)processXCA:(UMMTP3Label *)label lastFSN:(int)fsn ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
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
- (void)sendXCO:(UMMTP3Label *)label lastFSN:(int)fsn ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
- (void)sendXCA:(UMMTP3Label *)label lastFSN:(int)fsn ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link;
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
- (void)powerOn:(NSString *)reason;
- (void)powerOff;
- (void)powerOff:(NSString *)reason;
- (void)forcedPowerOn;
- (void)forcedPowerOff;
- (void)start:(int)slc;
- (void)stop:(int)slc;
- (void)attachmentConfirmed:(int)slc;
- (void)attachmentFailed:(int)slc reason:(NSString *)r;
- (void)sctpStatusUpdate:(UMSocketStatus)status slc:(int)slc;
- (void)m2paStatusUpdate:(M2PA_Status)status slc:(int)slc;
- (void)linktestTimeEventForLink:(UMMTP3Link *)link;
- (void)updateLinkSetStatus;

- (void)forgetAdvertizedPointcodes; /* call this to let the outbound cache forget which pointcodes it has already advertized */
- (void)advertizePointcodeAvailable:(UMMTP3PointCode *)pc mask:(int)mask;
- (void)advertizePointcodeRestricted:(UMMTP3PointCode *)pc mask:(int)mask;
- (void)advertizePointcodeUnavailable:(UMMTP3PointCode *)pc mask:(int)mask;

- (void)advertizePointcodeAvailable:(UMMTP3PointCode *)pc mask:(int)mask link:(UMMTP3Link *)link;
- (void)advertizePointcodeRestricted:(UMMTP3PointCode *)pc mask:(int)mask link:(UMMTP3Link *)link;
- (void)advertizePointcodeUnavailable:(UMMTP3PointCode *)pc mask:(int)mask link:(UMMTP3Link *)link;

- (void)stopDetachAndDestroy;
- (NSString *)webStatus;

- (void)updateRouteUnavailable:(UMMTP3PointCode *)pc
                          mask:(int)mask
                      priority:(UMMTP3RoutePriority)prio
                        reason:(NSString *)reason;
/* returns YES if status has changed */

- (void)updateRouteAvailable:(UMMTP3PointCode *)pc
                        mask:(int)mask
                    priority:(UMMTP3RoutePriority)prio
                      reason:(NSString *)reason;
    /* returns YES if status has changed */

- (void)updateRouteRestricted:(UMMTP3PointCode *)pc
                         mask:(int)mask
                     priority:(UMMTP3RoutePriority)prio
                       reason:(NSString *)reason;
/* returns YES if status has changed */

/* update routes if all links are up or down*/
- (void)updateRoutingTableLinksetAvailable;
- (void)updateRoutingTableLinksetUnavailable;

- (UMMTP3PointCode *)remoteToLocalPointcode:(UMMTP3PointCode *)pc;
- (UMMTP3PointCode *)localToRemotePointcode:(UMMTP3PointCode *)pc;
- (UMMTP3Label *)remoteToLocalLabel:(UMMTP3Label *)label;
- (UMMTP3Label *)localToRemoteLabel:(UMMTP3Label *)label;
- (int)remoteToLocalNetworkIndicator:(int)ni;
- (int)localToRemoteNetworkIndicator:(int)ni;
- (void)reopenTimer1EventFor:(UMMTP3Link *)link;
- (void)reopenTimer2EventFor:(UMMTP3Link *)link;
- (BOOL)allowRoutingUpdateForPointcode:(UMMTP3PointCode *)pc mask:(int)mask;
- (BOOL)allowAdvertizingPointcode:(UMMTP3PointCode *)pc mask:(int)mask;


- (void)openMtp3ScreeningTraceFile;
- (void)closeMtp3ScreeningTraceFile;
- (void)writeMtp3ScreeningTraceFile:(NSString *)s;

- (void)openSccpScreeningTraceFile;
- (void)closeSccpScreeningTraceFile;
- (void)writeSccpScreeningTraceFile:(NSString *)s;

- (void)reopenLogfiles;
- (void)reloadPluginConfigs;
- (void)reloadPlugins;
- (void)loadMtp3ScreeningPlugin;
- (void)loadSccpScreeningPlugin;

@end
