//
//  UMMTP3LinkSet.m
//  ulibmtp3
//
//  Created by Andreas Fink on 04/12/14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import "UMMTP3LinkSet.h"
#import "UMMTP3Link.h"
#import "UMMTP3Variant.h"
#import "UMMTP3Label.h"
#import "UMMTP3HeadingCode.h"
#import "UMMTP3PointCode.h"
#import "UMLayerMTP3.h"
#import "UMMTP3Label.h"
#import "UMMTP3WhiteList.h"
#import "UMMTP3BlackList.h"
#import "UMMTP3TransitPermission.h"
#import "UMMTP3InstanceRoutingTable.h"
#import "UMMTP3PointCodeTranslationTable.h"

@implementation UMMTP3LinkSet

- (int)networkIndicator
{
    return _mtp3.networkIndicator;
}

- (UMMTP3LinkSet *)init
{
    self = [super init];
    if(self)
    {
        _linksBySlc = [[UMSynchronizedSortedDictionary alloc]init];
        _slsLock = [[UMMutex alloc]initWithName:@"mtp3-sls-lock"];
        _name = @"untitled";
        _activeLinks = 0;
        _inactiveLinks = 0;
        _readyLinks = 0;
        _totalLinks = 0;
        _congestionLevel = 0;
        _logLevel = UMLOG_MAJOR;
        _advertizedPointcodes = [[UMSynchronizedSortedDictionary alloc]init];
        _speedometerRx = [[UMThroughputCounter alloc]init];
        _speedometerTx  = [[UMThroughputCounter alloc]init];
        _speedometerRxBytes  = [[UMThroughputCounter alloc]init];
        _speedometerTxBytes = [[UMThroughputCounter alloc]init];
        _sccp_traceLock = [[UMMutex alloc]initWithName:@"sccp-trace-lock"];
        _mtp3_traceLock = [[UMMutex alloc]initWithName:@"mtp3-trace-lock"];
        _currentLinksMutex = [[UMMutex alloc]initWithName:@"current-links-mutex"];
        _layerHistory = [[UMHistoryLog alloc]initWithMaxLines:100];
    }
    return self;
}

- (void)addToLayerHistoryLog:(NSString *)s
{
    [_layerHistory addLogEntry:s];
}

- (void)addLink:(UMMTP3Link *)lnk
{
    UMAssert(lnk!=NULL,@"addLink:NULL");
    int slc = lnk.slc;
    UMAssert(((slc>=0) && (slc < 16)),@"addLink SLC is not in range 0...15");
    if(lnk.name.length==0)
    {
        lnk.name = [NSString stringWithFormat:@"%@:%d",self.name,lnk.slc];
    }
    [self.logFeed infoText:[NSString stringWithFormat:@"adding Link:'%@' to linkSet:'%@' with SLC:%d",lnk.name, self.name,lnk.slc]];
    _linksBySlc[@(lnk.slc)]= lnk;
    lnk.linkset = self;
    _totalLinks++;
    [_mtp3 addLink:lnk];
}

- (void)removeAllLinks
{
   // [self.logFeed infoText:[NSString stringWithFormat:@"removing All Links from linkSet:'%@'",self.name]];

    NSArray *keys = [_linksBySlc allKeys];
    for(NSString *key in keys)
    {
        UMMTP3Link *link = _linksBySlc[key];
        if(link)
        {
            [_mtp3 removeLink:link];
        }
    }
    _linksBySlc = [[UMSynchronizedSortedDictionary alloc]init];
    _totalLinks = 0;
    _activeLinks = 0;
    _inactiveLinks = 0;
    _readyLinks = 0;
}

- (UMMTP3Link *)getLinkBySlc:(int)slc
{
    UMMTP3Link *lnk = _linksBySlc[@(slc)];
    return lnk;
}

- (UMMTP3Link *)getAnyLink
{
    if(_linksBySlc.count==0)
    {
        [self.logFeed debugText:@"linkset has zero links attached"];
        return NULL;
    }

    NSArray *linkKeys = [_linksBySlc allKeys];
    NSMutableArray *activeLinkKeys = [[NSMutableArray alloc]init];
    for(NSNumber *key in linkKeys)
    {
        UMMTP3Link *link = _linksBySlc[key];
        if(link.current_m2pa_status == M2PA_STATUS_IS)
        {
            [activeLinkKeys addObject:key];
        }
    }
    NSUInteger n = [activeLinkKeys count];
    UMMTP3Link *link = NULL;
    if(n>0)
    {
        _linkSelector = _linkSelector + 1;
        _linkSelector = _linkSelector % n;
        NSNumber *key = activeLinkKeys[_linkSelector];
        link = _linksBySlc[key];
    }
    else
    {
        if(_logLevel <=UMLOG_DEBUG)
        {
            [self.logFeed debugText:@"linkset has zero links in the IS state"];
            [self.logFeed debugText:[NSString stringWithFormat:@"_linksBySlc: %@",_linksBySlc.description]];
            NSMutableString *s = [[NSMutableString alloc]init];
            NSArray *linkKeys = [_linksBySlc allKeys];
            for(NSNumber *key in linkKeys)
            {
                UMMTP3Link *link2 = _linksBySlc[key];
                [s appendFormat:@"\t%@",link2.name];
                [s appendFormat:@" SLC %d",link2.slc];
                [s appendFormat:@" %@",[UMLayerM2PA m2paStatusString:link2.current_m2pa_status]];
                [s appendString:@"\n"];
            }
            [self.logFeed debugText:s];
        }
    }
    return link;
}

- (void)logDebug:(NSString *)s
{
    [self.logFeed debugText:s];
}

- (void)logWarning:(NSString *)s
{
    [self.logFeed warningText:s];
}

- (void)logInfo:(NSString *)s
{
    [self.logFeed infoText:s];
}

- (void) logPanic:(NSString *)s
{
    [self.logFeed panicText:s];
}

- (void)logMajorError:(NSString *)s
{
    [self.logFeed majorErrorText:s];
}

- (void)logMinorError:(NSString *)s
{
    [self.logFeed majorErrorText:s];
}


- (void)fisuIndication:(const unsigned char *)data maxlen:(size_t)maxlen slc:(int)slc
{
    if(_logLevel <= UMLOG_DEBUG)
    {
        [self.logFeed debugText:@" FISU (Fill-in Signal Unit). (We should not get this on M2PA data link)"];
    }
}


-(void) protocolViolation
{
    [self.logFeed majorErrorText:@"protocolViolation"];
}

- (void)lssuIndication:(const unsigned char *)data maxlen:(size_t)maxlen slc:(int)slc
{
    if(maxlen < 2)
    {
        [self.logFeed majorErrorText:@"LSSU received with less than 2 byte"];
        [self protocolViolation];
        return;
    }

    int sf = data[1];
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self.logFeed debugText:@" LSSU (m3link Status Signal Unit) (We should not get this on M2PA data link)"];
        [self.logFeed debugText:[NSString stringWithFormat:@" Status Field (SF): [%d]",sf]];
        switch(sf & 0x07)
        {
            case 0:
                [self.logFeed debugText:@"  {SIO} OUT OF ALIGNMENT"];
                break;
            case 1:
                [self.logFeed debugText:@"  {SIN} NORMAL ALIGNMENT"];
                break;
            case 2:
                [self.logFeed debugText:@"  {SIE} EMERGENCY ALIGNMENT"];
                break;
            case 3:
                [self.logFeed debugText:@"  {SIOS} OUT OF SERVICE"];
                break;
            case 4:
                [self.logFeed debugText:@"  {SIPO} PROCESSOR OUTAGE"];
                break;
            case 5:
                [self.logFeed debugText:@"  {SIB} BUSY"];
                break;
            default:
                [self.logFeed debugText:@"  {unknown}"];
                break;
        }
    }
}

- (void) dataIndication:(NSData *)dataIn slc:(int)slc
{
    const unsigned char *data = dataIn.bytes;
    size_t maxlen = dataIn.length;

	if(_logLevel <= UMLOG_DEBUG)
	{
		[self.logFeed debugText:[NSString stringWithFormat:@"dataIndication[slc=%d]: %@",slc,dataIn]];
	}

    if(maxlen <1)
    {
        /* an empty packet to ack the outstanding FSN/BSN */
        /* kind of a FISU */
        if(_logLevel <= UMLOG_DEBUG)
        {
            [self.logFeed debugText:@" empty MSU"];
        }
        return;
    }
    // size_t li = data[0] & 0x3F; /* length indicator */
    switch(maxlen)
    {
        case 0:
            /* FISU */
            [self fisuIndication:data maxlen:maxlen slc:slc];
            break;
        case 1:
            [self lssuIndication:data maxlen:maxlen slc:slc];
            break;
        case 2:
            /* LSSU length=2 */
            [self.logFeed minorErrorText:@" LSSU (m3link Status Signal Unit 2 bytes) not permitted for M2PA"];
            break;
        default:
            [self msuIndication:data maxlen:maxlen slc:slc];
            break;
    }
}

- (UMMTP3TransitPermission_result)screenIncomingLabel:(UMMTP3Label *)label error:(NSError **)err
{
    if((_mtp3_screeningPluginName.length > 0) && (_mtp3_screeningPlugin == NULL))
    {
        [self loadMtp3ScreeningPlugin];
    }
    if(_mtp3_screeningPlugin)
    {
        UMMTP3TransitPermission_result r = [_mtp3_screeningPlugin screenIncomingLabel:label  error:err linkset:self.name];
        return r;
    }
    /* here we check if we allow the incoming pointcode from this link */
#if 0
    if(label.opc.variant != self.variant)
    {
        if(err!=NULL)
        {
            *err = [NSError errorWithDomain:@"mtp_decode" code:0 userInfo:@{@"sysinfo":@"opc-variant does not match local variant",@"backtrace": UMBacktrace(NULL,0)}];
        }
        return UMMTP3TransitPermission_errorResult;
    }
    if(label.dpc.variant != self.variant)
    {
        if(err!=NULL)
        {
            *err = [NSError errorWithDomain:@"mtp_decode" code:0 userInfo:@{@"sysinfo":@"dpc-variant does not match local variant",@"backtrace": UMBacktrace(NULL,0)}];
        }
        return UMMTP3TransitPermission_errorResult;
    }
#endif

    UMMTP3TransitPermission_result perm = UMMTP3TransitPermission_undefined;
    
    if((_incomingWhiteList==NULL) && (_incomingBlackList==NULL))
    {
        return UMMTP3TransitPermission_implicitlyPermitted;
    }
    else if((_incomingWhiteList!=NULL) && (_incomingBlackList==NULL))
    {
        perm = [_incomingWhiteList isTransferAllowed:label];
        if(perm == UMMTP3TransitPermission_explicitlyPermitted)
        {
            return perm;
        }
        return UMMTP3TransitPermission_implicitlyDenied;
    }

    else if((_incomingWhiteList==NULL) && (_incomingBlackList!=NULL))
    {
        perm = [_incomingBlackList isTransferDenied:label];
        if(perm == UMMTP3TransitPermission_explicitlyDenied)
        {
            return perm;
        }
        return UMMTP3TransitPermission_implicitlyPermitted;
    }

    /* white & blacklist defined */
    UMMTP3TransitPermission_result perm_w= [_incomingWhiteList isTransferAllowed:label];
    if(perm_w == UMMTP3TransitPermission_explicitlyPermitted)
    {
        return perm_w;
    }
    perm = [_incomingBlackList isTransferDenied:label];
    if(perm == UMMTP3TransitPermission_explicitlyDenied)
    {
        return perm;
    }
    return UMMTP3TransitPermission_implicitlyDenied;
}

- (void) msuIndication:(const unsigned char *)data maxlen:(size_t)maxlen slc:(int)slc
{
    UMMTP3Link *link = [self getLinkBySlc:slc];
    @try
    {
        int labelsize;
        switch(_variant)
        {
            case UMMTP3Variant_Japan:
            case UMMTP3Variant_China:
            case UMMTP3Variant_ANSI:
                labelsize = 7;
                break;
            default:
                labelsize = 3;
                break;
        }
        if(maxlen < (2+labelsize+1))
        {
            /* we need at least LI byte, SIO byte, LABEL, heading byte */
            @throw([NSException exceptionWithName:@"MTP_PACKET_TOO_SHORT"
                                           reason:NULL
                                         userInfo:@{
                                                    @"sysmsg" : @"too-short-packet",
                                                    @"func": @(__func__),
                                                    @"line": @(__LINE__),
                                                    @"file": @(__FILE__),
                                                    @"obj":self,
                                                    @"backtrace": UMBacktrace(NULL,0)
                                                    }
                    ]);

        }
#define GRAB_BYTE(var,data,index,max)               \
        if (index<max)                              \
        {                                           \
            var = data[index];                      \
            index++;                                \
        }                                           \
        else                                        \
        {                                           \
            @throw([NSException exceptionWithName:@"MTP_PACKET_TOO_SHORT" \
                reason:NULL \
                userInfo:@{ \
                           @"sysmsg" : [NSString stringWithFormat:@"too-short-packet %s:%d",__FILE__,__LINE__],\
                           @"func": @(__func__),\
                           @"line": @(__LINE__),\
                           @"file": @(__FILE__),\
                           @"obj":self,\
                           @"backtrace": UMBacktrace(NULL,0)\
                           }\
                    ]);\
        }


        int idx = 0;
        int li;
        int sio;
        GRAB_BYTE(li,data,idx,maxlen);
        GRAB_BYTE(sio,data,idx,maxlen);

        int si; /* service indicator */
        int ni; /* network indicator */
        int mp; /* message priority */

        if(_logLevel <= UMLOG_DEBUG)
        {
            [self.logFeed debugText:@" MSU (Message Signal Unit)"];
        }
        switch (_variant)
        {
            case UMMTP3Variant_Japan:
                mp = (li >> 6) & 0x03;
                si  = (sio & 0x0F);
                ni  = (sio >> 6) & 0x03;
                break;
            case UMMTP3Variant_ANSI:
                mp = (sio >> 4 ) & 0x03;
                si  = (sio & 0x0F);
                ni  = (sio >> 6) & 0x03;
                break;
            default:
                if (_nationalOptions & UMMTP3_NATIONAL_OPTION_MESSAGE_PRIORITY)
                {
                    mp = (sio >> 4 ) & 0x03;
                    si  = (sio & 0x0F);
                    ni  = (sio >> 6) & 0x03;
                }
                else
                {
                    mp = 0;
                    si  = (sio & 0x0F);
                    ni  = (sio >> 6) & 0x03;
                }
                break;
        }

        UMMTP3Label *label = [[UMMTP3Label alloc]initWithBytes:data pos:&idx variant:_variant];

        ni = [self remoteToLocalNetworkIndicator:ni];
        UMMTP3Label *translatedLabel = [self remoteToLocalLabel:label];

        NSData *pdu = [NSData dataWithBytes:&data[idx] length:(maxlen - idx)];
        [self msuIndication2:pdu
                       label:translatedLabel
                          si:si
                          ni:ni
                          mp:mp
                         slc:slc
                        link:link
           networkAppearance:NULL
               correlationId:NULL
              routingContext:NULL];
    }
    @catch(NSException *e)
    {
        NSDictionary *d = e.userInfo;
        NSString *desc = d[@"sysmsg"];
        [self.logFeed majorErrorText:desc];
        [self protocolViolation];
        return;
    }
}

- (void)updateTxStatisticSi:(int)si headingCode:(int)heading
{
    int msuCount=1;
    switch(si & 0x0F)
    {
        case MTP3_SERVICE_INDICATOR_SCCP:
            [_prometheusMetrics.sccpTxCount increaseBy:1];
            break;
        case MTP3_SERVICE_INDICATOR_TUP:
            [_prometheusMetrics.tupTxCount increaseBy:1];
            break;
        case MTP3_SERVICE_INDICATOR_ISUP:
            [_prometheusMetrics.isupTxCount increaseBy:1];
            break;
        case MTP3_SERVICE_INDICATOR_DUP_C:
            [_prometheusMetrics.dupcTxCount increaseBy:1];
            break;
        case MTP3_SERVICE_INDICATOR_DUP_F:
            [_prometheusMetrics.dupfTxCount increaseBy:1];
            break;
        case MTP3_SERVICE_INDICATOR_RES_TESTING:
            [_prometheusMetrics.resTxCount increaseBy:1];
            break;
        case MTP3_SERVICE_INDICATOR_BROADBAND_ISUP:
            [_prometheusMetrics.bisupTxCount increaseBy:1];
            break;
        case MTP3_SERVICE_INDICATOR_SAT_ISUP:
            [_prometheusMetrics.sisupTxCount increaseBy:1];
            break;
        case MTP3_SERVICE_INDICATOR_SPARE_B:
            [_prometheusMetrics.sparebTxCount increaseBy:1];
            break;
        case MTP3_SERVICE_INDICATOR_SPARE_C:
            [_prometheusMetrics.sparecTxCount increaseBy:1];
            break;
        case MTP3_SERVICE_INDICATOR_SPARE_D:
            [_prometheusMetrics.sparedTxCount increaseBy:1];
            break;
        case MTP3_SERVICE_INDICATOR_SPARE_E:
            [_prometheusMetrics.spareeTxCount increaseBy:1];
            break;
        case MTP3_SERVICE_INDICATOR_SPARE_F:
            [_prometheusMetrics.sparefTxCount increaseBy:1];
            break;
        case MTP3_SERVICE_INDICATOR_MGMT:
        {
            msuCount=0;
            switch(heading)
            {
                case MTP3_MGMT_COO:      /* signalling link test message */
                    [_prometheusMetrics.cooTxCount increaseBy:1];
                    break;
                case MTP3_MGMT_COA:      /* signalling link test message */
                    [_prometheusMetrics.coaTxCount increaseBy:1];
                    break;
                case MTP3_MGMT_XCO:      /* extended changeover order */
                    [_prometheusMetrics.xcoTxCount increaseBy:1];
                    break;
                case MTP3_MGMT_XCA:      /* extended changeover acknowledgmenbt  */
                    [_prometheusMetrics.xcaTxCount increaseBy:1];
                    break;
                case MTP3_MGMT_CBD:      /* Changeback Declaration */
                    [_prometheusMetrics.cbdTxCount increaseBy:1];
                    break;
                case MTP3_MGMT_CBA:      /* Changeback acknowledgement */
                    [_prometheusMetrics.cbaTxCount increaseBy:1];
                    break;
                case MTP3_MGMT_ECO:      /* Emergency Changeover Order */
                    [_prometheusMetrics.ecoTxCount increaseBy:1];
                    break;
                case MTP3_MGMT_ECA:      /* Emergency Changeover Acknowledgement */
                    [_prometheusMetrics.ecaTxCount increaseBy:1];
                    break;
                case MTP3_MGMT_RCT:      /* Signalling route set congesting test signal */
                    [_prometheusMetrics.rctTxCount increaseBy:1];
                    break;
                case MTP3_MGMT_TFC:      /* Transfer Controlled Signal */
                    [_prometheusMetrics.tfcTxCount increaseBy:1];
                    break;
                case MTP3_MGMT_TFP:      /* Transfer Prohibited Signal */
                    [_prometheusMetrics.tfpTxCount increaseBy:1];
                    break;
                case MTP3_MGMT_TFR:      /* Transfer Restricted (national option) */
                    [_prometheusMetrics.tfrTxCount increaseBy:1];
                    break;
                case MTP3_MGMT_TFA:      /* Transfer Allowed */
                    [_prometheusMetrics.tfaTxCount increaseBy:1];
                    break;
                case MTP3_MGMT_RST:      /* Signalling-route-set-test signal for prohibited destination */
                    [_prometheusMetrics.rstTxCount increaseBy:1];
                    break;
                case MTP3_MGMT_RSR:      /* Signalling-route-set-test signal for restricted destination (national option) */
                    [_prometheusMetrics.rsrTxCount increaseBy:1];
                    break;
                case MTP3_MGMT_LIN:      /* Link inhibit signal */
                    [_prometheusMetrics.linTxCount increaseBy:1];
                    break;
                case MTP3_MGMT_LUN:      /* Link uninhibit signal */
                    [_prometheusMetrics.lunTxCount increaseBy:1];
                    break;
                case MTP3_MGMT_LIA:      /* Link inhibit acknowledgement signal */
                    [_prometheusMetrics.liaTxCount increaseBy:1];
                    break;
                case MTP3_MGMT_LUA:      /* Link uninhibit acknowledgement signal */
                    [_prometheusMetrics.luaTxCount increaseBy:1];
                    break;
                case MTP3_MGMT_LID:      /* Link inhibit denied signal */
                    [_prometheusMetrics.lidTxCount increaseBy:1];
                    break;
                case MTP3_MGMT_LFU:      /* Link forced uninhibit signal */
                    [_prometheusMetrics.lfuTxCount increaseBy:1];
                    break;
                case MTP3_MGMT_LLT:      /* Link local inhibit test signal */
                    [_prometheusMetrics.lltTxCount increaseBy:1];
                    break;
                case MTP3_MGMT_LRT:      /* Link remote inhibit test signal */
                    [_prometheusMetrics.lrtTxCount increaseBy:1];
                    break;
                case MTP3_MGMT_TRA:      /* Traffic-restart-allowed signal */
                    [_prometheusMetrics.traTxCount increaseBy:1];
                    break;
                case MTP3_MGMT_DLC:      /* Signalling-data-link-connection-order signal */
                    [_prometheusMetrics.dlcTxCount increaseBy:1];
                    break;
                case MTP3_MGMT_CSS:      /* Connection-successful signal */
                    [_prometheusMetrics.cssTxCount increaseBy:1];
                    break;
                case MTP3_MGMT_CNS:      /* Connection-not-successful signal */
                    [_prometheusMetrics.cnsTxCount increaseBy:1];
                    break;
                case MTP3_MGMT_CNP:      /* Connection-not-possible signal */
                    [_prometheusMetrics.cnpTxCount increaseBy:1];
                    break;
                case MTP3_MGMT_UPU:      /* User Part Unavailable */
                    [_prometheusMetrics.upuTxCount increaseBy:1];
                    break;
                case MTP3_MGMT_TCP:      /* ANSI */
                    [_prometheusMetrics.tcpTxCount increaseBy:1];
                    break;
                case MTP3_MGMT_TRW:      /* ANSI */
                    [_prometheusMetrics.trwTxCount increaseBy:1];
                    break;
                case MTP3_MGMT_TCR:      /* ANSI */
                    [_prometheusMetrics.tcrTxCount increaseBy:1];
                    break;
                case MTP3_MGMT_TCA:      /* ANSI */
                    [_prometheusMetrics.tcaTxCount increaseBy:1];
                    break;
                case MTP3_MGMT_RCP:      /* ANSI */
                    [_prometheusMetrics.rcpTxCount increaseBy:1];
                    break;
                case MTP3_MGMT_RCR:      /* ANSI */
                    [_prometheusMetrics.rcrTxCount increaseBy:1];
                    break;
                case MTP3_MGMT_UPA:      /* ANSI 91 only */
                    [_prometheusMetrics.upaTxCount increaseBy:1];
                    break;
                case MTP3_MGMT_UPT:      /*ANSI 91 only */
                    [_prometheusMetrics.uptTxCount increaseBy:1];
                    break;
            }
            break;
        }
        case MTP3_SERVICE_INDICATOR_TEST:
        {
            msuCount=0;
            switch(heading)
            {
                case MTP3_TESTING_SLTM:
                    [_prometheusMetrics.sltmTxCount increaseBy:1];
                    break;
                case MTP3_TESTING_SLTA:
                    [_prometheusMetrics.sltaTxCount increaseBy:1];
                    break;
            }
            break;
        }
        case MTP3_SERVICE_INDICATOR_MAINTENANCE_SPECIAL_MESSAGE:
        {
            msuCount = 0;
            switch(heading)
            {
                case MTP3_ANSI_TESTING_SSLTM:
                    [_prometheusMetrics.ssltmTxCount increaseBy:1];
                    break;
                case MTP3_ANSI_TESTING_SSLTA:
                    [_prometheusMetrics.ssltaTxCount increaseBy:1];
                    break;
            }
            break;
        }
    }
    if(msuCount)
    {
        [_prometheusMetrics.msuTxCount increaseBy:1];
        [_prometheusMetrics.msuTxThroughput increaseBy:1];
    }
}

- (void)updateRxStatisticSi:(int)si headingCode:(int)heading
{
    int msuCount = 1;
    switch(si & 0x0F)
    {
        case MTP3_SERVICE_INDICATOR_SCCP:
            [_prometheusMetrics.sccpRxCount increaseBy:1];
            break;
        case MTP3_SERVICE_INDICATOR_TUP:
            [_prometheusMetrics.tupRxCount increaseBy:1];
            break;
        case MTP3_SERVICE_INDICATOR_ISUP:
            [_prometheusMetrics.isupRxCount increaseBy:1];
            break;
        case MTP3_SERVICE_INDICATOR_DUP_C:
            [_prometheusMetrics.dupcRxCount increaseBy:1];
            break;
        case MTP3_SERVICE_INDICATOR_DUP_F:
            [_prometheusMetrics.dupfRxCount increaseBy:1];
            break;
        case MTP3_SERVICE_INDICATOR_RES_TESTING:
            [_prometheusMetrics.resRxCount increaseBy:1];
            break;
        case MTP3_SERVICE_INDICATOR_BROADBAND_ISUP:
            [_prometheusMetrics.bisupRxCount increaseBy:1];
            break;
        case MTP3_SERVICE_INDICATOR_SAT_ISUP:
            [_prometheusMetrics.sisupRxCount increaseBy:1];
            break;
        case MTP3_SERVICE_INDICATOR_SPARE_B:
            [_prometheusMetrics.sparebRxCount increaseBy:1];
            break;
        case MTP3_SERVICE_INDICATOR_SPARE_C:
            [_prometheusMetrics.sparecRxCount increaseBy:1];
            break;
        case MTP3_SERVICE_INDICATOR_SPARE_D:
            [_prometheusMetrics.sparedRxCount increaseBy:1];
            break;
        case MTP3_SERVICE_INDICATOR_SPARE_E:
            [_prometheusMetrics.spareeRxCount increaseBy:1];
            break;
        case MTP3_SERVICE_INDICATOR_SPARE_F:
            [_prometheusMetrics.sparefRxCount increaseBy:1];
            break;
        case MTP3_SERVICE_INDICATOR_MGMT:
        {
            msuCount = 0;
            switch(heading)
            {
                case MTP3_MGMT_COO:      /* signalling link test message */
                    [_prometheusMetrics.cooRxCount increaseBy:1];
                    break;
                case MTP3_MGMT_COA:      /* signalling link test message */
                    [_prometheusMetrics.coaRxCount increaseBy:1];
                    break;
                case MTP3_MGMT_XCO:      /* extended changeover order */
                    [_prometheusMetrics.xcoRxCount increaseBy:1];
                    break;
                case MTP3_MGMT_XCA:      /* extended changeover acknowledgmenbt  */
                    [_prometheusMetrics.xcaRxCount increaseBy:1];
                    break;
                case MTP3_MGMT_CBD:      /* Changeback Declaration */
                    [_prometheusMetrics.cbdRxCount increaseBy:1];
                    break;
                case MTP3_MGMT_CBA:      /* Changeback acknowledgement */
                    [_prometheusMetrics.cbaRxCount increaseBy:1];
                    break;
                case MTP3_MGMT_ECO:      /* Emergency Changeover Order */
                    [_prometheusMetrics.ecoRxCount increaseBy:1];
                    break;
                case MTP3_MGMT_ECA:      /* Emergency Changeover Acknowledgement */
                    [_prometheusMetrics.ecaRxCount increaseBy:1];
                    break;
                case MTP3_MGMT_RCT:      /* Signalling route set congesting test signal */
                    [_prometheusMetrics.rctRxCount increaseBy:1];
                    break;
                case MTP3_MGMT_TFC:      /* Transfer Controlled Signal */
                    [_prometheusMetrics.tfcRxCount increaseBy:1];
                    break;
                case MTP3_MGMT_TFP:      /* Transfer Prohibited Signal */
                    [_prometheusMetrics.tfpRxCount increaseBy:1];
                    break;
                case MTP3_MGMT_TFR:      /* Transfer Restricted (national option) */
                    [_prometheusMetrics.tfrRxCount increaseBy:1];
                    break;
                case MTP3_MGMT_TFA:      /* Transfer Allowed */
                    [_prometheusMetrics.tfaRxCount increaseBy:1];
                    break;
                case MTP3_MGMT_RST:      /* Signalling-route-set-test signal for prohibited destination */
                    [_prometheusMetrics.rstRxCount increaseBy:1];
                    break;
                case MTP3_MGMT_RSR:      /* Signalling-route-set-test signal for restricted destination (national option) */
                    [_prometheusMetrics.rsrRxCount increaseBy:1];
                    break;
                case MTP3_MGMT_LIN:      /* Link inhibit signal */
                    [_prometheusMetrics.linRxCount increaseBy:1];
                    break;
                case MTP3_MGMT_LUN:      /* Link uninhibit signal */
                    [_prometheusMetrics.lunRxCount increaseBy:1];
                    break;
                case MTP3_MGMT_LIA:      /* Link inhibit acknowledgement signal */
                    [_prometheusMetrics.liaRxCount increaseBy:1];
                    break;
                case MTP3_MGMT_LUA:      /* Link uninhibit acknowledgement signal */
                    [_prometheusMetrics.luaRxCount increaseBy:1];
                    break;
                case MTP3_MGMT_LID:      /* Link inhibit denied signal */
                    [_prometheusMetrics.lidRxCount increaseBy:1];
                    break;
                case MTP3_MGMT_LFU:      /* Link forced uninhibit signal */
                    [_prometheusMetrics.lfuRxCount increaseBy:1];
                    break;
                case MTP3_MGMT_LLT:      /* Link local inhibit test signal */
                    [_prometheusMetrics.lltRxCount increaseBy:1];
                    break;
                case MTP3_MGMT_LRT:      /* Link remote inhibit test signal */
                    [_prometheusMetrics.lrtRxCount increaseBy:1];
                    break;
                case MTP3_MGMT_TRA:      /* Traffic-restart-allowed signal */
                    [_prometheusMetrics.traRxCount increaseBy:1];
                    break;
                case MTP3_MGMT_DLC:      /* Signalling-data-link-connection-order signal */
                    [_prometheusMetrics.dlcRxCount increaseBy:1];
                    break;
                case MTP3_MGMT_CSS:      /* Connection-successful signal */
                    [_prometheusMetrics.cssRxCount increaseBy:1];
                    break;
                case MTP3_MGMT_CNS:      /* Connection-not-successful signal */
                    [_prometheusMetrics.cnsRxCount increaseBy:1];
                    break;
                case MTP3_MGMT_CNP:      /* Connection-not-possible signal */
                    [_prometheusMetrics.cnpRxCount increaseBy:1];
                    break;
                case MTP3_MGMT_UPU:      /* User Part Unavailable */
                    [_prometheusMetrics.upuRxCount increaseBy:1];
                    break;
                case MTP3_MGMT_TCP:      /* ANSI */
                    [_prometheusMetrics.tcpRxCount increaseBy:1];
                    break;
                case MTP3_MGMT_TRW:      /* ANSI */
                    [_prometheusMetrics.trwRxCount increaseBy:1];
                    break;
                case MTP3_MGMT_TCR:      /* ANSI */
                    [_prometheusMetrics.tcrRxCount increaseBy:1];
                    break;
                case MTP3_MGMT_TCA:      /* ANSI */
                    [_prometheusMetrics.tcaRxCount increaseBy:1];
                    break;
                case MTP3_MGMT_RCP:      /* ANSI */
                    [_prometheusMetrics.rcpRxCount increaseBy:1];
                    break;
                case MTP3_MGMT_RCR:      /* ANSI */
                    [_prometheusMetrics.rcrRxCount increaseBy:1];
                    break;
                case MTP3_MGMT_UPA:      /* ANSI 91 only */
                    [_prometheusMetrics.upaRxCount increaseBy:1];
                    break;
                case MTP3_MGMT_UPT:      /*ANSI 91 only */
                    [_prometheusMetrics.uptRxCount increaseBy:1];
                    break;
            }
            break;
        }
        case MTP3_SERVICE_INDICATOR_TEST:
        {
            msuCount = 0;
            switch(heading)
            {
                case MTP3_TESTING_SLTM:
                    [_prometheusMetrics.sltmRxCount increaseBy:1];
                    break;
                case MTP3_TESTING_SLTA:
                    [_prometheusMetrics.sltaRxCount increaseBy:1];
                    break;
            }
            break;
        }
        case MTP3_SERVICE_INDICATOR_MAINTENANCE_SPECIAL_MESSAGE:
        {
            msuCount = 0;
            switch(heading)
            {
                case MTP3_ANSI_TESTING_SSLTM:
                    [_prometheusMetrics.ssltmRxCount increaseBy:1];
                    break;
                case MTP3_ANSI_TESTING_SSLTA:
                    [_prometheusMetrics.ssltaRxCount increaseBy:1];
                    break;
            }
            break;
        }
    }
    if(msuCount)
    {
        [_prometheusMetrics.msuRxCount increaseBy:1];
        [_prometheusMetrics.msuRxThroughput increaseBy:1];
    }

}
- (void)msuIndication2:(NSData *)pdu
                 label:(UMMTP3Label *)label
                    si:(int)si
                    ni:(int)ni
                    mp:(int)mp
                   slc:(int)slc
                  link:(UMMTP3Link *)link
     networkAppearance:(NSData *)network_appearance
         correlationId:(NSData *)correlation_id
        routingContext:(NSData *)routing_context

{
    int idx=0;
    const uint8_t *data = pdu.bytes;
    NSUInteger maxlen   = pdu.length;
    int sls = label.sls;
    @try
    {
        if(_logLevel <= UMLOG_DEBUG)
        {
            [self.logFeed debugText:[NSString stringWithFormat:@"  data2: [%@]",pdu]];
            [self.logFeed debugText:[NSString stringWithFormat:@" maxlen: [%d]",(int)maxlen]];
            [self.logFeed debugText:[NSString stringWithFormat:@"     si: [%d]",si]];
            [self.logFeed debugText:[NSString stringWithFormat:@"     ni: [%d]",ni]];
            [self.logFeed debugText:[NSString stringWithFormat:@"    sls: [%d]",sls]];
            [self.logFeed debugText:[NSString stringWithFormat:@"     mp: [%d]",mp]];
            [self.logFeed debugText:[NSString stringWithFormat:@"    opc: %@",label.opc.description]];
            [self.logFeed debugText:[NSString stringWithFormat:@"    dpc: %@",label.dpc.description]];
        }

        /* Translate incoming NI and label here */

        if((ni != self.networkIndicator) && (_overrideNetworkIndicator && _overrideNetworkIndicator.intValue != ni))
        {
            self.lastError = [NSString stringWithFormat:@"NI received is %d but is expected to be %d",ni,self.networkIndicator];
            [self.logFeed majorErrorText:self.lastError];
            [self protocolViolation];
            return;
        }
        if(link && (link.current_m2pa_status != M2PA_STATUS_IS))
        {
            /* All messages to another destination received at a signalling point whose MTP is restarting are discarded.*/
            if(![label.dpc isEqualToPointCode:_localPointCode])
            {
                [self logMinorError:@"MTP_DECODE: no-relay-during-startup"];
                [self protocolViolation];
                return;
            }
        }
        

        NSError *e = NULL;
        UMMTP3TransitPermission_result perm = [self screenIncomingLabel:label error:&e];
        switch(perm)
        {
            case UMMTP3TransitPermission_errorResult:
                @throw([NSException exceptionWithName:@"UMMTP3TransitPermission_errorResult"
                                               reason:e.description
                                             userInfo:@{
                                                        @"sysmsg" : @"screening failed",
                                                        @"func": @(__func__),
                                                        @"line": @(__LINE__),
                                                        @"file": @(__FILE__),
                                                        @"obj":self,
                                                        @"err":e,
                                                        @"backtrace": UMBacktrace(NULL,0)
                                                        }
                        ]);
                break;
            case UMMTP3TransitPermission_explicitlyDenied:
            {
                if(_logLevel <= UMLOG_DEBUG)
                {
                    [self.logFeed debugText:[NSString stringWithFormat:@"  screening: explicitly denied"]];
                }
                break;
            }
            case UMMTP3TransitPermission_implicitlyDenied:
            {
                if(_logLevel <= UMLOG_DEBUG)
                {
                    [self.logFeed debugText:[NSString stringWithFormat:@"  screening: implicitly denied"]];
                    break;
                }
            }
            case UMMTP3TransitPermission_explicitlyPermitted:
            {
                if(_logLevel <= UMLOG_DEBUG)
                {
                    [self.logFeed debugText:[NSString stringWithFormat:@"  screening: explicitly permitted"]];
                }
                break;
            }
            case UMMTP3TransitPermission_implicitlyPermitted:
            {
                if(_logLevel <= UMLOG_DEBUG)
                {
                    [self.logFeed debugText:[NSString stringWithFormat:@"  screening: implicitly permitted"]];
                }
                break;
            }
            default:
                break;
        }

        switch(si & 0x0F)
        {
            case MTP3_SERVICE_INDICATOR_MAINTENANCE_SPECIAL_MESSAGE:
            {
                /* Signalling network testing and maintenance messages */
                if(_logLevel <= UMLOG_DEBUG)
                {
                    [self.logFeed debugText:[NSString stringWithFormat:@"  Service Indicator: [%d] Signalling network testing and maintenance messages",si]];
                }
                int heading;
                GRAB_BYTE(heading,data,idx,maxlen);
                [self updateRxStatisticSi:si headingCode:heading];
                switch(heading)
                {
                    case MTP3_ANSI_TESTING_SSLTM:
                    {
                        int byte;
                        int slc2;
                        int len;
                        GRAB_BYTE(byte,data,idx,maxlen);
                        if(_variant == UMMTP3Variant_ANSI)
                        {
                            len = (byte & 0xF0) >> 4;
                            slc2 = (byte & 0x0F);
                        }
                        else
                        {
                            len = (byte & 0xF0) >> 4;
                            slc2 = label.sls;
                        }
                        if(slc != slc2)
                        {
                            [self.logFeed majorErrorText:@"SSLTM: SLC received is not matching the links configured SLC"];
                            [self protocolViolation];
                        }
                        if ((idx + len)>maxlen)
                        {
                            [self logMinorError:@"MTP_DECODE: MTP_PACKET_TOO_SHORT"];
                            @throw([NSException exceptionWithName:@"MTP_PACKET_TOO_SHORT"
                                                           reason:NULL
                                                         userInfo:@{
                                                                    @"sysmsg" : @"too-short-packet in SLTM",
                                                                    @"func": @(__func__),
                                                                    @"line": @(__LINE__),
                                                                    @"file": @(__FILE__),
                                                                    @"obj":self,
                                                                    @"backtrace": UMBacktrace(NULL,0)
                                                                    }
                                    ]);
                        }
                        NSMutableData *pattern = [[NSMutableData alloc]init];
                        [pattern appendBytes:&data[idx] length:len];
                        idx+=len;
                        [self processSSLTM:label
                                   pattern:pattern
                                        ni:ni
                                        mp:mp
                                       slc:slc2
                                      link:link];
                    }
                        break;
                    case MTP3_ANSI_TESTING_SSLTA:
                    {

                        int byte;
                        int slc2;
                        int len;
                        GRAB_BYTE(byte,data,idx,maxlen);
                        if(_variant == UMMTP3Variant_ANSI)
                        {
                            len = (byte & 0xF0) >> 4;
                            slc2 = (byte & 0x0F);
                        }
                        else
                        {
                            len = (byte & 0xF0) >> 4;
                            slc2 = label.sls;
                        }
                        if(slc != slc2)
                        {
                            [self logMajorError:@"MTP_DECODE: SSLTA SLC received is not matching the links configured SLC"];
                            [self protocolViolation];
                        }
                        if ((idx+len)>maxlen)
                        {
                            @throw([NSException exceptionWithName:@"MTP_DECODE"
                                                           reason:NULL
                                                         userInfo:@{
                                                                    @"sysmsg" : @"too-short-packet in SLTA",
                                                                    @"func": @(__func__),
                                                                    @"line": @(__LINE__),
                                                                    @"file": @(__FILE__),
                                                                    @"obj":self
                                                                    }
                                    ]);
                        }
                        NSMutableData *pattern = [[NSMutableData alloc]init];
                        [pattern appendBytes:&data[idx] length:len];
                        idx+=len;
                        [self processSSLTA:label
                                   pattern:pattern
                                        ni:ni
                                        mp:mp
                                       slc:slc2
                                      link:link];

                    }
                        break;
                    default:
                        [self logMinorError:[NSString stringWithFormat: @"MTP_PACKET_INVALID: unknown-heading 0x%02X received. Ignored",heading]];
                        @throw([NSException exceptionWithName:@"MTP_PACKET_INVALID"
                                                       reason:NULL
                                                     userInfo:@{
                                                                @"sysmsg" : @"unknown-heading received",
                                                                @"func": @(__func__),
                                                                @"line": @(__LINE__),
                                                                @"file": @(__FILE__),
                                                                @"obj":self
                                                                }
                                ]);
                        break;
                }
            }
                break;
            case MTP3_SERVICE_INDICATOR_TEST:
            {

                /* Signalling network testing and maintenance messages */
                if(_logLevel <= UMLOG_DEBUG)
                {
                    [self logDebug:[NSString stringWithFormat:@"  Service Indicator: [%d] Signalling network testing and maintenance messages",si]];
                }
                int heading;
                GRAB_BYTE(heading,data,idx,maxlen);
                [self updateRxStatisticSi:si headingCode:heading];
                switch(heading)
                {
                    case MTP3_TESTING_SLTM:
                    {
                        int byte;
                        int slc2;
                        int len;
                        GRAB_BYTE(byte,data,idx,maxlen);
                        if(_variant == UMMTP3Variant_ANSI)
                        {
                            len = (byte & 0xF0) >> 4;
                            slc2 = (byte & 0x0F);
                        }
                        else
                        {
                            len = (byte & 0xF0) >> 4;
                            slc2 = label.sls;
                        }
                        if(slc != slc2)
                        {
                            [self logMajorError:@"SLTM: SLC received is not matching the links configured SLC"];
                            [self protocolViolation];
                        }
                        if ((idx+len)>maxlen)
                        {
                            [self logMajorError:[NSString stringWithFormat:@"MTP_PACKET_TOO_SHORT. i = %d, len=%d, maxlen=%d",(int)idx,(int)len,(int)maxlen]];
                            @throw([NSException exceptionWithName:@"MTP_PACKET_TOO_SHORT"
                                                           reason:NULL
                                                         userInfo:@{
                                                                    @"sysmsg" : @"too-short-packet in SLTM",
                                                                    @"func": @(__func__),
                                                                    @"line": @(__LINE__),
                                                                    @"file": @(__FILE__),
                                                                    @"obj":self
                                                                    }
                                    ]);

                        }
                        NSMutableData *pattern = [[NSMutableData alloc]init];
                        [pattern appendBytes:&data[idx] length:len];
                        idx+=len;
                        [self processSLTM:label
                                  pattern:pattern
                                       ni:ni
                                       mp:mp
                                      slc:slc2
                                     link:link];
                    }
                        break;
                    case MTP3_TESTING_SLTA:
                    {
                        int byte;
                        int slc2;
                        int len;
                        GRAB_BYTE(byte,data,idx,maxlen);
                        if(_variant == UMMTP3Variant_ANSI)
                        {
                            len = (byte & 0xF0) >> 4;
                            slc2 = (byte & 0x0F);
                        }
                        else
                        {
                            len = (byte & 0xF0) >> 4;
                            slc2 = label.sls;
                        }
                        if(slc != slc2)
                        {
                            [self logMajorError:@"SLTA SLC received is not matching the links configured SLC"];
                            [self protocolViolation];
                        }
                        if ((idx+len)>maxlen)
                        {
                            [self logMajorError:[NSString stringWithFormat:@"MTP_PACKET_TOO_SHORT. i = %d, len=%d, maxlen=%d",(int)idx,(int)len,(int)maxlen]];
                            @throw([NSException exceptionWithName:@"MTP_PACKET_TOO_SHORT"
                                                           reason:NULL
                                                         userInfo:@{
                                                                    @"sysmsg" : @"too-short-packet in SLTA",
                                                                    @"func": @(__func__),
                                                                    @"line": @(__LINE__),
                                                                    @"file": @(__FILE__),
                                                                    @"obj":self
                                                                    }
                                    ]);

                        }
                        NSMutableData *pattern = [[NSMutableData alloc]init];
                        [pattern appendBytes:&data[idx] length:len];
                        idx+=len;
                        [self processSLTA:label
                                  pattern:pattern
                                       ni:ni
                                       mp:mp
                                      slc:slc2
                                     link:link];

                    }
                        break;
                    default:
                        [self logMajorError:[NSString stringWithFormat:@"MTP_DECODE. unknown-heading 0x%02x",heading]];
                        @throw([NSException exceptionWithName:@"MTP_DECODE"
                                                       reason:NULL
                                                     userInfo:@{
                                                                @"sysmsg" : @"unknown-heading received",
                                                                @"func": @(__func__),
                                                                @"line": @(__LINE__),
                                                                @"file": @(__FILE__),
                                                                @"obj":self
                                                                }
                                ]);

                        break;
                }
            }
                break;
            case MTP3_SERVICE_INDICATOR_MGMT:
            {
                /* Signalling network management messages */

                if(_logLevel <= UMLOG_DEBUG)
                {
                    [self.logFeed debugText:[NSString stringWithFormat:@"  Service Indicator: [%d] Signalling network management messages",si]];
                }
                int heading;
                GRAB_BYTE(heading,data,idx,maxlen);
                [self updateRxStatisticSi:si headingCode:heading];
                switch(heading)
                {
                    case MTP3_MGMT_COO:
                    {
                        int fsn = 0;
                        if(_variant == UMMTP3Variant_ANSI)
                        {
                            int byte0;
                            int byte1;
                            GRAB_BYTE(byte0,data,idx,maxlen);
                            GRAB_BYTE(byte1,data,idx,maxlen);
                            slc = byte0 & 0xF;
                            fsn = byte0 >>4 | ((byte1 & 0x07) << 0x04);
                        }
                        else
                        {
                            slc = label.sls;
                            GRAB_BYTE(fsn,data,idx,maxlen); /* Forward sequence number of last accepted message signal unit (7 bits )*/
                            fsn = fsn & 0x7F;
                        }
                        [self processCOO:label lastFSN:fsn ni:ni mp:mp slc:slc link:link];
                    }
                        break;
                    case MTP3_MGMT_XCO:
                    {
                        int fsn = 0;
                        slc = label.sls;
                        int fsn1;
                        int fsn2;
                        int fsn3;
                        GRAB_BYTE(fsn1,data,idx,maxlen);
                        GRAB_BYTE(fsn2,data,idx,maxlen);
                        GRAB_BYTE(fsn3,data,idx,maxlen);
                        fsn = ((fsn3 << 16) | (fsn2 <<8) | (fsn1));
                        [self processXCO:label lastFSN:fsn ni:ni mp:mp slc:slc link:link];
                    }
                        break;
                    case MTP3_MGMT_XCA:
                    {
                        int fsn;
                        slc = label.sls;
                        int fsn1;
                        int fsn2;
                        int fsn3;
                        GRAB_BYTE(fsn1,data,idx,maxlen);
                        GRAB_BYTE(fsn2,data,idx,maxlen);
                        GRAB_BYTE(fsn3,data,idx,maxlen);
                        fsn = (fsn1 << 16 | fsn2 <<8 | fsn3);
                        [self processXCA:label lastFSN:fsn ni:ni mp:mp slc:slc link:link];
                    }
                        break;

                    case MTP3_MGMT_COA:
                    {
                        int fsn;
                        if(_variant == UMMTP3Variant_ANSI)
                        {
                            int byte0;
                            int byte1;
                            GRAB_BYTE(byte0,data,idx,maxlen);
                            GRAB_BYTE(byte1,data,idx,maxlen);
                            slc = byte0 & 0xF;
                            fsn = byte0 >>4 | ((byte1 & 0x07) << 0x04);
                        }
                        else
                        {
                            slc = label.sls;
                            GRAB_BYTE(fsn,data,idx,maxlen);
                            fsn = fsn & 0x7F;
                        }
                        [self processCOA:label lastFSN:fsn ni:ni mp:mp slc:slc link:link];
                    }
                        break;

                    case MTP3_MGMT_CBD:
                    {
                        int cbc;
                        if(_variant == UMMTP3Variant_ANSI)
                        {
                            int byte0;
                            int byte1;
                            GRAB_BYTE(byte0,data,idx,maxlen);
                            GRAB_BYTE(byte1,data,idx,maxlen);
                            slc = byte0 & 0xF;
                            cbc = byte0 >>4 | ((byte1 & 0x07) << 0x04);
                        }
                        else
                        {
                            slc = label.sls;
                            GRAB_BYTE(cbc,data,idx,maxlen);
                        }
                        [self processCBD:label changeBackCode:cbc ni:ni mp:mp slc:slc link:link];
                    }
                        break;
                    case MTP3_MGMT_CBA:
                    {
                        int cbc;
                        if(_variant == UMMTP3Variant_ANSI)
                        {
                            int byte0;
                            int byte1;
                            GRAB_BYTE(byte0,data,idx,maxlen);
                            GRAB_BYTE(byte1,data,idx,maxlen);
                            slc = byte0 & 0xF;
                            cbc = byte0 >>4 | ((byte1 & 0x07) << 0x04);
                        }
                        else
                        {
                            slc = label.sls;

                            GRAB_BYTE(cbc,data,idx,maxlen);
                        }
                        [self processCBA:label changeBackCode:cbc ni:ni mp:mp slc:slc link:link];
                    }
                        break;
                    case MTP3_MGMT_ECO:
                        [self processECO:label ni:ni mp:mp slc:slc link:link];
                        break;
                    case MTP3_MGMT_ECA:
                        [self processECA:label ni:ni mp:mp slc:slc link:link];
                        break;
                    case MTP3_MGMT_RCT:
                        [self processRCT:label ni:ni mp:mp slc:slc link:link];
                        break;
                    case MTP3_MGMT_TFC: /* Transfer controlled */
                    {
                        int status;
                        UMMTP3PointCode *pc = [[UMMTP3PointCode alloc]initWithBytes:data pos:&idx variant:_variant status:&status maxlen:maxlen];
                        [self processTFC:label destination:pc status:status ni:ni mp:mp slc:slc link:link];
                    }
                        break;
                    case MTP3_MGMT_TFP: /* Transfer Prohibited */
                    {
                        UMMTP3PointCode *pc = [[UMMTP3PointCode alloc]initWithBytes:data pos:&idx variant:_variant maxlen:maxlen];
                        [self processTFP:label destination:pc ni:ni mp:mp slc:slc link:link];
                    }
                        break;
                    case MTP3_MGMT_TFR: /* Transfer Restricted */
                    {
                        UMMTP3PointCode *pc = [[UMMTP3PointCode alloc]initWithBytes:data pos:&idx variant:_variant maxlen:maxlen];
                        [self processTFR:label destination:pc ni:ni mp:mp slc:slc link:link];
                    }
                        break;
                    case MTP3_MGMT_TFA: /* Transfer Allowed */
                    {
                        UMMTP3PointCode *pc = [[UMMTP3PointCode alloc]initWithBytes:data pos:&idx variant:_variant maxlen:maxlen];
                        [self processTFA:label destination:pc ni:ni mp:mp slc:slc link:link];
                    }
                        break;
                    case MTP3_MGMT_RST:
                    {
                        UMMTP3PointCode *pc = [[UMMTP3PointCode alloc]initWithBytes:data pos:&idx variant:_variant];
                        if(_logLevel < UMLOG_DEBUG)
                        {
                            [self.logFeed debugText:[NSString stringWithFormat:@"  H0/H1: [0x%02X] RST Signalling-route-set-test signal for prohibited destination",heading]];
                        }
                        [self processRST:label destination:pc ni:ni mp:mp slc:slc link:link];
                    }
                        break;
                    case MTP3_MGMT_RSR:
                    {
                        UMMTP3PointCode *pc = [[UMMTP3PointCode alloc]initWithBytes:data pos:&idx variant:_variant];
                        [self processRSR:label destination:pc ni:ni mp:mp slc:slc link:link];
                    }
                        break;
                    case MTP3_MGMT_LIN:
                        [self processLIN:label ni:ni mp:mp slc:slc link:link];
                        break;
                    case MTP3_MGMT_LUN:
                        [self processLUN:label ni:ni mp:mp slc:slc link:link];
                        break;
                    case MTP3_MGMT_LIA:
                        [self processLIA:label ni:ni mp:mp slc:slc link:link];
                        break;
                    case MTP3_MGMT_LUA:
                        [self processLUA:label ni:ni mp:mp slc:slc link:link];
                        break;
                    case MTP3_MGMT_LID:
                        [self processLID:label ni:ni mp:mp slc:slc link:link];
                        break;
                    case MTP3_MGMT_LFU:
                        [self processLFU:label ni:ni mp:mp slc:slc link:link];
                        break;
                    case MTP3_MGMT_LLT:
                        [self processLLT:label ni:ni mp:mp slc:slc link:link];
                        break;
                    case MTP3_MGMT_LRT:
                        [self processLRT:label ni:ni mp:mp slc:slc link:link];
                        break;
                    case MTP3_MGMT_TRA:
                        [self processTRA:label ni:ni mp:mp slc:slc link:link];
                        break;
                    case MTP3_MGMT_DLC:
                    {
                        int cic;
                        int slc2 = slc;
                        if(_variant == UMMTP3Variant_ANSI)
                        {
                            int byte0;
                            int byte1;
                            GRAB_BYTE(byte0,data,idx,maxlen);
                            GRAB_BYTE(byte1,data,idx,maxlen);
                            cic  =  byte0 | ((byte1 & 0x0F)  << 8);

                        }
                        else
                        {
                            int byte0;
                            int byte1;
                            int byte2;
                            GRAB_BYTE(byte0,data,idx,maxlen);
                            GRAB_BYTE(byte1,data,idx,maxlen);
                            GRAB_BYTE(byte2,data,idx,maxlen);
                            cic  = (byte0 >> 4) | (byte1 << 4) | ((byte2 & 0x03) << 12);
                            slc2 = byte0 & 0x03;
                        }
                        idx +=2;
                        [self processDLC:label cic:cic ni:ni mp:mp slc:slc2 link:link];
                        break;
                    }
                    case MTP3_MGMT_CSS:
                        [self processCSS:label ni:ni mp:mp slc:slc link:link];
                        break;
                    case MTP3_MGMT_CNS:
                        [self processCNS:label ni:ni mp:mp slc:slc link:link];
                        break;
                    case MTP3_MGMT_CNP:
                        [self processCNP:label ni:ni mp:mp slc:slc link:link];
                        break;
                    case MTP3_MGMT_UPU:
                    {
                        UMMTP3PointCode *pc = [[UMMTP3PointCode alloc]initWithBytes:data pos:&idx variant:_variant];
                        int field = data[idx++];
                        int upid = field & 0x0F;
                        int cause = (field >>4) & 0x0F;

                        [self processUPU:label
                             destination:pc
                              userpartId:(int)upid
                                   cause:(int)cause
                                      ni:(int)ni
                                      mp:(int)mp
                                     slc:(int)slc
                                    link:link];
                    }
                        break;

                        /* ansi cases */
                    case MTP3_MGMT_TRW:
                        [self processTRW:label ni:ni mp:mp slc:slc link:link];
                        break;

                    case MTP3_MGMT_TCP:
                    {
                        UMMTP3PointCode *pc = [[UMMTP3PointCode alloc]initWithBytes:data pos:&idx variant:_variant maxlen:maxlen];
                        [self processTCP:label destination:pc ni:ni mp:mp slc:slc link:link];
                    }
                        break;
                    case MTP3_MGMT_TCR:
                    {
                        UMMTP3PointCode *pc = [[UMMTP3PointCode alloc]initWithBytes:data pos:&idx variant:_variant maxlen:maxlen];
                        [self processTCR:label destination:pc ni:ni mp:mp slc:slc link:link];
                    }
                        break;
                    case MTP3_MGMT_TCA:
                    {
                        UMMTP3PointCode *pc = [[UMMTP3PointCode alloc]initWithBytes:data pos:&idx variant:_variant maxlen:maxlen];
                        [self processTCA:label destination:pc ni:ni mp:mp slc:slc link:link];
                    }
                        break;

                    case MTP3_MGMT_RCP:
                    {
                        UMMTP3PointCode *pc = [[UMMTP3PointCode alloc]initWithBytes:data pos:&idx variant:_variant maxlen:maxlen];
                        [self processRCP:label destination:pc ni:ni mp:mp slc:slc link:link];
                    }
                        break;

                    case MTP3_MGMT_RCR:
                    {
                        UMMTP3PointCode *pc = [[UMMTP3PointCode alloc]initWithBytes:data pos:&idx variant:_variant maxlen:maxlen];
                        [self processRCR:label destination:pc ni:ni mp:mp slc:slc link:link];
                    }
                        break;
                    case MTP3_MGMT_UPA:
                        break;
                    case MTP3_MGMT_UPT:
                        break;
                }
            }
                break;
            case MTP3_SERVICE_INDICATOR_SCCP:
            {
                [self updateRxStatisticSi:si headingCode:0];
                NSData *pdu2 = [NSData dataWithBytes:&data[idx] length:(maxlen-idx)];
                if(_logLevel <= UMLOG_DEBUG)
                {
                    [self.logFeed debugText:[NSString stringWithFormat:@"  Service Indicator: [%d] SCCP",si]];
                    [self.logFeed debugText:[NSString stringWithFormat:@"  Data: %@ ",pdu2]];
                    [self.logFeed debugText:[NSString stringWithFormat:@"  idx=: %d ",idx]];
                }
                [_mtp3 processIncomingPdu:label data:pdu2 userpartId:si ni:ni sls:sls mp:mp linksetName:_name linkset:self];
            }
                break;
            case MTP3_SERVICE_INDICATOR_TUP:
            {
                [self updateRxStatisticSi:si headingCode:0];
                if(_logLevel <= UMLOG_DEBUG)
                {
                    [self.logFeed debugText:[NSString stringWithFormat:@"  Service Indicator: [%d] SPARE_TUP",si]];
                }
                NSData *pdu = [NSData dataWithBytes:data+idx length:maxlen-idx];
                [_mtp3 processIncomingPdu:label data:pdu userpartId:si ni:ni sls:sls mp:mp linksetName:_name linkset:self];

            }
                break;
            case MTP3_SERVICE_INDICATOR_ISUP:
            {
                [self updateRxStatisticSi:si headingCode:0];
                if(_logLevel <= UMLOG_DEBUG)
                {
                    [self.logFeed debugText:[NSString stringWithFormat:@"  Service Indicator: [%d] SPARE_ISUP",si]];
                }
                NSData *pdu = [NSData dataWithBytes:data+idx length:maxlen-idx];
                [_mtp3 processIncomingPdu:label data:pdu userpartId:si ni:ni sls:sls mp:mp linksetName:_name linkset:self];

            }
                break;
            case MTP3_SERVICE_INDICATOR_DUP_C:
            {
                [self updateRxStatisticSi:si headingCode:0];
                if(_logLevel <= UMLOG_DEBUG)
                {
                    [self.logFeed debugText:[NSString stringWithFormat:@"  Service Indicator: [%d] SPARE_DUP_C",si]];
                }
                NSData *pdu = [NSData dataWithBytes:data+idx length:maxlen-idx];
                [_mtp3 processIncomingPdu:label data:pdu userpartId:si ni:ni sls:sls mp:mp linksetName:_name linkset:self];

            }
                break;
            case MTP3_SERVICE_INDICATOR_DUP_F:
            {
                [self updateRxStatisticSi:si headingCode:0];
                if(_logLevel <= UMLOG_DEBUG)
                {
                    [self.logFeed debugText:[NSString stringWithFormat:@"  Service Indicator: [%d] SPARE_DUP_F",si]];
                }
                NSData *pdu = [NSData dataWithBytes:data+idx length:maxlen-idx];
                [_mtp3 processIncomingPdu:label data:pdu userpartId:si ni:ni sls:sls mp:mp linksetName:_name linkset:self];

            }
                break;
            case MTP3_SERVICE_INDICATOR_RES_TESTING:
            {
                [self updateRxStatisticSi:si headingCode:0];
                if(_logLevel <= UMLOG_DEBUG)
                {
                    [self.logFeed debugText:[NSString stringWithFormat:@"  Service Indicator: [%d] SPARE_RES_TESTING",si]];
                }
                NSData *pdu = [NSData dataWithBytes:data+idx length:maxlen-idx];
                [_mtp3 processIncomingPdu:label data:pdu userpartId:si ni:ni sls:sls mp:mp linksetName:_name linkset:self];

            }
                break;
            case MTP3_SERVICE_INDICATOR_BROADBAND_ISUP:
            {
                [self updateRxStatisticSi:si headingCode:0];
                if(_logLevel <= UMLOG_DEBUG)
                {
                    [self.logFeed debugText:[NSString stringWithFormat:@"  Service Indicator: [%d] SPARE_ISUP",si]];
                }
                NSData *pdu = [NSData dataWithBytes:data+idx length:maxlen-idx];
                [_mtp3 processIncomingPdu:label data:pdu userpartId:si ni:ni sls:sls mp:mp linksetName:_name linkset:self];
            }
                break;
            case MTP3_SERVICE_INDICATOR_SAT_ISUP:
            {
                [self updateRxStatisticSi:si headingCode:0];
                if(_logLevel <= UMLOG_DEBUG)
                {
                    [self.logFeed debugText:[NSString stringWithFormat:@"  Service Indicator: [%d] SPARE_SAT_ISUP",si]];
                }
                NSData *pdu = [NSData dataWithBytes:data+idx length:maxlen-idx];
                [_mtp3 processIncomingPdu:label data:pdu userpartId:si ni:ni sls:sls mp:mp linksetName:_name linkset:self];
            }
                break;
            case MTP3_SERVICE_INDICATOR_SPARE_B:
            {
                [self updateRxStatisticSi:si headingCode:0];
                if(_logLevel <= UMLOG_DEBUG)
                {
                    [self.logFeed debugText:[NSString stringWithFormat:@"  Service Indicator: [%d] SPARE_B",si]];
                }
                NSData *pdu = [NSData dataWithBytes:data+idx length:maxlen-idx];
                [_mtp3 processIncomingPdu:label data:pdu userpartId:si ni:ni sls:sls mp:mp linksetName:_name  linkset:self];
            }
                break;
            case MTP3_SERVICE_INDICATOR_SPARE_C:
            {
                [self updateRxStatisticSi:si headingCode:0];
                if(_logLevel <= UMLOG_DEBUG)
                {
                    [self.logFeed debugText:[NSString stringWithFormat:@"  Service Indicator: [%d] SPARE_C",si]];
                }
                NSData *pdu = [NSData dataWithBytes:data+idx length:maxlen-idx];
                [_mtp3 processIncomingPdu:label data:pdu userpartId:si ni:ni sls:sls mp:mp linksetName:_name  linkset:self];
            }
                break;
            case MTP3_SERVICE_INDICATOR_SPARE_D:
            {
                [self updateRxStatisticSi:si headingCode:0];
                if(_logLevel <= UMLOG_DEBUG)
                {
                    [self.logFeed debugText:[NSString stringWithFormat:@"  Service Indicator: [%d] SPARE_D",si]];
                }
                NSData *pdu = [NSData dataWithBytes:data+idx length:maxlen-idx];
                [_mtp3 processIncomingPdu:label data:pdu userpartId:si ni:ni sls:sls mp:mp linksetName:_name linkset:self];
            }
                break;
            case MTP3_SERVICE_INDICATOR_SPARE_E:
            {
                [self updateRxStatisticSi:si headingCode:0];
                if(_logLevel <= UMLOG_DEBUG)
                {
                    [self.logFeed debugText:[NSString stringWithFormat:@"  Service Indicator: [%d] SPARE_E",si]];
                }
                NSData *pdu = [NSData dataWithBytes:data+idx length:maxlen-idx];
                [_mtp3 processIncomingPdu:label data:pdu userpartId:si ni:ni sls:sls mp:mp linksetName:_name linkset:self];
            }
                break;
            case MTP3_SERVICE_INDICATOR_SPARE_F:
            {
                [self updateRxStatisticSi:si headingCode:0];
                if(_logLevel <= UMLOG_DEBUG)
                {
                    [self.logFeed debugText:[NSString stringWithFormat:@"  Service Indicator: [%d] SPARE_F",si]];
                }
                NSData *pdu = [NSData dataWithBytes:data+idx length:maxlen-idx];
                [_mtp3 processIncomingPdu:label data:pdu userpartId:si ni:ni sls:sls mp:mp linksetName:_name  linkset:self];

            }
                break;
        }
    }
    @catch(NSException *e)
    {
        NSDictionary *d = e.userInfo;
        NSString *desc = d[@"sysmsg"];
        NSMutableString *s1 = [[NSMutableString alloc]init];
        [s1 appendFormat:@"Exception: %@\n",desc];
        [s1 appendFormat:@"     Link: %@\n",link.name];
        [s1 appendFormat:@"      PDU: %@\n",pdu.hexString];
        [s1 appendFormat:@"    Label: %@\n",label];
        [s1 appendFormat:@"       SI: %d\n",si];
        [s1 appendFormat:@"       NI: %d\n",ni];
        [s1 appendFormat:@"       SLS: %d\n",sls];
        [s1 appendFormat:@"       MP: %d\n",mp];
        [s1 appendFormat:@"      SLC: %d\n",slc];
        if(network_appearance > 0)
        {
            [s1 appendFormat:@"      network_appearance: %@\n",network_appearance.hexString];
        }
        if(correlation_id.length > 0)
        {
            [s1 appendFormat:@"      correlation_id: %@\n",correlation_id.hexString];
        }
        if(routing_context.length > 0)
        {
            [s1 appendFormat:@"      routing_context: %@\n",routing_context.hexString];
        }
        NSLog(@"%@",s1);
        [self.logFeed majorErrorText:s1];
        return;
    }
}

- (BOOL) isFromAdjacentToLocal:(UMMTP3Label *)label
{
    if(![label.dpc isEqualToPointCode:self.localPointCode])
    {
        return NO;
    }
    if(![label.opc isEqualToPointCode:self.adjacentPointCode])
    {
        return NO;
    }
    return YES;
}

- (void)processSLTM:(UMMTP3Label *)label
            pattern:(NSData *)pattern
                 ni:(int)ni
                 mp:(int)mp
                slc:(int)slc
               link:(UMMTP3Link *)link
{
    if(link.current_m2pa_status != M2PA_STATUS_ALIGNED_READY)
    {
        [self m2paStatusUpdate:M2PA_STATUS_IS slc:slc];
    }
    else if(link.current_m2pa_status != M2PA_STATUS_IS)
    {
        [self logWarning:[NSString stringWithFormat:@"Warning: SLTM while in status %d",link.current_m2pa_status]];
        [self m2paStatusUpdate:M2PA_STATUS_IS slc:slc];
    }
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"processSLTM"];
    }
    if(![self isFromAdjacentToLocal:label])
    {
        self.lastError = [NSString stringWithFormat:@"unexpected SLTM transiting Label = %@. Should be %@->%@", label.logDescription,_adjacentPointCode.logDescription,_localPointCode.logDescription];
        [self logMajorError:self.lastError];
        [self protocolViolation];
        link.receivedInvalidSLTM++;
        return;
    }
    link.receivedSLTM++;
    UMMTP3Label *reverse_label = [label reverseLabel];
    if(_overrideNetworkIndicator)
    {
        [self sendSLTA:reverse_label pattern:pattern ni:(_overrideNetworkIndicator.intValue) mp:mp slc:slc link:link];
    }
    else
    {
        [self sendSLTA:reverse_label pattern:pattern ni:ni mp:mp slc:slc link:link];
    }
    [self updateLinkSetStatus];
}

- (void)processSLTA:(UMMTP3Label *)label
            pattern:(NSData *)pattern
                 ni:(int)ni
                 mp:(int)mp
                slc:(int)slc
               link:(UMMTP3Link *)link
{
  	[link stopLinkTestAckTimer];
  	link.outstandingSLTA = 0;
    [link.m2pa.stateMachineLogFeed debugText:[NSString stringWithFormat:@"SLTA received (outstanding SLTA=%d on SLC=%d)",link.outstandingSLTA,link.slc]];
    if(link.current_m2pa_status != M2PA_STATUS_IS)
    {
        [self logWarning:[NSString stringWithFormat:@"Warning: SLTA while in status %d",link.current_m2pa_status]];
        [self m2paStatusUpdate:M2PA_STATUS_IS slc:slc];
    }

    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"processSLTA"];
    }

    if(![self isFromAdjacentToLocal:label])
    {
        NSString *s = [NSString stringWithFormat:@"unexpected SLTA transiting Label = %@. Should be %@->%@", label.logDescription,_adjacentPointCode.logDescription,_localPointCode.logDescription];
        [self logMajorError:s];
        [link.m2pa.stateMachineLogFeed debugText:s];
        [self protocolViolation];
        link.receivedInvalidSLTA++;
        return;
    }
    link.receivedSLTA++;
    if(link.awaitFirstSLTA)
    {
        link.awaitFirstSLTA=NO;
        UMMTP3Label *reverse_label = [label reverseLabel];
        [self sendTRA:reverse_label ni:ni mp:mp slc:slc link:link];
        [self updateRouteAvailable:_adjacentPointCode
                              mask:_adjacentPointCode.maxmask
                          priority:UMMTP3RoutePriority_1
                            reason:@"first SLTA"];
    }
    [self updateLinkSetStatus];
}

- (void)processSSLTM:(UMMTP3Label *)label
            pattern:(NSData *)pattern
                 ni:(int)ni
                 mp:(int)mp
                slc:(int)slc
               link:(UMMTP3Link *)link
{
    [link stopLinkTestAckTimer];
    link.outstandingSSLTA = 0;
    if(link.current_m2pa_status != M2PA_STATUS_IS)
    {
        [self logWarning:[NSString stringWithFormat:@"Warning: SSLTM while in status %d",link.current_m2pa_status]];
        [self m2paStatusUpdate:M2PA_STATUS_IS slc:slc];
    }

    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"processSSLTM"];
    }

    if(![self isFromAdjacentToLocal:label])
    {
        [self logMajorError:[NSString stringWithFormat:@"unexpected SSTLM transiting Label = %@. Should be %@->%@", label.logDescription,_adjacentPointCode.logDescription,_localPointCode.logDescription]];
        link.receivedInvalidSSLTM--;
        [self protocolViolation];
        return;
    }
    link.receivedSSLTM++;
    UMMTP3Label *reverse_label = [label reverseLabel];
    [self sendSSLTA:reverse_label pattern:pattern ni:ni mp:mp slc:slc link:link];
}
    

- (void)processSSLTA:(UMMTP3Label *)label
             pattern:(NSData *)pattern
                  ni:(int)ni
                  mp:(int)mp
                 slc:(int)slc
                link:(UMMTP3Link *)link
{
    [link stopLinkTestAckTimer];
    link.outstandingSSLTA = 0;
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"processSSLTA"];
    }
    if(link.current_m2pa_status != M2PA_STATUS_IS)
    {
        [self logWarning:[NSString stringWithFormat:@"Warning: SSLTA while in status %d",link.current_m2pa_status]];
        [self updateLinkSetStatus];
        [self m2paStatusUpdate:M2PA_STATUS_IS slc:slc];
    }

    if(![self isFromAdjacentToLocal:label])
    {
        [self logMajorError:[NSString stringWithFormat:@"unexpected SSLTA transiting Label = %@. Should be %@->%@", label.logDescription,_adjacentPointCode.logDescription,_localPointCode.logDescription]];
        [self protocolViolation];
        link.receivedInvalidSSLTA--;
        return;
    }
    link.receivedSSLTA++;
    if(link.awaitFirstSLTA)
    {
        link.awaitFirstSLTA=NO;
        UMMTP3Label *reverse_label = [label reverseLabel];
        [self sendTRA:reverse_label ni:ni mp:mp slc:slc link:link];
        [self updateRouteAvailable:_adjacentPointCode
                              mask:_adjacentPointCode.maxmask
                          priority:UMMTP3RoutePriority_1
                            reason:@"first STLA"];
    }
    [self updateLinkSetStatus];
}


/* Group CHM */
- (void)processCOO:(UMMTP3Label *)label lastFSN:(int)fsn ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"processCOO (Changeover-order signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" lastFSN: %d",fsn]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",self.name]];
    }
    UMMTP3PointCode *translatedPc = [self remoteToLocalPointcode:label.opc];
    if(translatedPc.pc == _mtp3.opc.pc)
    {
        [self logDebug:@"ignoring COO from own pointcode"];
    }
    else if(translatedPc.pc == _adjacentPointCode.pc)
    {
        [self updateRouteUnavailable:translatedPc
                                mask:translatedPc.maxmask
                            priority:UMMTP3RoutePriority_1
                              reason:@"COO"];
    }
    else
    {
        [self updateRouteUnavailable:translatedPc
                                mask:translatedPc.maxmask
                            priority:UMMTP3RoutePriority_5
                              reason:@"COO"];
    }

    [self sendCOA:[label reverseLabel] lastFSN:fsn ni:ni mp:mp slc:slc link:link];
}


- (void)processCOA:(UMMTP3Label *)label lastFSN:(int)fsn ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"processCOA (Changeover-acknowledgement signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" lastFSN: %d",fsn]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",self.name]];
    }
}

- (void)processXCO:(UMMTP3Label *)label
           lastFSN:(int)fsn
                ni:(int)ni
                mp:(int)mp
               slc:(int)slc
              link:(UMMTP3Link *)link
{

    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"processXCO (Extended Changeover)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" lastFSN: %d",fsn]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",self.name]];
    }
    
    UMMTP3PointCode *translatedPc = [self remoteToLocalPointcode:label.opc];
    if(translatedPc.pc == _mtp3.opc.pc)
    {
        [self logDebug:@"ignoring XCO from own pointcode"];
    }
    else if(translatedPc.pc == _adjacentPointCode.pc)
    {
        [self updateRouteUnavailable:translatedPc
                                mask:translatedPc.maxmask
                            priority:UMMTP3RoutePriority_1
                              reason:@"XCO"];
    }
    else
    {
        [self updateRouteUnavailable:translatedPc
                                mask:translatedPc.maxmask
                            priority:UMMTP3RoutePriority_5
                              reason:@"XCO"];
    }
    
    UMMTP3Label *reverse_label;
    reverse_label = [label reverseLabel];
    [self sendXCA:reverse_label lastFSN:fsn ni:ni mp:mp slc:slc link:link];
}

- (void)processXCA:(UMMTP3Label *)label lastFSN:(int)fsn ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"processXCA (Extended Changeover Acknowledgement signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" lastFSN: %d",fsn]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",self.name]];
    }
}

- (void)processCBD:(UMMTP3Label *)label changeBackCode:(int)cbc ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"processCBD (Changeback-declaration signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" changeBackCode: %d",cbc]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",self.name]];
    }
    
    UMMTP3PointCode *translatedPc = [self remoteToLocalPointcode:label.opc];
    if(translatedPc.pc == _mtp3.opc.pc)
    {
        [self logDebug:@"ignoring CBD for own pointcode"];
    }
    else if(translatedPc.pc == _adjacentPointCode.pc)
    {
        [self updateRouteAvailable:translatedPc
                              mask:translatedPc.maxmask
                          priority:UMMTP3RoutePriority_1
                            reason:@"CBD from adjacent"];
    }
    else
    {
        [self updateRouteAvailable:translatedPc
                              mask:translatedPc.maxmask
                          priority:UMMTP3RoutePriority_5
                            reason:@"CBD from non-adjacent"];
    }
    [self sendCBA:[label reverseLabel] changeBackCode:cbc ni:ni mp:mp slc:slc link:link];
}

- (void)processCBA:(UMMTP3Label *)label changeBackCode:(int)cbc ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"processCBA (Changeback-acknowledgement signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" changeBackCode: %d",cbc]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",self.name]];
    }
}

/* Group ECM */
- (void)processECO:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"processECO (Emergency-changeover-order signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",self.name]];
    }
}

- (void)processECA:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"processECA (Emergency-changeover-acknowledgement signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",self.name]];
    }
    
}

/* Group FCM */
- (void)processRCT:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"processRCT (Signalling-route-set-congestion-test signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",self.name]];
    }
}

- (void)processTFC:(UMMTP3Label *)label destination:(UMMTP3PointCode *)pc status:(int)status ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    UMMTP3PointCode *translatedPc = [self remoteToLocalPointcode:pc];
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"processTFC (Transfer-controlled signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" destination: %@",translatedPc.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",self.name]];
    }
    
    if(translatedPc.pc == _mtp3.opc.pc)
    {
        [self logDebug:@"ignoring TFC for own pointcode"];
    }
    else if(translatedPc.pc == _adjacentPointCode.pc)
    {
        [self logDebug:@"TFC for adjacent pointcode"];
        [self updateRouteRestricted:translatedPc
                               mask:translatedPc.maxmask
                           priority:UMMTP3RoutePriority_1
                             reason:@"TFC from adjacent"];
    }
    else
    {
        [self updateRouteRestricted:translatedPc
                              mask:translatedPc.maxmask
                          priority:UMMTP3RoutePriority_5
                            reason:@"TFC from non-adjacent"];
    }
}

/* Group TFM */
- (int) defaultMask
{
    int mask;
    switch(_variant)
    {
        case UMMTP3Variant_ANSI:
        case UMMTP3Variant_China:
            mask = 0x00FFFFFF;
            break;

        default:
            mask = 0x00003FFF;
            break;
    }
    return mask;
}

- (void)processTFP:(UMMTP3Label *)label
       destination:(UMMTP3PointCode *)pc
                ni:(int)ni
                mp:(int)mp
               slc:(int)slc
              link:(UMMTP3Link *)link
{
    UMMTP3PointCode *translatedPc = [self remoteToLocalPointcode:pc];

    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"processTFP (Transfer-prohibited signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" destination: %@",translatedPc.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",self.name]];
    }
    if(translatedPc.pc == _mtp3.opc.pc)
    {
        [self logDebug:@"ignoring TFP for own pointcode"];
    }
    if(translatedPc.pc == _adjacentPointCode.pc)
    {
        [self updateRouteUnavailable:translatedPc
                                mask:translatedPc.maxmask
                            priority:UMMTP3RoutePriority_1
                              reason:@"TFP"];
    }
    else
    {
        [self updateRouteUnavailable:translatedPc
                                mask:translatedPc.maxmask
                            priority:UMMTP3RoutePriority_5
                              reason:@"TFP"];
    }
}


- (void)processTFR:(UMMTP3Label *)label
       destination:(UMMTP3PointCode *)pc
                ni:(int)ni
                mp:(int)mp
               slc:(int)slc
              link:(UMMTP3Link *)link
{
    UMMTP3PointCode *translatedPc = [self remoteToLocalPointcode:pc];

    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"processTFR (Transfer-restricted signal (national option))"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" destination: %@",translatedPc.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",self.name]];
    }
    if(translatedPc.pc == _mtp3.opc.pc)
    {
        [self logDebug:@"ignoring TFR for own pointcode"];
    }
    else if(translatedPc.pc == _adjacentPointCode.pc)
    {
        [self updateRouteRestricted:translatedPc
                               mask:translatedPc.maxmask
                           priority:UMMTP3RoutePriority_1
                             reason:@"TFR from adjacent"];
    }
    else
    {
        [self updateRouteRestricted:translatedPc
                               mask:translatedPc.maxmask
                           priority:UMMTP3RoutePriority_5
                             reason:@"TFR from non adjacent"];
    }
}


/**
 *
 * This performs special TFA procedures for STPs.  When rerouting traffic away from a route list, to
 * a lower cost route list, send TFA/TCA for the rerouted traffic to let the adjacent signalling
 * point know that it can now route traffic via this STP.
 *
 * Note that we ignore the error on sending TFA or TCA, because if we fail to send it now, the route
 * set test procedures of the adjacent signalling point will discover the situation.  Also, if we
 * are short of buffers, we do not mind that the adjacent signalling point does not yet know of our
 * availability for these routes.
 */

- (void)processTFA:(UMMTP3Label *)label
       destination:(UMMTP3PointCode *)pc
                ni:(int)ni
                mp:(int)mp
               slc:(int)slc
              link:(UMMTP3Link *)link
{
    UMMTP3PointCode *translatedPc = [self remoteToLocalPointcode:pc];

    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"processTFA (Transfer-allowed signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" destination: %@",translatedPc.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",self.name]];
    }
    if(translatedPc.pc == _mtp3.opc.pc)
    {
        [self logDebug:@"ignoring TFA for own pointcode"];
    }
    else if(translatedPc.pc == _adjacentPointCode.pc)
    {
        [self updateRouteAvailable:translatedPc
                              mask:translatedPc.maxmask
                          priority:UMMTP3RoutePriority_1
                            reason:@"TFA from adjacent"];
    }
    else
    {
        [self updateRouteAvailable:translatedPc
                              mask:translatedPc.maxmask
                          priority:UMMTP3RoutePriority_5
                            reason:@"TFA from non-adjacent"];
    }
}



/* Group RSM */
- (void)processRST:(UMMTP3Label *)label destination:(UMMTP3PointCode *)pc ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    UMMTP3PointCode *translatedPc = [self remoteToLocalPointcode:pc];
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"processRST (Signalling-route-set-test signal for prohibited destination)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" destination: %@",translatedPc.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",self.name]];
    }
    /* TODO: check if route is available and send TFA/TFP/TFR back accordingly */
    
    UMMTP3Label *reverse_label = [label reverseLabel];
    UMMTP3RouteStatus routeStatus = [_mtp3 getRouteStatus:pc];
    switch(routeStatus)
    {
        case UMMTP3_ROUTE_PROHIBITED:
            [self sendTFP:reverse_label
              destination:pc
                       ni:ni
                       mp:mp
                      slc:slc
                     link:link];
            break;
        case UMMTP3_ROUTE_RESTRICTED:
            [self sendTFR:reverse_label
              destination:pc
                       ni:ni
                       mp:mp
                      slc:slc
                     link:link];
            break;
        case UMMTP3_ROUTE_UNUSED:
        case UMMTP3_ROUTE_UNKNOWN:
        case UMMTP3_ROUTE_ALLOWED:
            [self sendTFA:reverse_label
              destination:pc
                       ni:ni
                       mp:mp
                      slc:slc
                     link:link];
            break;
    }
}

- (void)processRSR:(UMMTP3Label *)label destination:(UMMTP3PointCode *)pc ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    UMMTP3PointCode *translatedPc = [self remoteToLocalPointcode:pc];

    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"processRSR (Signalling-route-set-test signal for restricted destination (national option))"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" destination: %@",translatedPc.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",self.name]];
    }
    UMMTP3Label *reverse_label = [label reverseLabel];
    UMMTP3RouteStatus routeStatus = [_mtp3 getRouteStatus:pc];
    switch(routeStatus)
    {
        case UMMTP3_ROUTE_PROHIBITED:
            [self sendTFP:reverse_label
              destination:pc
                       ni:ni
                       mp:mp
                      slc:slc
                     link:link];
            break;
        case UMMTP3_ROUTE_RESTRICTED:
            [self sendTFR:reverse_label
              destination:pc
                       ni:ni
                       mp:mp
                      slc:slc
                     link:link];
            break;
        case UMMTP3_ROUTE_UNUSED:
        case UMMTP3_ROUTE_UNKNOWN:

        case UMMTP3_ROUTE_ALLOWED:
            [self sendTFA:reverse_label
              destination:pc
                       ni:ni
                       mp:mp
                      slc:slc
                     link:link];
            break;
    }
}

/* Group MIM */
- (void)processLIN:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"processLIN (Link inhibit signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",self.name]];
    }
}

- (void)processLUN:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"processLUN (Link uninhibit signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",self.name]];
    }
    
}

- (void)processLIA:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"processLIA (Link inhibit acknowledgement signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",self.name]];
    }
    
}

- (void)processLUA:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"processLUA (Link uninhibit acknowledgement signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",self.name]];
    }
    
}

- (void)processLID:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"processLID (Link inhibit denied signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",self.name]];
    }
    
}

- (void)processLFU:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"processLFU (Link forced uninhibit signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",self.name]];
    }
    
}

- (void)processLLT:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"processLLT (Link local inhibit test signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",self.name]];
    }
}

- (void)processLRT:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"processLRT (Link remote inhibit test signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",self.name]];
    }
}

/* Group TRM */
- (void)processTRA:(UMMTP3Label *)label
                ni:(int)ni
                mp:(int)mp
               slc:(int)slc
              link:(UMMTP3Link *)link
{
    if(link.current_m2pa_status != M2PA_STATUS_IS)
    {
        [self logWarning:[NSString stringWithFormat:@"Warning: TRA while in status %d",link.current_m2pa_status]];
    }

    [self updateLinkSetStatus];
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"processTRA (Traffic-restart-allowed signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",self.name]];
    }
    [self updateRouteAvailable:_adjacentPointCode
                          mask:_adjacentPointCode.maxmask
                      priority:UMMTP3RoutePriority_1
                        reason:@"TRA"];
    _mtp3.ready=YES;
}


/**
 * TRW
 *
 * ANSI T1.111.4/2000 9.4 (Actions in Signalling Point X on Receipt of an Unexpected TRA or TRW
 * Message.)  If an unexpected traffic restart allowed message or traffic restart waiting message is
 * received from an adjacent point,
 *
 * (1) If the receiving point has no transfer function it returns a traffic restart allowed message
 *     to the adjacent point from which the unexpected traffic restart allowed or traffic restart
 *     waiting message was received and starts time T29 concerning that point.
 *
 * (2) If the receiving point has the transfer function function, it starts timer T30, sends a
 *     traffic restart waiting message followed by the necessary transfer-restricted and
 *     transfer-prohibited messages (preventative transfer prohibited messages according to 13.2.2
 *     (1) are required for traffic currently being routed via the point from which the unexpected
 *     traffic restart allowed or traffic restart waiting message was received), and a traffic
 *     restart allowed message.  It then stops T30 and starts T29.  In the abnormal case that T30
 *     expires before the sending of transfer-prohibited and transfer-restricted messages is
 *     complete, it sends a traffic restart allowed message, starts T29, and then completes sending
 *     any preventative transfer-prohibited messages according to 13.2.2 (1) for traffic currently
 *     being routed via the point from which the unexpected traffic restart allowed or traffic
 *     restart waiting message was received.
 *
 * NOTE: A received traffic restart waiting or traffic restart allowed message is not unexpected if
 * T22, T23 or T24 is running and a direct link is in service at level 2 to the point from which the
 * message is received or if T25, T28, T29 or T30 is running for the point from which the message is
 * received.
 *
 * ANSI T1.111.4/2000 9.3 ... (1) If a TRW message is received from Y while T28 is running, or
 * before it is started, X starts T25.  X stops T28 if it is running.  (2) If a TRW message is
 * received from Y while T25 is running, X restarts T25.
 *
 * IMPLEMENTATION NOTES:-
 * - TRW is only sent from an signalling point to an adjacent signalling point, only on a direct
 *   link set.
 * - TRW message is addressed to the remote adjacent signalling point from the local adjacent
 *   signalling point.
 * - TRW is only sent by a signalling point having the transfer function (i.e.  and STP).
 * - TRW is sent followed by transfer-prohibited and transfer-restricted messages, followed by TRA.
 * - TRW is sent by the adjacent signalling point only when it, or the local signalling point, or
 *   both, are restarting (i.e. after the first signalling link in the direct link set becomes
 *   available at level 2).
 *
 * mtp_lookup_rt() performs appropriate screening for TRW and TRA messages.
 */

- (void)processTRW:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_variant != UMMTP3Variant_ANSI)
    {
        [self logMajorError:@"unexpected TRW packet in non ANSI mode"];
        [self logMajorError:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logMajorError:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logMajorError:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logMajorError:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logMajorError:[NSString stringWithFormat:@" linkset: %@",self.name]];
        [self protocolViolation];
        return;
    }
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"processTRW (Traffic Restart Waiting (ANSI only))"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",self.name]];
    }
    
    if(![self isFromAdjacentToLocal:label])
    {
        [self logMajorError:[NSString stringWithFormat:@"unexpected STLM transiting Label = %@. Should be %@->%@", label.logDescription,_adjacentPointCode.logDescription,_localPointCode.logDescription]];
        [self protocolViolation];
        return;
    }
    [self sendTRA:label.reverseLabel ni:ni mp:mp slc:slc link:link];
}

/**
 * mtp_tfa_broadcast: - TFA/TCA broadcast
 * @q: active queue
 * @rs: routset for which to broadcast
 *
 * Perform local and adjacent (if STP) broadcast of route set allowed, including an old non-primary
 * link set, but not a new non-primary link set which receives a directed TFP, and not on a primary
 * link set which receives nothing.
 *
 * 13.3.1 ... Transfer-allowed message are always address to an adjacent signalling point.  They may
 * use any available signalling route that leads to that signalling point.
 *
 * 13.3.2  A transfer-allowed message relating to a given destination X is sent form signalling
 * transfer point Y in the following cases:
 *
 * i)  When signalling transfer point Y stops routing (at changeback or controlled re-routing),
 *     signalling traffic destined to signalling point X via a signalling transfer point Z (to which
 *     the concerned traffic was previously diverted as a consequence of changeover or forced
 *     rerouting).  In this case, the transfer-allowed message is sent to signalling transfer point
 *     Z.
 *
 * ii) When signalling transfer point Y recognizes that it is again able to transfer signalling
 *     traffic destined to signalling point X (see 6.2.3 and 8.2.3).  In this case a
 *     transfer-allowed message is sent to all accessible adjacent signalling points, except those
 *     signalling points that receive a TFP message according to 13.2.2 i) and except signalling
 *     point X if it is an adjacent point. (Broadcast Method).
 */

- (void)processTCA:(UMMTP3Label *)label destination:(UMMTP3PointCode *)pc ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    UMMTP3PointCode *translatedPc = [self remoteToLocalPointcode:pc];

    if(_variant != UMMTP3Variant_ANSI)
    {
        [self logMajorError:@"unexpected TCA packet in non ANSI mode"];
        [self logMajorError:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logMajorError:[NSString stringWithFormat:@" destination: %@",translatedPc]];
        [self logMajorError:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logMajorError:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logMajorError:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logMajorError:[NSString stringWithFormat:@" linkset: %@",self.name]];
        return;
    }
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"processTCA"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logMajorError:[NSString stringWithFormat:@" destination: %@",translatedPc]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",self.name]];
    }
}


- (void)processTCP:(UMMTP3Label *)label destination:(UMMTP3PointCode *)pc ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    UMMTP3PointCode *translatedPc = [self remoteToLocalPointcode:pc];

    if(_variant != UMMTP3Variant_ANSI)
    {
        [self logMajorError:@"unexpected TCP packet in non ANSI mode"];
        [self logMajorError:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logMajorError:[NSString stringWithFormat:@" destination: %@",translatedPc]];
        [self logMajorError:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logMajorError:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logMajorError:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logMajorError:[NSString stringWithFormat:@" linkset: %@",self.name]];
        return;
    }
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"processTCP"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logMajorError:[NSString stringWithFormat:@" destination: %@",translatedPc]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",self.name]];
    }
}

- (void)processTCR:(UMMTP3Label *)label destination:(UMMTP3PointCode *)pc ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    UMMTP3PointCode *translatedPc = [self remoteToLocalPointcode:pc];

    if(_variant != UMMTP3Variant_ANSI)
    {
        [self logMajorError:@"unexpected TCR packet in non ANSI mode"];
        [self logMajorError:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logMajorError:[NSString stringWithFormat:@" destination: %@",translatedPc]];
        [self logMajorError:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logMajorError:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logMajorError:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logMajorError:[NSString stringWithFormat:@" linkset: %@",self.name]];
        return;
    }
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"processTCR"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logMajorError:[NSString stringWithFormat:@" destination: %@",translatedPc]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",self.name]];
    }
}

- (void)processRCP:(UMMTP3Label *)label destination:(UMMTP3PointCode *)pc ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    UMMTP3PointCode *translatedPc = [self remoteToLocalPointcode:pc];

    if(_variant != UMMTP3Variant_ANSI)
    {
        [self logMajorError:@"unexpected RCP packet in non ANSI mode"];
        [self logMajorError:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logMajorError:[NSString stringWithFormat:@" destination: %@",translatedPc]];
        [self logMajorError:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logMajorError:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logMajorError:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logMajorError:[NSString stringWithFormat:@" linkset: %@",self.name]];
        return;
    }
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"processRCP"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logMajorError:[NSString stringWithFormat:@" destination: %@",translatedPc]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",self.name]];
    }
}

- (void)processRCR:(UMMTP3Label *)label destination:(UMMTP3PointCode *)pc ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    UMMTP3PointCode *translatedPc = [self remoteToLocalPointcode:pc];

    if(_variant != UMMTP3Variant_ANSI)
    {
        [self logMajorError:@"unexpected RCR packet in non ANSI mode"];
        [self logMajorError:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logMajorError:[NSString stringWithFormat:@" destination: %@",translatedPc]];
        [self logMajorError:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logMajorError:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logMajorError:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logMajorError:[NSString stringWithFormat:@" linkset: %@",self.name]];
        return;
    }
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"processRCR"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logMajorError:[NSString stringWithFormat:@" destination: %@",translatedPc]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",self.name]];
    }
}




/* group DLM */
- (void)processDLC:(UMMTP3Label *)label cic:(int)cic ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"processDLC (Signalling-data-link-connection-order signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" cic: %d",cic]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",self.name]];
    }
    
}

- (void)processCSS:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"processCSS (Connection-successful signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",self.name]];
    }
    
}

- (void)processCNS:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"processCNS (Connection-not-successful signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",self.name]];
    }
    
}

- (void)processCNP:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"processCNP (Connection-not-possible signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",self.name]];
    }
    
    
}
/* group UFC */
- (void)processUPU:(UMMTP3Label *)label destination:(UMMTP3PointCode *)pc userpartId:(int)upid cause:(int)cause ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    UMMTP3PointCode *translatedPc = [self remoteToLocalPointcode:pc];

    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"processUPU (User part unavailable signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" destination: %@",translatedPc.description]];
        [self logDebug:[NSString stringWithFormat:@" userpartId: %d",upid]];
        [self logDebug:[NSString stringWithFormat:@" cause: %d",cause]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",self.name]];
    }
    
}

#pragma mark -
#pragma mark Send Routines

- (void)sendSLTA:(UMMTP3Label *)label
         pattern:(NSData *)pattern
              ni:(int)ni
              mp:(int)mp
             slc:(int)slc
            link:(UMMTP3Link *)link
{
    if(_overrideNetworkIndicator)
    {
        ni = _overrideNetworkIndicator.intValue;
    }
    NSMutableData *pdu = [[NSMutableData alloc]init];
    if(_variant==UMMTP3Variant_ANSI)
    {
        [pdu appendByte:([pattern length]<<4) | (slc & 0x0F)];
        
    }
    else
    {
        [pdu appendByte:([pattern length]<<4)];
    }
    [pdu appendData:pattern];
    
    if(_logLevel <=UMLOG_DEBUG)
    {
           [self logDebug:@"sendSLTA (Signaling Link Test Answer)"];
           [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
           [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
           [self logDebug:[NSString stringWithFormat:@" mp: %d",mp]];
           [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
           [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
           [self logDebug:[NSString stringWithFormat:@" linkset: %@",_name]];
           [self logDebug:[NSString stringWithFormat:@" pattern: %@",pattern]];
    }
    link.sentSLTA++;
    [self sendPdu:pdu
            label:label
          heading:MTP3_TESTING_SLTA
             link:link
              slc:slc
               ni:ni
               mp:mp
               si:MTP3_SERVICE_INDICATOR_TEST
       ackRequest:NULL
          options:NULL];
}



- (void)sendSLTM:(UMMTP3Label *)label
         pattern:(NSData *)pattern
              ni:(int)ni
              mp:(int)mp
             slc:(int)slc
            link:(UMMTP3Link *)link
{
    if(link.firstSLTMSent == NO)
    {
        link.firstSLTMSent = YES;
        link.outstandingSLTA = 0;
    }
    else
    {
        link.outstandingSLTA++;
    }
	[link startLinkTestAckTimer];
    if(_overrideNetworkIndicator)
    {
        ni = _overrideNetworkIndicator.intValue;
    }
   NSMutableData *pdu = [[NSMutableData alloc]init];
    if(_variant==UMMTP3Variant_ANSI)
    {
        [pdu appendByte:([pattern length]<<4) | (slc & 0x0F)];

    }
    else
    {
        [pdu appendByte:([pattern length]<<4)];
    }
    [pdu appendData:pattern];
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"sendSLTM (Signaling Link Test Message)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" mp: %d",mp]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",_name]];
        [self logDebug:[NSString stringWithFormat:@" pattern: %@",pattern]];
    }
    label.sls = slc;
    link.sentSLTM++;
    [self sendPdu:pdu
            label:label
          heading:MTP3_TESTING_SLTM
             link:link
              slc:slc
               ni:ni
               mp:mp
               si:MTP3_SERVICE_INDICATOR_TEST
       ackRequest:NULL
          options:NULL];
    
}

- (void)sendSSLTA:(UMMTP3Label *)label
          pattern:(NSData *)pattern
               ni:(int)ni
               mp:(int)mp
              slc:(int)slc
             link:(UMMTP3Link *)link
{
    if(_overrideNetworkIndicator)
    {
        ni = _overrideNetworkIndicator.intValue;
    }

    NSMutableData *pdu = [[NSMutableData alloc]init];
    if(_variant==UMMTP3Variant_ANSI)
    {
        [pdu appendByte:([pattern length]<<4) | (slc & 0x0F)];
        
    }
    else
    {
        [pdu appendByte:([pattern length]<<4)];
    }
    [pdu appendData:pattern];
    label.sls = slc;
    
    if(_logLevel <=UMLOG_DEBUG)
    {
           [self logDebug:@"sendSSLTA"];
           [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
           [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
           [self logDebug:[NSString stringWithFormat:@" mp: %d",mp]];
           [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
           [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
           [self logDebug:[NSString stringWithFormat:@" linkset: %@",_name]];
           [self logDebug:[NSString stringWithFormat:@" pattern: %@",pattern]];
    }
    link.sentSSLTA++;
    [self sendPdu:pdu
            label:label
          heading:MTP3_ANSI_TESTING_SSLTA
             link:link
              slc:slc
               ni:ni
               mp:mp
               si:MTP3_ANSI_SERVICE_INDICATOR_TEST
       ackRequest:NULL
          options:NULL];

}

- (void)sendSSLTM:(UMMTP3Label *)label
         pattern:(NSData *)pattern
              ni:(int)ni
              mp:(int)mp
             slc:(int)slc
            link:(UMMTP3Link *)link
{
    if(_overrideNetworkIndicator)
    {
        ni = _overrideNetworkIndicator.intValue;
    }

    NSMutableData *pdu = [[NSMutableData alloc]init];
    if(_variant==UMMTP3Variant_ANSI)
    {
        [pdu appendByte:([pattern length]<<4) | (slc & 0x0F)];
    }
    else
    {
        [pdu appendByte:([pattern length]<<4)];
    }
    [pdu appendData:pattern];
    
    if(_logLevel <=UMLOG_DEBUG)
    {
           [self logDebug:@"sendSSLTM"];
           [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
           [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
           [self logDebug:[NSString stringWithFormat:@" mp: %d",mp]];
           [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
           [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
           [self logDebug:[NSString stringWithFormat:@" linkset: %@",_name]];
           [self logDebug:[NSString stringWithFormat:@" pattern: %@",pattern]];
    }
	link.sentSSLTM++;
    [self sendPdu:pdu
            label:label
          heading:MTP3_ANSI_TESTING_SSLTM
             link:link
              slc:slc
               ni:ni
               mp:mp
               si:MTP3_ANSI_SERVICE_INDICATOR_TEST
       ackRequest:NULL
          options:NULL];
}


-(void)sendPdu:(NSData *)data
         label:(UMMTP3Label *)label
       heading:(int)heading
          link:(UMMTP3Link *)link
           slc:(int)slc
            ni:(int)ni
            mp:(int)mp
            si:(int)si
    ackRequest:(NSDictionary *)ackRequest
       options:(NSDictionary *)options
{
    UMMTP3Label *translatedLabel = [self localToRemoteLabel:label];
    ni = [self localToRemoteNetworkIndicator:ni];

    if(_overrideNetworkIndicator)
    {
        if(self.logLevel <= UMLOG_DEBUG)
        {
            [self.logFeed debugText:[NSString stringWithFormat:@"overrwriting-network-indicator: ni=%d->%d",ni,_overrideNetworkIndicator.intValue]];
        }
        ni = _overrideNetworkIndicator.intValue;
    }
    if(link == NULL)
    {
        link = [self getAnyLink];
    }
    if(link==NULL)
    {
        [self logMajorError:@"sendPdu: No link found in Linkset!"];
    }
    
    NSMutableData *pdu = [[NSMutableData alloc]init];
    uint8_t len;
    
    /* Q703 2.3.3 says
     In the case that the signalling information field of a message signal unit is spanning 62 octets or more, the length indicator is set to 63. */
    if(data.length >= 62)
    {
        len=63;
    }
    else
    {
        len = data.length;
    }
    
    switch(_variant)
    {
        case UMMTP3Variant_Japan:
            len = len | ((mp & 0x03) << 6);
            [pdu appendByte:len];
            [pdu appendByte:((ni & 0x3) << 6) | (si & 0xF)];
            break;
        
        case UMMTP3Variant_ANSI:
            [pdu appendByte:len];
            [pdu appendByte:((ni & 0x3) << 6) | (si & 0xF) | ((mp & 0x03) << 4)];
            break;

        default:
            [pdu appendByte:len];
            
            if(_nationalOptions & UMMTP3_NATIONAL_OPTION_MESSAGE_PRIORITY)
            {
                [pdu appendByte:((ni & 0x3) << 6) | (si & 0xF) | ((mp & 0x03) << 4)];
            }
            else
            {
                [pdu appendByte:((ni & 0x3) << 6) | (si & 0xF)];
            }
            break;
    }
    if(slc < 0)
    {
        [_slsLock lock];
        translatedLabel.sls = _last_sls;
        _last_sls = (_last_sls+1) % 16;
        [_slsLock unlock];
    }
    else
    {
        translatedLabel.sls = slc;
    }
    [translatedLabel appendToMutableData:pdu];
    if(heading >= 0)
    {
        uint8_t heading_byte = heading & 0xFF;
        [pdu appendByte:heading_byte];
    }
    if(data)
    {
        [pdu appendData:data];
    }
    [_speedometerTx increase];
    [_speedometerTxBytes increaseBy:(uint32_t)pdu.length];
    [link.m2pa dataFor:_mtp3 data:pdu ackRequest:ackRequest async:NO dpc:label.dpc.pc];
    [self updateTxStatisticSi:si headingCode:heading];
}

-(void)sendPdu:(NSData *)data
         label:(UMMTP3Label *)label
       heading:(int)heading
            ni:(int)ni
            mp:(int)mp
            si:(int)si
    ackRequest:(NSDictionary *)ackRequest
 correlationId:(uint32_t)correlation_id
       options:(NSDictionary *)options
{
    if(_overrideNetworkIndicator)
    {
        ni = _overrideNetworkIndicator.intValue;
    }

    NSMutableDictionary *options2=NULL;
    if((self.sendExtendedAttributes) && (options!=NULL))
    {
        options2 = [[NSMutableDictionary alloc]init];
        NSMutableDictionary *d = [[NSMutableDictionary alloc]init];
        if(options[@"mtp3-incoming-linkset"])
        {
            d[@"incoming-linkset"] = options[@"mtp3-incoming-linkset"];
        }
        if(options[@"mtp3-incoming-opc"])
        {
            d[@"incoming-opc"] = options[@"mtp3-incoming-opc"];
        }
        if(d.count > 0)
        {
            options2[@"info-string"] = [d jsonString];
        }
    }

    [self sendPdu:data
            label:label
          heading:heading
             link:NULL
              slc:-1
               ni:ni
               mp:mp
               si:si
       ackRequest:ackRequest
          options:options2];
}


#pragma mark -
#pragma mark Config stuff

- (NSDictionary *)config
{
    NSMutableDictionary *config = [[NSMutableDictionary alloc]init];
    NSArray *allkeys = [_linksBySlc allKeys];

    for(NSNumber *key in allkeys)
    {
        UMMTP3Link *link = _linksBySlc[key];
        config[[NSString stringWithFormat:@"attach-slc%d",link.slc]] = link.name;
    }
    config[@"dpc"] = [_adjacentPointCode stringValue];
    return config;
}

- (void)setDefaultValues
{
    _variant = UMMTP3Variant_Undefined;
    _overrideNetworkIndicator = NULL;
    _speed = 0; /* means unlimited */
}


- (void)setConfig:(NSDictionary *)cfg applicationContext:(id)appContext
{
    NSString *apcString = @"";
    NSString *opcString = NULL;
    _appdel = appContext;
    if(cfg[@"log-level"])
    {
        _logLevel = [cfg[@"log-level"] intValue];
    }
    if([cfg[@"disable-route-advertizement"] boolValue])
    {
        _dontAdvertizeRoutes = YES;
    }
   
    
    if(cfg[@"mtp3"])
    {
        NSString *mtp3_name = [cfg[@"mtp3"] stringValue];
        _mtp3 = [appContext getMTP3:mtp3_name];
        _prometheusMetrics.prometheus = _mtp3.prometheus;
    }

    if(cfg[@"apc"])
    {
        apcString  = [cfg[@"apc"] stringValue];
    }
    if(cfg[@"name"])
    {
        self.name =  [cfg[@"name"] stringValue];
    }
    if(cfg[@"speed"])
    {
        _speed =  [cfg[@"speed"] doubleValue];
    }

    if(cfg[@"opc"]) /* optional */
    {
        opcString = [cfg[@"opc"] stringValue];
    }


    if(cfg[@"tt-map-in"]) /* optional */
    {
        _ttmap_in_name = [cfg[@"tt-map-in"] stringValue];
        _ttmap_in = [appContext getTTMap:_ttmap_in_name];
    }
    if(cfg[@"tt-map-out"]) /* optional */
    {
        _ttmap_out_name = [cfg[@"tt-map-out"] stringValue];
        _ttmap_out = [appContext getTTMap:_ttmap_in_name];
    }
    if(cfg[@"pointcode-translation-table"]) /* optional */
    {
        _pointcodeTranslationTableNameBidi = [cfg[@"pointcode-translation-table"] stringValue];
    }
    if(cfg[@"pointcode-translation-table-in"]) /* optional */
    {
        _pointcodeTranslationTableNameIn = [cfg[@"pointcode-translation-table-in"] stringValue];
    }
    if(cfg[@"pointcode-translation-table-out"]) /* optional */
    {
        _pointcodeTranslationTableNameOut = [cfg[@"pointcode-translation-table-out"] stringValue];
    }

    _overrideNetworkIndicator = NULL;
    if (cfg[@"override-network-indicator"])
    {
        NSString *s = [cfg[@"override-network-indicator"] stringValue];
        if((  [s isEqualToStringCaseInsensitive:@"international"])
           || ([s isEqualToStringCaseInsensitive:@"int"])
           || ([s isEqualToStringCaseInsensitive:@"0"]))
        {
            _overrideNetworkIndicator = @(0);
        }
        else if(([s isEqualToStringCaseInsensitive:@"national"])
                || ([s isEqualToStringCaseInsensitive:@"nat"])
                || ([s isEqualToStringCaseInsensitive:@"2"]))
        {
            _overrideNetworkIndicator = @(2);
        }
        else if(([s isEqualToStringCaseInsensitive:@"spare"])
                || ([s isEqualToStringCaseInsensitive:@"international-spare"])
                || ([s isEqualToStringCaseInsensitive:@"int-spare"])
                || ([s isEqualToStringCaseInsensitive:@"1"]))
        {
            _overrideNetworkIndicator = @(1);
        }
        else if(([s isEqualToStringCaseInsensitive:@"reserved"])
                || ([s isEqualToStringCaseInsensitive:@"national-reserved"])
                || ([s isEqualToStringCaseInsensitive:@"nat-reserved"])
                || ([s isEqualToStringCaseInsensitive:@"3"]))
        {
            _overrideNetworkIndicator = @(3);
        }
        else
        {
            [self logMajorError:[NSString stringWithFormat:@"Unknown M3UA network-indicator '%@' defaulting to international",s]];
            _overrideNetworkIndicator = 0;
        }
    }

    if(cfg[@"mtp3"])
    {
        NSString *attachTo = [cfg[@"mtp3"] stringValue];
        _mtp3 = [appContext getMTP3:attachTo];
        if(_mtp3 == NULL)
        {
            NSString *s = [NSString stringWithFormat:@"Can not find mtp3 layer '%@' referred from mtp3 linkset '%@'",attachTo,_name];
            [self logMajorError:s];
            @throw([NSException exceptionWithName:[NSString stringWithFormat:@"CONFIG_ERROR FILE %s line:%ld",__FILE__,(long)__LINE__]
                                           reason:s
                                          userInfo:@{
                                                        @"sysmsg" : @"configuration error",
                                                        @"func": @(__func__),
                                                        @"line": @(__LINE__),
                                                        @"file": @(__FILE__),
                                                        @"obj":self
                                          }]);
        }
        else
        {
            [_mtp3 addLinkSet:self];
        }
    }

    _variant = _mtp3.variant;

    if (cfg[@"variant"])
    {
        NSString *s = [cfg[@"variant"] stringValue];
        if([s isEqualToStringCaseInsensitive:@"itu"])
        {
            _variant = UMMTP3Variant_ITU;
        }
        else if([s isEqualToStringCaseInsensitive:@"ansi"])
        {
            _variant = UMMTP3Variant_ANSI;
        }
        else if([s isEqualToStringCaseInsensitive:@"china"])
        {
            _variant = UMMTP3Variant_China;
        }
        else if([s isEqualToStringCaseInsensitive:@"japan"])
        {
            _variant = UMMTP3Variant_Japan;
        }
        else
        {
            [self logMajorError:[NSString stringWithFormat:@"Unknown M3UA variant '%@'",s]];
        }
    }

    if(_variant == UMMTP3Variant_Undefined)
    {
        @throw([NSException exceptionWithName:[NSString stringWithFormat:@"CONFIG_ERROR FILE %s line:%ld",__FILE__,(long)__LINE__]
                                       reason:@"Can not figure out mtp3 variant"
                                     userInfo:
                                        @{
                                            @"func": @(__func__),
                                            @"line": @(__LINE__),
                                            @"file": @(__FILE__),
                                     }]);
    }

    _adjacentPointCode = [[UMMTP3PointCode alloc]initWithString:apcString variant:_variant];
    if(opcString)
    {
        _localPointCode = [[UMMTP3PointCode alloc]initWithString:opcString variant:_variant];
    }
    else
    {
        _localPointCode = _mtp3.opc;
    }
    if (cfg[@"screening-mtp3-plugin-name"])
    {
        _mtp3_screeningPluginName = [cfg[@"screening-mtp3-plugin-name"] stringValue];
        _mtp3_screeningPlugin = NULL; /* forces reload of plugin if config change occurs */
    }
    if (cfg[@"screening-mtp3-plugin-config-file"])
    {
        _mtp3_screeningPluginConfigFileName = [cfg[@"screening-mtp3-plugin-config-file"] stringValue];
        _mtp3_screeningPlugin = NULL; /* forces reload of plugin if config change occurs */
    }
    if (cfg[@"screening-mtp3-plugin-trace-file"])
    {
        _mtp3_screeningPluginTraceFileName = [cfg[@"screening-mtp3-plugin-trace-file"] stringValue];
        _mtp3_screeningPlugin = NULL; /* forces reload of plugin if config change occurs */
    }
    if (cfg[@"screening-mtp3-plugin-trace-level"])
    {
        NSNumber *n = cfg[@"screening-mtp3-plugin-trace-level"];
        NSInteger i = n.integerValue;
        switch(i)
        {
            case 0:
                _mtp3ScreeningTraceLevel = UMMTP3ScreeningTraceLevel_none;
                break;
            case 1:
                _mtp3ScreeningTraceLevel = UMMTP3ScreeningTraceLevel_rejected_only;
                break;
            case 2:
                _mtp3ScreeningTraceLevel = UMMTP3ScreeningTraceLevel_everything;
                break;
            default:
                [self logMajorError:@"Invalid value for screening-mtp3-plugin-trace-level. Should be 0...2"];
        }
    }

    if (cfg[@"screening-sccp-plugin-name"])
    {
        _sccp_screeningPluginName = [cfg[@"screening-sccp-plugin-name"] stringValue];
        _sccp_screeningPlugin = NULL; /* forces reload of plugin if config change occurs */
    }
    if (cfg[@"screening-sccp-plugin-config-file"])
    {
        _sccp_screeningPluginConfigFileName = [cfg[@"screening-sccp-plugin-config-file"] stringValue];
        _sccp_screeningPlugin = NULL; /* forces reload of plugin if config change occurs */
    }
    if (cfg[@"screening-sccp-plugin-trace-file"])
    {
        _sccp_screeningPluginTraceFileName = [cfg[@"screening-sccp-plugin-trace-file"] stringValue];
        _sccp_screeningPlugin = NULL; /* forces reload of plugin if config change occurs */
    }

    if (cfg[@"screening-sccp-plugin-trace-level"])
    {
        NSNumber *n = cfg[@"screening-sccp-plugin-trace-level"];
        NSInteger i = n.integerValue;
        switch(i)
        {
            case 0:
                _mtp3ScreeningTraceLevel = UMMTP3ScreeningTraceLevel_none;
                break;
            case 1:
                _mtp3ScreeningTraceLevel = UMMTP3ScreeningTraceLevel_rejected_only;
                break;
            case 2:
                _mtp3ScreeningTraceLevel = UMMTP3ScreeningTraceLevel_everything;
                break;
            default:
                [self logMajorError:@"Invalid value for screening-sccp-plugin-trace-level. Should be 0...2"];
        }
    }

    if(cfg[@"routing-update-allow"])
    {
        id p = cfg[@"routing-update-allow"];
        if([p isKindOfClass:[NSString class]])
        {
            p = @[p];
        }
        if([p isKindOfClass:[NSArray class]])
        {
            NSArray *p1 = (NSArray *)p;
            for(NSString *pcstr in p1)
            {
                if([pcstr isEqual:@"*"])
                {
                    _permittedPointcodesInRoutingUpdatesAll = YES;
                }
                else
                {
                    UMMTP3PointCode *pc = [[UMMTP3PointCode alloc]initWithString:pcstr variant:_variant];
                    if(pc)
                    {
                        if(_permittedPointcodesInRoutingUpdates == NULL)
                        {
                            _permittedPointcodesInRoutingUpdates = @[pc];
                        }
                        else
                        {
                            _permittedPointcodesInRoutingUpdates = [_permittedPointcodesInRoutingUpdates arrayByAddingObject:pc];
                        }
                    }
                }
            }
        }
    }

    if(cfg[@"routing-update-deny"])
    {
        id p = cfg[@"routing-update-deny"];
        if([p isKindOfClass:[NSString class]])
        {
            p = @[p];
        }
        if([p isKindOfClass:[NSArray class]])
        {
            NSArray *p1 = (NSArray *)p;
            for(NSString *pcstr in p1)
            {
                if([pcstr isEqual:@"*"])
                {
                    _deniedPointcodesInRoutingUpdatesAll = YES;
                }
                else
                {
                    UMMTP3PointCode *pc = [[UMMTP3PointCode alloc]initWithString:pcstr variant:_variant];
                    if(pc)
                    {
                        if(_deniedPointcodesInRoutingUpdates == NULL)
                        {
                            _deniedPointcodesInRoutingUpdates = @[pc];
                        }
                        else
                        {
                            _deniedPointcodesInRoutingUpdates =  [_deniedPointcodesInRoutingUpdates arrayByAddingObject:pc];
                        }
                    }
                }
            }
        }
    }
    
    id a = cfg[@"routing-advertisement-allow"];
    if([a isKindOfClass:[NSString class]])
    {
        a = @[a];
    }
    if([a isKindOfClass:[NSArray class]])
    {
        for(NSString *pcstr in a)
        {
            if([pcstr isEqual:@"*"])
            {
                _dontAdvertizeRoutes = NO;
            }
            else
            {
                UMMTP3PointCode *pc = [[UMMTP3PointCode alloc]initWithString:pcstr variant:_variant];
                if(_allowedAdvertizedPointcodes == NULL)
                {
                    _allowedAdvertizedPointcodes = @[pc];
                }
                else
                {
                    _allowedAdvertizedPointcodes = [_allowedAdvertizedPointcodes  arrayByAddingObject:pc];
                }
            }
        }
    }

    a = cfg[@"routing-advertisement-deny"];
    if([a isKindOfClass:[NSString class]])
    {
        a = @[a];
    }
    if([a isKindOfClass:[NSArray class]])
    {
        for(NSString *pcstr in a)
        {
            if([pcstr isEqual:@"*"])
            {
                _dontAdvertizeRoutes = YES;
            }
            else
            {
                UMMTP3PointCode *pc = [[UMMTP3PointCode alloc]initWithString:pcstr variant:_variant];
                if(_deniedAdvertizedPointcodes == NULL)
                {
                    _deniedAdvertizedPointcodes = @[pc];
                }
                else
                {
                    _deniedAdvertizedPointcodes = [_deniedAdvertizedPointcodes arrayByAddingObject:pc];
                }
            }
        }
    }
    [self removeAllLinks];
    _prometheusMetrics = [[UMMTP3LinkSetPrometheusData alloc]initWithPrometheus:_mtp3.prometheus
                                                                    linksetName:_name
                                                                         isM3UA:NO];
    [_prometheusMetrics setSubname1:@"linkset" value:_name];
    [_prometheusMetrics registerMetrics];
}

#pragma mark -
#pragma mark MTP3 Send Management Messages
/* Group CHM */
- (void)sendCOO:(UMMTP3Label *)label lastFSN:(int)fsn ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"sendCOO (Changeover-order signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" lastFSN: %d",fsn]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",_name]];
    }
    NSMutableData *pdu = [[NSMutableData alloc]init];
    
    if(_variant == UMMTP3Variant_ANSI)
    {
        unsigned char byte[2];
        byte[0] = (slc & 0x0f) | (fsn << 4);
        byte[1] = (fsn >> 4) & 0x07;
        [pdu appendBytes:byte length:2];
    }
    else
    {
        [pdu appendByte:(fsn & 0x7F)];
    }
    [self sendPdu:pdu
            label:label
          heading:MTP3_MGMT_COO
             link:link
              slc:slc
               ni:ni
               mp:mp
               si:MTP3_SERVICE_INDICATOR_MGMT
       ackRequest:NULL
          options:NULL];
}

- (void)sendCOA:(UMMTP3Label *)label lastFSN:(int)fsn ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"sendCOA (Changeover-acknowledgement signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" lastFSN: %d",fsn]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" mp: %d",mp]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",_name]];
    }
    NSMutableData *pdu = [[NSMutableData alloc]init];
    if(_variant == UMMTP3Variant_ANSI)
    {
        unsigned char byte[2];
        byte[0] = (slc & 0x0f) | (fsn << 4);
        byte[1] = (fsn >> 4) & 0x07;
        [pdu appendBytes:byte length:2];
    }
    else
    {
        [pdu appendByte:(fsn & 0x7F)];
    }
    [self sendPdu:pdu
            label:label
          heading:MTP3_MGMT_COA
             link:link
              slc:slc
               ni:ni
               mp:mp
               si:MTP3_SERVICE_INDICATOR_MGMT
       ackRequest:NULL
          options:NULL];

}

- (void)sendXCO:(UMMTP3Label *)label lastFSN:(int)fsn ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"sendXCO (Extended Change Over)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" lastFSN: %d",fsn]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" mp: %d",mp]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",_name]];
    }
    NSMutableData *pdu = [[NSMutableData alloc]init];
    int fsn1 = (fsn >> 16) & 0xFF;
    int fsn2 = (fsn >> 8) & 0xFF;
    int fsn3 = (fsn >> 0) & 0xFF;
    [pdu appendByte:fsn1];
    [pdu appendByte:fsn2];
    [pdu appendByte:fsn3];
    [self sendPdu:pdu
            label:label
          heading:MTP3_MGMT_XCO
             link:link
              slc:slc
               ni:ni
               mp:mp
               si:MTP3_SERVICE_INDICATOR_MGMT
       ackRequest:NULL
          options:NULL];
}

- (void)sendXCA:(UMMTP3Label *)label
        lastFSN:(int)fsn
             ni:(int)ni
             mp:(int)mp
            slc:(int)slc
           link:(UMMTP3Link *)link
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"sendXCO (Extended Change Over Acknowledgment)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" lastFSN: %d",fsn]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" mp: %d",mp]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",_name]];
    }
    NSMutableData *pdu = [[NSMutableData alloc]init];
    int fsn1 = (fsn >> 0) & 0xFF;
    int fsn2 = (fsn >> 8) & 0xFF;
    int fsn3 = (fsn >> 16) & 0xFF;
    [pdu appendByte:fsn1];
    [pdu appendByte:fsn2];
    [pdu appendByte:fsn3];
    [self sendPdu:pdu
            label:label
          heading:MTP3_MGMT_XCA
             link:link
              slc:slc
               ni:ni
               mp:mp
               si:MTP3_SERVICE_INDICATOR_MGMT
       ackRequest:NULL
          options:NULL];
}

- (void)sendCBD:(UMMTP3Label *)label changeBackCode:(int)cbc ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"sendCBD (Changeback-declaration signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" changeBackCode: %d",cbc]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" mp: %d",mp]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",_name]];
    }
    NSMutableData *pdu = [[NSMutableData alloc]init];
    if(_variant == UMMTP3Variant_ANSI)
    {
        unsigned char byte[2];
        byte[0] = (slc & 0x0f) | (cbc << 4);
        byte[1] = (cbc >> 4) & 0x0F;
        [pdu appendBytes:byte length:2];
    }
    else
    {
        [pdu appendByte:(cbc & 0x7F)];
    }
    [self sendPdu:pdu
            label:label
          heading:MTP3_MGMT_CBD
             link:link
              slc:slc
               ni:ni
               mp:mp
               si:MTP3_SERVICE_INDICATOR_MGMT
       ackRequest:NULL
          options:NULL];
}

- (void)sendCBA:(UMMTP3Label *)label changeBackCode:(int)cbc ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"sendCBA (Changeback-acknowledgement signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" changeBackCode: %d",cbc]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" mp: %d",mp]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",_name]];
    }
    NSMutableData *pdu = [[NSMutableData alloc]init];
    if(_variant == UMMTP3Variant_ANSI)
    {
        unsigned char byte[2];
        byte[0] = (slc & 0x0f) | (cbc << 4);
        byte[1] = (cbc >> 4) & 0x0F;
        [pdu appendBytes:byte length:2];
    }
    else
    {
        [pdu appendByte:(cbc & 0x7F)];
    }
    [self sendPdu:pdu
            label:label
          heading:MTP3_MGMT_CBA
             link:link
              slc:slc
               ni:ni
               mp:mp
               si:MTP3_SERVICE_INDICATOR_MGMT
       ackRequest:NULL
          options:NULL];
}

/* Group ECM */
- (void)sendECO:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"sendECO (Emergency-changeover-order signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" mp: %d",mp]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",_name]];
    }
    [self sendPdu:NULL
            label:label
          heading:MTP3_MGMT_ECO
             link:link
              slc:slc
               ni:ni
               mp:mp
               si:MTP3_SERVICE_INDICATOR_MGMT
       ackRequest:NULL
          options:NULL];
}

- (void)sendECA:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"sendECA (Emergency-changeover-acknowledgement signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" mp: %d",mp]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",_name]];
    }
    [self sendPdu:NULL
            label:label
          heading:MTP3_MGMT_ECA
             link:link
              slc:slc
               ni:ni
               mp:mp
               si:MTP3_SERVICE_INDICATOR_MGMT
       ackRequest:NULL
          options:NULL];
}

/* Group FCM */
- (void)sendRCT:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"sendRCT (Signalling-route-set-congestion-test signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" mp: %d",mp]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",_name]];
    }
    [self sendPdu:NULL
            label:label
          heading:MTP3_MGMT_RCT
             link:link
              slc:slc
               ni:ni
               mp:mp
               si:MTP3_SERVICE_INDICATOR_MGMT
       ackRequest:NULL
          options:NULL];
}

- (void)sendTFC:(UMMTP3Label *)label
    destination:(UMMTP3PointCode *)pc
         status:(int)status
             ni:(int)ni
             mp:(int)mp
            slc:(int)slc
           link:(UMMTP3Link *)link
{
    UMMTP3PointCode *translatedPointCode = [self localToRemotePointcode:pc];
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"sendTFC (Transfer-controlled signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" destination: %@",pc.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" mp: %d",mp]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",_name]];
    }
    
    [self sendPdu:[translatedPointCode asDataWithStatus:status]
            label:label
          heading:MTP3_MGMT_TFC
             link:link
              slc:slc
               ni:ni
               mp:mp
               si:MTP3_SERVICE_INDICATOR_MGMT
       ackRequest:NULL
          options:NULL];
}

/* Group TFM */
- (void)sendTFP:(UMMTP3Label *)label
    destination:(UMMTP3PointCode *)pc
             ni:(int)ni mp:(int)mp
            slc:(int)slc
           link:(UMMTP3Link *)link
{
    UMMTP3PointCode *translatedPointCode = [self localToRemotePointcode:pc];

    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"sendTFP (Transfer-prohibited signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" destination: %@",pc.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" mp: %d",mp]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",_name]];
    }
    if(pc==NULL)
    {
        [self logDebug:@"sendTFP: pointcode is null. ignoring"];
        return;
    }
    [self sendPdu:[translatedPointCode asData]
            label:label
          heading:MTP3_MGMT_TFP
             link:link
              slc:slc
               ni:ni
               mp:mp
               si:MTP3_SERVICE_INDICATOR_MGMT
       ackRequest:NULL
          options:NULL];
}

- (void)sendTFR:(UMMTP3Label *)label destination:(UMMTP3PointCode *)pc ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    UMMTP3PointCode *translatedPointCode = [self localToRemotePointcode:pc];

    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"sendTFR (Transfer-restricted signal (national option))"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" destination: %@",pc.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" mp: %d",mp]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",_name]];
    }
    [self sendPdu:[translatedPointCode asData]
            label:label
          heading:MTP3_MGMT_TFR
             link:link
              slc:slc
               ni:ni
               mp:mp
               si:MTP3_SERVICE_INDICATOR_MGMT
       ackRequest:NULL
          options:NULL];
}

- (void)sendTFA:(UMMTP3Label *)label
    destination:(UMMTP3PointCode *)pc
             ni:(int)ni mp:(int)mp
            slc:(int)slc
           link:(UMMTP3Link *)link
{
    UMMTP3PointCode *translatedPointCode = [self localToRemotePointcode:pc];

    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"sendTFA (Transfer-allowed signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" destination: %@",pc.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" mp: %d",mp]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",_name]];
    }
    [self sendPdu:[translatedPointCode asData]
            label:label
          heading:MTP3_MGMT_TFA
             link:link
              slc:slc
               ni:ni
               mp:mp
               si:MTP3_SERVICE_INDICATOR_MGMT
       ackRequest:NULL
          options:NULL];
}

/* Group RSM */
- (void)sendRST:(UMMTP3Label *)label destination:(UMMTP3PointCode *)pc ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    UMMTP3PointCode *translatedPointCode = [self localToRemotePointcode:pc];

    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"sendRST (Signalling-route-set-test signal for prohibited destination)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" destination: %@",pc.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" mp: %d",mp]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",_name]];
    }
    [self sendPdu:[translatedPointCode asData]
            label:label
          heading:MTP3_MGMT_RST
             link:link
              slc:slc
               ni:ni
               mp:mp
               si:MTP3_SERVICE_INDICATOR_MGMT
       ackRequest:NULL
          options:NULL];
}
- (void)sendRSR:(UMMTP3Label *)label destination:(UMMTP3PointCode *)pc ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    UMMTP3PointCode *translatedPointCode = [self localToRemotePointcode:pc];

    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"sendRSR (Signalling-route-set-test signal for restricted destination (national option))"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" destination: %@",pc.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" mp: %d",mp]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",_name]];
    }
    [self sendPdu:[translatedPointCode asData]
            label:label
          heading:MTP3_MGMT_RSR
             link:link
              slc:slc
               ni:ni
               mp:mp
               si:MTP3_SERVICE_INDICATOR_MGMT
       ackRequest:NULL
          options:NULL];
}

/* Group MIM */
- (void)sendLIN:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"sendLIN (Link inhibit signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" mp: %d",mp]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",_name]];
    }
    [self sendPdu:NULL
            label:label
          heading:MTP3_MGMT_LIN
             link:link
              slc:slc
               ni:ni
               mp:mp
               si:MTP3_SERVICE_INDICATOR_MGMT
       ackRequest:NULL
          options:NULL];
}

- (void)sendLUN:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"sendLUN (Link uninhibit signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" mp: %d",mp]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",_name]];
    }
    [self sendPdu:NULL
            label:label
          heading:MTP3_MGMT_LUN
             link:link
              slc:slc
               ni:ni
               mp:mp
               si:MTP3_SERVICE_INDICATOR_MGMT
       ackRequest:NULL
          options:NULL];
}

- (void)sendLIA:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"sendLIA (Link inhibit acknowledgement signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" mp: %d",mp]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",_name]];
    }
    [self sendPdu:NULL
            label:label
          heading:MTP3_MGMT_LIA
             link:link
              slc:slc
               ni:ni
               mp:mp
               si:MTP3_SERVICE_INDICATOR_MGMT
       ackRequest:NULL
          options:NULL];
}

- (void)sendLUA:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"sendLUA (Link uninhibit acknowledgement signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" mp: %d",mp]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",_name]];
    }
    [self sendPdu:NULL
            label:label
          heading:MTP3_MGMT_LUA
             link:link
              slc:slc
               ni:ni
               mp:mp
               si:MTP3_SERVICE_INDICATOR_MGMT
       ackRequest:NULL
          options:NULL];
}

- (void)sendLID:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"sendLID (Link inhibit denied signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" mp: %d",mp]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",_name]];
    }
    [self sendPdu:NULL
            label:label
          heading:MTP3_MGMT_LID
             link:link
              slc:slc
               ni:ni
               mp:mp
               si:MTP3_SERVICE_INDICATOR_MGMT
       ackRequest:NULL
          options:NULL];
}

- (void)sendLFU:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"sendLFU (Link forced uninhibit signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" mp: %d",mp]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",_name]];
    }
    [self sendPdu:NULL
            label:label
          heading:MTP3_MGMT_LFU
             link:link
              slc:slc
               ni:ni
               mp:mp
               si:MTP3_SERVICE_INDICATOR_MGMT
       ackRequest:NULL
          options:NULL];
}

- (void)sendLLT:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"sendLLT (Link local inhibit test signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" mp: %d",mp]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",_name]];
    }
    [self sendPdu:NULL
            label:label
          heading:MTP3_MGMT_LLT
             link:link
              slc:slc
               ni:ni
               mp:mp
               si:MTP3_SERVICE_INDICATOR_MGMT
       ackRequest:NULL
          options:NULL];
}

- (void)sendLRT:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"sendLRT (Link remote inhibit test signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" mp: %d",mp]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",_name]];
    }
    [self sendPdu:NULL
            label:label
          heading:MTP3_MGMT_LRT
             link:link
              slc:slc
               ni:ni
               mp:mp
               si:MTP3_SERVICE_INDICATOR_MGMT
       ackRequest:NULL
          options:NULL];
}

- (void)sendTRA:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    _tra_sent++;
    link.awaitFirstSLTA = NO;
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"sendTRA (Traffic-restart-allowed signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" mp: %d",mp]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",_name]];
    }
    [self sendPdu:NULL
            label:label
          heading:MTP3_MGMT_TRA
             link:link
              slc:slc
               ni:ni
               mp:mp
               si:MTP3_SERVICE_INDICATOR_MGMT
       ackRequest:NULL
          options:NULL];

}

/* group DLM */
- (void)sendDLC:(UMMTP3Label *)label cic:(int)cic ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"sendDLC (Signalling-data-link-connection-order signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" cic: %d",cic]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" mp: %d",mp]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",_name]];
    }
    

    NSData *data;
   if(_variant==UMMTP3Variant_ANSI)
   {
       uint8_t buf[2];
       buf[0] = cic & 0xFF;
       buf[1] = (cic >> 8) & 0x0F;
       data = [NSData dataWithBytes:buf length:2];

   }
   else
   {
       uint8_t buf[3];
       buf[0] = (slc & 0x0f) | (cic << 4);
       buf[1] = cic >> 4;
       buf[2] = (cic >> 12) & 0x03;
       data = [NSData dataWithBytes:buf length:3];
    }
    
    [self sendPdu:data
            label:label
          heading:MTP3_MGMT_DLC
             link:link
              slc:slc
               ni:ni
               mp:mp
               si:MTP3_SERVICE_INDICATOR_MGMT
       ackRequest:NULL
          options:NULL];
}

- (void)sendCSS:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"sendCSS (Connection-successful signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" mp: %d",mp]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",_name]];
    }
    [self sendPdu:NULL
            label:label
          heading:MTP3_MGMT_CSS
             link:link
              slc:slc
               ni:ni
               mp:mp
               si:MTP3_SERVICE_INDICATOR_MGMT
       ackRequest:NULL
          options:NULL];
}

- (void)sendCNS:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"sendCNS (Connection-not-successful signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" mp: %d",mp]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",_name]];
    }
    [self sendPdu:NULL
            label:label
          heading:MTP3_MGMT_CNS
             link:link
              slc:slc
               ni:ni
               mp:mp
               si:MTP3_SERVICE_INDICATOR_MGMT
       ackRequest:NULL
          options:NULL];
}

- (void)sendCNP:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"sendCNP (Connection-not-possible signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" mp: %d",mp]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",_name]];
    }
    [self sendPdu:NULL
            label:label
          heading:MTP3_MGMT_CNP
             link:link
              slc:slc
               ni:ni
               mp:mp
               si:MTP3_SERVICE_INDICATOR_MGMT
       ackRequest:NULL
          options:NULL];
}
/* group UFC */
- (void)sendUPU:(UMMTP3Label *)label destination:(UMMTP3PointCode *)pc userpartId:(int)upid cause:(int)cause ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    UMMTP3PointCode *translatedPointCode = [self localToRemotePointcode:pc];

    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"sendUPU (User part unavailable signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" destination: %@",pc.description]];
        [self logDebug:[NSString stringWithFormat:@" userpartId: %d",upid]];
        [self logDebug:[NSString stringWithFormat:@" cause: %d",cause]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" mp: %d",mp]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",_name]];
    }
    NSMutableData *pdu = [[NSMutableData alloc]initWithData:[translatedPointCode asData]];
    [pdu appendByte: ((upid & 0x0F) | (cause & 0x0F << 8))];
    [self sendPdu:pdu
            label:label
          heading:MTP3_MGMT_UPU
             link:link
              slc:slc
               ni:ni
               mp:mp
               si:MTP3_SERVICE_INDICATOR_MGMT
       ackRequest:NULL
          options:NULL];
}

- (void)sendUPA:(UMMTP3Label *)label
    destination:(UMMTP3PointCode *)pc
     userpartId:(int)upid
          cause:(int)cause
             ni:(int)ni
             mp:(int)mp
            slc:(int)slc
           link:(UMMTP3Link *)link
{
    UMMTP3PointCode *translatedPointCode = [self localToRemotePointcode:pc];

    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"sendUPA"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" destination: %@",pc.description]];
        [self logDebug:[NSString stringWithFormat:@" userpartId: %d",upid]];
        [self logDebug:[NSString stringWithFormat:@" cause: %d",cause]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" mp: %d",mp]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",_name]];
    }
    NSMutableData *pdu = [[NSMutableData alloc]initWithData:[translatedPointCode asData]];
    [pdu appendByte: ((upid & 0x0F) | (cause & 0x0F << 8))];
    [self sendPdu:pdu
            label:label
          heading:MTP3_MGMT_UPA
             link:link
              slc:slc
               ni:ni
               mp:mp
               si:MTP3_SERVICE_INDICATOR_MGMT
       ackRequest:NULL
          options:NULL];
}

- (void)sendUPT:(UMMTP3Label *)label
    destination:(UMMTP3PointCode *)pc
     userpartId:(int)upid
          cause:(int)cause
             ni:(int)ni
             mp:(int)mp
            slc:(int)slc
           link:(UMMTP3Link *)link
{
    UMMTP3PointCode *translatedPointCode = [self localToRemotePointcode:pc];

    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"sendUPT"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" destination: %@",pc.description]];
        [self logDebug:[NSString stringWithFormat:@" userpartId: %d",upid]];
        [self logDebug:[NSString stringWithFormat:@" cause: %d",cause]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" mp: %d",mp]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",_name]];
    }
    NSMutableData *pdu = [[NSMutableData alloc]initWithData:[translatedPointCode asData]];
    [pdu appendByte: ((upid & 0x0F) | (cause & 0x0F << 8))];
    [self sendPdu:pdu
            label:label
          heading:MTP3_MGMT_UPT
             link:link
              slc:slc
               ni:ni
               mp:mp
               si:MTP3_SERVICE_INDICATOR_MGMT
       ackRequest:NULL
          options:NULL];
}

- (void)powerOn
{
    [self powerOn:NULL];
}

- (void)powerOn:(NSString *)reason
{
    NSArray *linkKeys = [_linksBySlc allKeys];
    for(NSNumber *key in linkKeys)
    {
        UMMTP3Link *link = _linksBySlc[key];
        [link powerOn];
    }
}

- (void)powerOff
{
    [self powerOff:NULL];
}

- (void)powerOff:(NSString *)reason
{
    NSArray *linkKeys = [_linksBySlc allKeys];
    for(NSNumber *key in linkKeys)
    {
        UMMTP3Link *link = _linksBySlc[key];
        [link.m2pa.stateMachineLogFeed debugText:@"PowerOff requested from linkset PowerOff"];
        [link powerOff];
    }
}

- (void)forcedPowerOff
{
    NSArray *linkKeys = [_linksBySlc allKeys];
    for(NSNumber *key in linkKeys)
    {
        UMMTP3Link *link = _linksBySlc[key];
        [link forcedPowerOff];
    }
}

- (void)forcedPowerOn
{
    NSArray *linkKeys = [_linksBySlc allKeys];
    for(NSNumber *key in linkKeys)
    {
        UMMTP3Link *link = _linksBySlc[key];
        [link forcedPowerOn];
    }
}


- (void)attachmentConfirmed:(int)slc
{
    UMMTP3Link *link = [self getLinkBySlc:slc];
    [link attachmentConfirmed];
}

- (void)attachmentFailed:(int)slc reason:(NSString *)r
{
    UMMTP3Link *link = [self getLinkBySlc:slc];
    [link attachmentFailed:r];
}

- (void)sctpStatusUpdate:(UMSocketStatus)status slc:(int)slc
{
    UMMTP3Link *link = [self getLinkBySlc:slc];
    [link sctpStatusUpdate:status];
    [self updateLinkSetStatus];
}


- (void)m2paStatusUpdate:(M2PA_Status)status slc:(int)slc
{
    UMMTP3Link *link = [self getLinkBySlc:slc];
    if(link==NULL)
    {
        return;
    }
    M2PA_Status old_status = link.current_m2pa_status;
    if(old_status == status)
    {
        return;
    }

    link.current_m2pa_status = status;
    link.last_m2pa_status = old_status;
    BOOL newUp = NO;
    BOOL newDown = NO;

    [self updateLinkSetStatus];
    
    if((status == M2PA_STATUS_IS) && (old_status != M2PA_STATUS_IS))
    {
        _activeLinks++;
        newUp = YES;
    }
    else if((status != M2PA_STATUS_IS) && (old_status == M2PA_STATUS_IS))
    {
        _activeLinks--;
        newDown = YES;
    }

    if(_activeLinks==0)
    {
        link.emergency = YES;
    }
    else
    {
        link.emergency = NO;
    }

    if(old_status != status)
    {
        switch(status)
        {
            case M2PA_STATUS_FOOS:
                [link stopLinkTestTimer];
                [link stopReopenTimer1];
                [link stopReopenTimer2];
                [link.m2pa.stateMachineLogFeed debugText:@"PowerOff requested due to status M2PA_STATUS_FOOS"];
                [link powerOff];
                break;
            case M2PA_STATUS_DISCONNECTED:
                [link stopLinkTestTimer];
                [link stopReopenTimer1];
                [link stopReopenTimer2];
                [link.m2pa.stateMachineLogFeed debugText:@"PowerOff requested due to status M2PA_STATUS_DISCONNECTED"];
                [link powerOff];
                [link startReopenTimer1]; /* this will power on in few sec */
                break;
            case M2PA_STATUS_OFF: /* connection requested but SCTP is not yet up */
                [link stopLinkTestTimer];
                [link stopReopenTimer1];
                [link.m2pa.stateMachineLogFeed debugText:@"PowerOff NOT requested due to status M2PA_STATUS_OFF"];
                //[link powerOff];
                break;
            case M2PA_STATUS_OOS:
                [link stopLinkTestTimer];
                [link stopReopenTimer1];
                [link start];
                break;
            case M2PA_STATUS_INITIAL_ALIGNMENT:
                break;
            case M2PA_STATUS_ALIGNED_NOT_READY:
                break;
            case M2PA_STATUS_ALIGNED_READY:
                break;
            case M2PA_STATUS_PROCESSOR_OUTAGE:
                break;
            case M2PA_STATUS_IS:
                [link stopReopenTimer1];
                if(newUp)
                {
                    link.awaitFirstSLTA = YES;
                    link.firstSLTMSent = NO;
                    [link stopLinkTestTimer];
                    if(link.firstSLTMSent == NO)
                    [self linktestTimeEventForLink:link];
                    link.firstSLTMSent = YES;
                    [link startLinkTestTimer];
                    [link stopReopenTimer2];
                }
                break;
        }
        if(newUp)
        {
            link.lastLinkUp = [NSDate date];
        }
        if(newDown)
        {
            link.lastLinkDown = [NSDate date];
        }
    }
}

/* reopen Timer Event 1 happens when a link got closed.
   We wait a small amount of time and restart the link */
- (void)reopenTimer1EventFor:(UMMTP3Link *)link
{
    [link.m2pa.state logStatemachineEventString:@"reopenTimer1Event"];

    switch(link.current_m2pa_status)
    {
        case M2PA_STATUS_FOOS:
            /* human told us not to start. So we do nothing */
            [link stopLinkTestTimer];
            [link stopReopenTimer1];
            [link stopReopenTimer2];
            [link powerOff];
            break;
        case M2PA_STATUS_OFF:
            /* link stayed off. so lets kick it and restart it */
            [link stopLinkTestTimer];
            [link stopReopenTimer1];
            [link startReopenTimer2];
            [link powerOn];
            break;
        case M2PA_STATUS_DISCONNECTED:
            /* link is establishing already (from other side for example). lets not mess with it but check again in 6 seconds again.*/
            [link stopReopenTimer1];
            [link startReopenTimer1];
            [link stopReopenTimer2];
            break;
        case M2PA_STATUS_OOS:
        case M2PA_STATUS_INITIAL_ALIGNMENT:
        case M2PA_STATUS_ALIGNED_NOT_READY:
        case M2PA_STATUS_ALIGNED_READY:
        case M2PA_STATUS_IS:
        case M2PA_STATUS_PROCESSOR_OUTAGE:
            /* link is already coming up. so all is fine */
            [link stopReopenTimer1];
            break;
    }
}

/* reopen Timer Event 2 happens when a link got started but doesnt come up after a while.
 we tear everythign down after reopen timer 2 and restart the link */
- (void)reopenTimer2EventFor:(UMMTP3Link *)link
{
    if(link.last_m2pa_status != M2PA_STATUS_IS)
    {
        [link stopLinkTestTimer];
        [link stopReopenTimer1];
        [link stopReopenTimer2];
        [link.m2pa.stateMachineLogFeed debugText:@"reopenTimer2Event: not in service after reopen timer 2 expired. "];
        [link powerOff];
        [link startReopenTimer1];
    }
}

- (void)start:(int)slc
{
    UMMTP3Link *link = [self getLinkBySlc:slc];
    [link start];
}
- (void)stop:(int)slc
{
    UMMTP3Link *link = [self getLinkBySlc:slc];
    [link stop];
}


- (void)updateLinkSetStatus
{
    UMMUTEX_LOCK(_currentLinksMutex);
    NSMutableArray *inactiveLinks = [[NSMutableArray alloc]init];
    NSMutableArray *activeLinks = [[NSMutableArray alloc]init];
    NSMutableArray *readyLinks  = [[NSMutableArray alloc]init];
    NSMutableArray *processorOutageLinks  = [[NSMutableArray alloc]init];
    NSArray *keys = [_linksBySlc allKeys];
    for (NSNumber *key in keys)
    {
        UMMTP3Link *link = _linksBySlc[key];
        switch(link.current_m2pa_status)
        {
            default:
            case M2PA_STATUS_OFF:
                if([_currentActiveLinks indexOfObject:link] != NSNotFound)
                {
                    [_prometheusMetrics.linkDownCount increaseBy:1];
                }
                [inactiveLinks addObject:link];
                break;
            case M2PA_STATUS_OOS:
                if([_currentActiveLinks indexOfObject:link] != NSNotFound)
                {
                    [_prometheusMetrics.linkDownCount increaseBy:1];
                }
                [inactiveLinks addObject:link];
                break;
            case M2PA_STATUS_INITIAL_ALIGNMENT:
                if([_currentActiveLinks indexOfObject:link] != NSNotFound)
                {
                    [_prometheusMetrics.linkDownCount increaseBy:1];
                }
                [inactiveLinks addObject:link];
                break;
            case M2PA_STATUS_ALIGNED_NOT_READY:
                if([_currentActiveLinks indexOfObject:link] != NSNotFound)
                {
                    [_prometheusMetrics.linkDownCount increaseBy:1];
                }
                [inactiveLinks addObject:link];
                break;
            case M2PA_STATUS_ALIGNED_READY:
                [readyLinks addObject:link];
                break;
            case M2PA_STATUS_IS:
                if([_currentActiveLinks indexOfObject:link] == NSNotFound)
                {
                    [_prometheusMetrics.linkUpCount increaseBy:1];
                }
                if(link.m2pa.remote_processor_outage)
                {
                    [processorOutageLinks addObject:link];
                }
                else
                {
                    [activeLinks addObject:link];
                }
                break;
        }
    }
    /* if we now have our first active link, we should send a first SLTM before sending TRA */
    /* we do this */

    _prometheusMetrics.linksAvailableGauge.value = @(_activeLinks);
    _activeLinksCount = activeLinks.count;
    _inactiveLinksCount = inactiveLinks.count;
    _readyLinksCount = readyLinks.count;
    _processorOutageLinksCount = processorOutageLinks.count;

    BOOL nowAvailable=NO;
    BOOL nowUnavailable=NO;
    if((_currentActiveLinks.count == 0) && (_activeLinksCount > 0))
    {
        /* the linkset now has active links */
        _mtp3.ready = YES;
        nowAvailable = YES;
    }
    else if((_activeLinksCount == 0) && (_currentActiveLinks.count > 0))
    {
        /* the linkset has no active links anymore */
        nowUnavailable = YES;
    }
    _currentInactiveLinks = inactiveLinks;
    _currentActiveLinks = activeLinks;
    _currentReadyLinks  = readyLinks;
    _currentProcessorOutageLinks  = processorOutageLinks;
    UMMUTEX_UNLOCK(_currentLinksMutex);
    
    if(nowAvailable)
    {
        [_mtp3 updateRoutingTableLinksetAvailabe:_name];
        [self updateRouteAvailable:_adjacentPointCode
                              mask:_adjacentPointCode.maxmask
                          priority:UMMTP3RoutePriority_1
                            reason:@"updateLinksetStatus activeLinks > 0"];
        _lastLinksetUp = [NSDate date];
    }
    if(nowUnavailable)
    {
        [self forgetAdvertizedPointcodes];
        [_mtp3 updateRoutingTableLinksetUnavailabe:_name];
        [self updateRouteUnavailable:_adjacentPointCode
                                mask:_adjacentPointCode.maxmask
                            priority:UMMTP3RoutePriority_1
                              reason:@"updateLinksetStatus activeLinks < 1"];
        _lastLinksetDown = [NSDate date];
    }
}

- (void)linktestTimeEventForLink:(UMMTP3Link *)link
{
    const char *patternBytes = "I need coffee!";
    unsigned long patternLength = strlen(patternBytes);
    NSData *pattern = [NSData dataWithBytes:patternBytes length:patternLength];

    UMMTP3Label *label = [[UMMTP3Label alloc]init];
    label.opc = self.localPointCode;
    label.dpc = self.adjacentPointCode;
    label.sls = link.slc;

    if(_logLevel <=UMLOG_DEBUG)
    {
        NSString *s = [NSString stringWithFormat:@"LinktestTimerEvent (%d/%d)",_variant,_mtp3.variant];
        [self logDebug:s];
    }
    if(_variant == UMMTP3Variant_ANSI)
    {
        [self sendSSLTM:label
               pattern:pattern
                    ni:_mtp3.networkIndicator
                    mp:0
                   slc:link.slc
                  link:link];
    }
    else
    {
		[self sendSLTM:label
			   pattern:pattern
                    ni:_mtp3.networkIndicator
                    mp:0
                   slc:link.slc
                  link:link];
	}
}

- (void)updateRouteAvailable:(UMMTP3PointCode *)pc
                        mask:(int)mask
                    priority:(UMMTP3RoutePriority)prio
                      reason:(NSString *)reason
{
    if([self allowRoutingUpdateForPointcode:pc mask:mask] == NO)
    {
        return;
    }
    

    if(_logLevel <=UMLOG_DEBUG)
    {
        NSString *s = [NSString stringWithFormat:@"updateRouteAvailable:%@/%d",pc.stringValue,mask];
        [self logDebug:s];
    }
    [_mtp3 updateRouteAvailable:pc
                           mask:mask
                    linksetName:_name
                       priority:prio
                         reason:reason];
}

- (void)updateRouteRestricted:(UMMTP3PointCode *)pc
                         mask:(int)mask
                     priority:(UMMTP3RoutePriority)prio
                       reason:(NSString *)reason
{
    if([self allowRoutingUpdateForPointcode:pc mask:mask] == NO)
    {
        return;
    }

    if(_logLevel <=UMLOG_DEBUG)
    {
        NSString *s = [NSString stringWithFormat:@"updateRouteRestricted:%@/%d",pc.stringValue,mask];
        [self logDebug:s];
    }

    [_mtp3 updateRouteRestricted:pc
                            mask:mask
                     linksetName:_name
                        priority:prio
                          reason:reason];
}


- (void)updateRouteUnavailable:(UMMTP3PointCode *)pc
                          mask:(int)mask
                      priority:(UMMTP3RoutePriority)prio
                        reason:(NSString *)reason
{
    if([self allowRoutingUpdateForPointcode:pc mask:mask] == NO)
    {
        return;
    }
    if(_logLevel <=UMLOG_DEBUG)
    {
        NSString *s = [NSString stringWithFormat:@"updateRouteUnavailable:%@/%d",pc.stringValue,mask];
        [self logDebug:s];
    }
    [_mtp3 updateRouteUnavailable:pc
                             mask:mask
                      linksetName:_name
                         priority:prio
                           reason:reason];
}

- (void)forgetAdvertizedPointcodes
{
    self.advertizedPointcodes = [[UMSynchronizedSortedDictionary alloc]init];
}

- (void)advertizePointcodeAvailable:(UMMTP3PointCode *)pc
                               mask:(int)mask
{
    if(mask == -1)
    {
        mask = pc.maxmask;
    }
    if((_dontAdvertizeRoutes) && (pc.pc != _mtp3.opc.pc))
    {
        return;
    }
    if([self allowRoutingUpdateForPointcode:pc mask:mask]==NO)
    {
        return;
    }

    if(mask != pc.maxmask)
    {
        [self logWarning:@"We dont support advertizements with mask other than maxmask"];
    }
    if(pc.pc == _adjacentPointCode.pc)
    {
        /* dont advertize pointcode unavailable to the very same pointcode.*/
        [self logWarning:[NSString stringWithFormat:@"not advertizing pointcode available %d to APC %d",pc.pc, _adjacentPointCode.pc]];
        return;
    }
    NSNumber *n = _advertizedPointcodes[@(pc.pc)];
    if((n==NULL) || ( n.integerValue != UMMTP3_ROUTE_ALLOWED))
    {
        _advertizedPointcodes[@(pc.pc)] = @(UMMTP3_ROUTE_ALLOWED);
        UMMTP3Label *label = [[UMMTP3Label alloc]init];
        label.opc = self.localPointCode;
        label.dpc = self.adjacentPointCode;
        [self sendTFA:label destination:pc ni:self.networkIndicator mp:0 slc:0 link:NULL];
    }
}

- (void)advertizePointcodeRestricted:(UMMTP3PointCode *)pc
                                mask:(int)mask
{
    if(mask == -1)
    {
        mask = pc.maxmask;
    }

    if((_dontAdvertizeRoutes) && (pc.pc != _mtp3.opc.pc))
    {
        return;
    }
    if([self allowRoutingUpdateForPointcode:pc mask:mask]==NO)
    {
        return;
    }

    if(mask != pc.maxmask)
    {
        NSLog(@"We dont support advertizements with mask other than maxmask");
    }
    if(pc.pc == _adjacentPointCode.pc)
    {
        /* dont advertize pointcode unavailable to the very same pointcode.*/
        NSLog(@"not advertizing pointcode restricted %d to APC %d",pc.pc, _adjacentPointCode.pc);
        return;
    }
    NSNumber *n = _advertizedPointcodes[@(pc.pc)];
    if((n==NULL) || ( n.integerValue != UMMTP3_ROUTE_RESTRICTED))
    {
        _advertizedPointcodes[@(pc.pc)] = @(UMMTP3_ROUTE_RESTRICTED);
        UMMTP3Label *label = [[UMMTP3Label alloc]init];
        label.opc = self.localPointCode;
        label.dpc = self.adjacentPointCode;
        [self sendTFR:label destination:pc ni:self.networkIndicator mp:0 slc:0 link:NULL];
    }
}

- (void)advertizePointcodeUnavailable:(UMMTP3PointCode *)pc
                                 mask:(int)mask
{
    if(mask == -1)
    {
        mask = pc.maxmask;
    }

    if((_dontAdvertizeRoutes) && (pc.pc != _mtp3.opc.pc))
    {
        return;
    }
    if([self allowRoutingUpdateForPointcode:pc mask:mask]==NO)
    {
        return;
    }

    if(mask != pc.maxmask)
    {
        NSLog(@"We dont support advertizements with mask other than maxmask");
        return;
    }
    if(pc==NULL)
    {
        NSLog(@"advertizePointcodeUnavailable: pointcode==NULL");
        return;
    }
    if(pc.pc == _adjacentPointCode.pc)
    {
        /* dont advertize pointcode unavailable to the very same pointcode.*/
        NSLog(@"not advertizing pointcode unavailable %d to APC %d",pc.pc, _adjacentPointCode.pc);
        return;
    }
    NSNumber *n = _advertizedPointcodes[@(pc.pc)];
    if((n==NULL) || ( n.integerValue != UMMTP3_ROUTE_PROHIBITED))
    {
        _advertizedPointcodes[@(pc.pc)] = @(UMMTP3_ROUTE_PROHIBITED);
        UMMTP3Label *label = [[UMMTP3Label alloc]init];
        label.opc = self.localPointCode;
        label.dpc = self.adjacentPointCode;
        [self sendTFP:label destination:pc ni:self.networkIndicator mp:0 slc:0 link:NULL];
    }
}

- (void)stopDetachAndDestroy
{
    /* FIXME: do something here */
}

- (NSString *)webStatus
{
    NSMutableString *s = [[NSMutableString alloc]init];

    NSArray *linkKeys = [_linksBySlc allKeys];
    for(NSNumber *key in linkKeys)
    {
        UMMTP3Link *link = _linksBySlc[key];
        if(link)
        {
            [s appendFormat:@"    %@",link.name];
            [s appendFormat:@" SLC %d",link.slc];
            [s appendFormat:@" M2PA-Status: %@",[UMLayerM2PA m2paStatusString:link.current_m2pa_status]];
            [s appendString:@"\n"];
        }
    }
    return s;
}

#pragma mark -
#pragma mark pointcode translation helper functions

- (void)loadTranslationTables
{
    if((_pointcodeTranslationTableNameBidi.length > 0) && (_pointcodeTranslationTableBidi == NULL))
    {
        _pointcodeTranslationTableBidi = [_appdel getMTP3PointCodeTranslationTable:_pointcodeTranslationTableNameBidi];
        if(_pointcodeTranslationTableBidi==NULL)
        {
            [self.logFeed debugText:[NSString stringWithFormat:@"Failed to load pointcode translation table '%@'",_pointcodeTranslationTableNameBidi]];
        }
    }

    if((_pointcodeTranslationTableNameIn.length > 0) && (_pointcodeTranslationTableIn== NULL))
    {
        _pointcodeTranslationTableIn = [_appdel getMTP3PointCodeTranslationTable:_pointcodeTranslationTableNameIn];
        if(_pointcodeTranslationTableIn==NULL)
        {
            [self.logFeed debugText:[NSString stringWithFormat:@"Failed to load pointcode translation table '%@'",_pointcodeTranslationTableNameIn]];
        }
    }

    if((_pointcodeTranslationTableNameOut.length > 0) && (_pointcodeTranslationTableOut== NULL))
    {
        _pointcodeTranslationTableOut = [_appdel getMTP3PointCodeTranslationTable:_pointcodeTranslationTableNameOut];
        if(_pointcodeTranslationTableOut==NULL)
        {
            [self.logFeed debugText:[NSString stringWithFormat:@"Failed to load pointcode translation table '%@'",_pointcodeTranslationTableNameOut]];
        }
    }
}


- (UMMTP3PointCode *)remoteToLocalPointcode:(UMMTP3PointCode *)pc
{
    [self loadTranslationTables];
    if((_pointcodeTranslationTableIn==NULL) && (_pointcodeTranslationTableNameBidi==NULL))
    {
        return pc;
    }
    if(_pointcodeTranslationTableIn)
    {
        return [_pointcodeTranslationTableIn translateRemoteToLocal:pc];
    }
    if(_pointcodeTranslationTableNameBidi)
    {
        return [_pointcodeTranslationTableBidi translateRemoteToLocal:pc];
    }
    return pc;
}

- (UMMTP3PointCode *)localToRemotePointcode:(UMMTP3PointCode *)pc
{
    [self loadTranslationTables];
    if((_pointcodeTranslationTableOut==NULL) && (_pointcodeTranslationTableNameBidi==NULL))
    {
        return pc;
    }
    if(_pointcodeTranslationTableOut)
    {
        return [_pointcodeTranslationTableOut translateLocalToRemote:pc];
    }
    if(_pointcodeTranslationTableNameBidi)
    {
        return [_pointcodeTranslationTableBidi translateLocalToRemote:pc];
    }
    return pc;
}


-(UMMTP3Label *)remoteToLocalLabel:(UMMTP3Label *)label
{
    UMMTP3Label *nlabel = [label copy];
    nlabel.opc = [self remoteToLocalPointcode:label.opc];
    nlabel.dpc = [self remoteToLocalPointcode:label.dpc];
    if(self.logLevel <= UMLOG_DEBUG)
    {
        if((nlabel.opc.pc != label.opc.pc) || (nlabel.dpc.pc != label.dpc.pc))
        {
            [self.logFeed debugText:[NSString stringWithFormat:@"pointcode-translation(remote->local): opc=%@/dpc=%@ to opc=%@/dpc=%@",label.opc,label.dpc,nlabel.opc,nlabel.dpc]];
        }
    }
    return nlabel;
}

-(UMMTP3Label *)localToRemoteLabel:(UMMTP3Label *)label
{
    UMMTP3Label *nlabel = [label copy];
    nlabel.opc = [self localToRemotePointcode:label.opc];
    nlabel.dpc = [self localToRemotePointcode:label.dpc];
    if(self.logLevel <= UMLOG_DEBUG)
    {
        if((nlabel.opc.pc != label.opc.pc) || (nlabel.dpc.pc != label.dpc.pc))
        {
            [self.logFeed debugText:[NSString stringWithFormat:@"pointcode-translation(local->remote): opc=%@/dpc=%@ to opc=%@/dpc=%@",label.opc,label.dpc,nlabel.opc,nlabel.dpc]];
        }
    }
    return nlabel;
}

-(int)remoteToLocalNetworkIndicator:(int)ni
{
    [self loadTranslationTables];

    if((_pointcodeTranslationTableIn==NULL) && (_pointcodeTranslationTableNameBidi==NULL))
    {
        return ni;
    }
    if(_pointcodeTranslationTableIn.localNetworkIndicator)
    {
        return [_pointcodeTranslationTableIn.localNetworkIndicator intValue];
    }
    if(_pointcodeTranslationTableBidi.localNetworkIndicator)
    {
        return [_pointcodeTranslationTableBidi.localNetworkIndicator intValue];
    }
    return ni;
}

-(int)localToRemoteNetworkIndicator:(int)ni
{
    [self loadTranslationTables];

    if((_pointcodeTranslationTableOut==NULL) && (_pointcodeTranslationTableNameBidi==NULL))
    {
        return ni;
    }
    if(_pointcodeTranslationTableOut.remoteNetworkIndicator)
    {
        return [_pointcodeTranslationTableOut.remoteNetworkIndicator intValue];
    }
    if(_pointcodeTranslationTableBidi.localNetworkIndicator)
    {
        return [_pointcodeTranslationTableBidi.remoteNetworkIndicator intValue];
    }
    return ni;
}

- (BOOL)allowRoutingUpdateForPointcode:(UMMTP3PointCode *)pc mask:(int)mask
{
    if(mask == -1)
    {
        mask = pc.maxmask;
    }

    if((pc.pc) == (self.adjacentPointCode.pc))
    {
        return YES; /* adjacent pointcodes are always allowed as otherwise things would not work at all */
    }
    BOOL allowed = YES;
    if(_deniedPointcodesInRoutingUpdates != NULL)
    {
        for(UMMTP3PointCode *ppc in _deniedPointcodesInRoutingUpdates)
        {
            if((pc.pc) == (ppc.pc))
            {
                allowed = NO;
                break;
            }
        }
    }
    if(_permittedPointcodesInRoutingUpdates != NULL)
    {
        allowed = NO; /* if we have an allowed list, then it must be in the list */
        for(UMMTP3PointCode *ppc in _permittedPointcodesInRoutingUpdates)
        {
            if((pc.pc) == (ppc.pc))
            {
                allowed = YES;
                break;
            }
        }
    }
    return allowed;
}

- (BOOL)allowAdvertizingPointcode:(UMMTP3PointCode *)pc mask:(int)mask /* mask is ignored for now */
{
    if((pc.pc) == (self.localPointCode.pc))
    {
        return YES; /* local pointcodes are always allowed as otherwise things would not work at all */
    }
    BOOL allowed = YES;
    if(_deniedAdvertizedPointcodes != NULL)
    {
        for(UMMTP3PointCode *ppc in _deniedAdvertizedPointcodes)
        {
            if((pc.pc) == (ppc.pc))
            {
                allowed = NO;
                break;
            }
        }
    }
    if(_allowedAdvertizedPointcodes != NULL)
    {
        allowed = NO;  /* if we have an allowed list, then it must be in the list */
        for(UMMTP3PointCode *ppc in _allowedAdvertizedPointcodes)
        {
            if((pc.pc) == (ppc.pc))
            {
                allowed = YES;
                break;
            }
        }
    }
    return allowed;
}

- (void)openSccpScreeningTraceFile
{
    [self closeSccpScreeningTraceFile];
    if(_sccp_screeningPluginTraceFileName.length > 0)
    {
        _sccp_screeningPluginTraceFile = fopen(_sccp_screeningPluginTraceFileName.UTF8String,"a+");        
    }
}

- (void)closeSccpScreeningTraceFile
{
    if(_sccp_screeningPluginTraceFile)
    {
        fclose(_sccp_screeningPluginTraceFile);
        _sccp_screeningPluginTraceFile = NULL;
    }
}

- (void)writeSccpScreeningTraceFile:(NSString *)s
{
    if(_sccp_screeningPluginTraceFile)
    {
        @autoreleasepool
        {
            [_sccp_traceLock lock];
            const char *str = [s UTF8String];
            fprintf(_sccp_screeningPluginTraceFile,"%s\n",str);
            fflush(_sccp_screeningPluginTraceFile);
            [_sccp_traceLock unlock];
        }
    }
}


- (void)openMtp3ScreeningTraceFile
{
    [self closeMtp3ScreeningTraceFile];
    if(_mtp3_screeningPluginTraceFileName.length > 0)
    {
        _mtp3_screeningPluginTraceFile = fopen(_mtp3_screeningPluginTraceFileName.UTF8String,"a+");
    }
}

- (void)closeMtp3ScreeningTraceFile
{
    if(_mtp3_screeningPluginTraceFile)
    {
        fclose(_mtp3_screeningPluginTraceFile);
        _mtp3_screeningPluginTraceFile = NULL;
    }
}

- (void)writeMtp3ScreeningTraceFile:(NSString *)s;
{
    if(_mtp3_screeningPluginTraceFile)
    {
        @autoreleasepool
        {
            [_mtp3_traceLock lock];
            const char *str = [s UTF8String];
            fprintf(_mtp3_screeningPluginTraceFile,"%s\n",str);
            fflush(_mtp3_screeningPluginTraceFile);
            [_mtp3_traceLock unlock];
        }
    }
}

- (void)reopenLogfiles
{
    [self openMtp3ScreeningTraceFile];
    [self openSccpScreeningTraceFile];
}

- (void)reloadPluginConfigs
{
    [_mtp3_screeningPlugin reloadConfig];
    [_sccp_screeningPlugin reloadConfig];
}


- (void)reloadPlugins
{
    [_sccp_screeningPlugin close];
    _sccp_screeningPlugin = NULL;
    [self loadSccpScreeningPlugin];
    
    [_mtp3_screeningPlugin close];
    _mtp3_screeningPlugin = NULL;
    [self loadMtp3ScreeningPlugin];
}

- (void)loadMtp3ScreeningPlugin
{
    if(_mtp3_screeningPluginName ==NULL)
    {
        return;
    }
    /* we have a plugin but it has not been loaded yet */
    NSString *filepath;
    if(([_mtp3_screeningPluginName hasPrefix:@"/"]) || (_appdel.filterEnginesPath.length==0))
    {
        filepath = _mtp3_screeningPluginName;
    }
    else
    {
        filepath = [NSString stringWithFormat:@"%@/%@",_appdel.filterEnginesPath,_mtp3_screeningPluginName];
    }
    
    UMPluginHandler *ph = [[UMPluginHandler alloc]initWithFile:filepath];
    if(ph==NULL)
    {
        NSLog(@"PLUGIN-ERROR: can not load plugin at %@",filepath);
        _mtp3_screeningPluginName = NULL;
        _mtp3_screeningPlugin = NULL;
    }
    else
    {
        NSMutableDictionary *open_dict = [[NSMutableDictionary alloc]init];
        open_dict[@"app-delegate"]      = _appdel;
        open_dict[@"license-directory"] = _appdel.licenseDirectory;
        open_dict[@"linkset-delegate"]  = self;
        int r = [ph openWithDictionary:open_dict];
        if(r<0)
        {
            [ph close];
            _mtp3_screeningPlugin = NULL;
            _mtp3_screeningPluginName = NULL;
            NSLog(@"LOADING-ERROR: can not open plugin at path %@. Reason %@",filepath,ph.error);
        }
        else
        {
            NSDictionary *info = ph.info;
            NSString *type = info[@"type"];
            if(![type isEqualToString:@"mtp3-screening"])
            {
                [ph close];
                _mtp3_screeningPlugin = NULL;
                _mtp3_screeningPluginName = NULL;
                NSLog(@"LOADING-ERROR: plugin at path %@ is not of type mtp3-screening but %@",filepath,type);
            }
            else
            {
                UMPlugin<UMMTP3ScreeningPluginProtocol> *p = (UMPlugin<UMMTP3ScreeningPluginProtocol> *)[ph instantiate];
                if(![p respondsToSelector:@selector(screenIncomingLabel:error:linkset:)])
                {
                    [ph close];
                    _mtp3_screeningPlugin = NULL;
                    _mtp3_screeningPluginName = NULL;
                    NSLog(@"LOADING-ERROR: plugin at path %@ does not implement method screenIncomingLabel:error:linkset:",filepath);
                }
                else
                {
                    if(![p respondsToSelector:@selector(loadConfigFromFile:)])
                    {
                        [ph close];
                        _mtp3_screeningPlugin = NULL;
                        _mtp3_screeningPluginName = NULL;
                        NSLog(@"LOADING-ERROR: plugin at path %@ does not implement method loadConfigFromFile:",filepath);
                    }
                    else
                    {
                        [p loadConfigFromFile:_mtp3_screeningPluginConfigFileName];
                        _mtp3_screeningPlugin = p;
                    }
                }
            }
        }
    }
}

- (void)loadSccpScreeningPlugin
{
    /* we have a plugin but it has not been loaded yet */
    NSString *filepath;
    if(_sccp_screeningPluginName == NULL)
    {
        return;
    }
    if(([_sccp_screeningPluginName hasPrefix:@"/"]) || (_appdel.filterEnginesPath.length==0))
    {
        filepath = _sccp_screeningPluginName;
    }
    else
    {
        filepath = [NSString stringWithFormat:@"%@/%@",_appdel.filterEnginesPath,_sccp_screeningPluginName];
    }
    
    UMPluginHandler *ph = [[UMPluginHandler alloc]initWithFile:filepath];
    if(ph==NULL)
    {
        NSLog(@"PLUGIN-ERROR: can not load sccp-screening plugin at %@ for layer %@",filepath,_name);
        _sccp_screeningPlugin = NULL;
        _sccp_screeningPluginName = NULL;
    }
    else
    {
        NSMutableDictionary *open_dict = [[NSMutableDictionary alloc]init];
        open_dict[@"app-delegate"]      = _appdel;
        open_dict[@"license-directory"] = _appdel.licenseDirectory;
        open_dict[@"linkset-delegate"]  = self;
        int r = [ph openWithDictionary:open_dict];
        if(r<0)
        {
            [ph close];
            _sccp_screeningPlugin = NULL;
            _sccp_screeningPluginName = NULL;
            NSLog(@"LOADING-ERROR: can not open plugin at path %@. Reason %@",filepath,ph.error);
        }
        else
        {
            NSDictionary *info = ph.info;
            NSString *type = info[@"type"];
            if(![type isEqualToString:@"sccp-screening"])
            {
                [ph close];
                _sccp_screeningPlugin = NULL;
                _sccp_screeningPluginName = NULL;
                NSLog(@"LOADING-ERROR: plugin at path %@ is not of type mtp3-screening but %@",filepath,type);
            }
            else
            {
                UMPlugin<UMMTP3SCCPScreeningPluginProtocol> *p = (UMPlugin<UMMTP3SCCPScreeningPluginProtocol> *)[ph instantiate];
                if(![p respondsToSelector:@selector(screenSccpPacketInbound:error:)])
                {
                    [ph close];
                    _sccp_screeningPlugin = NULL;
                    _sccp_screeningPluginName = NULL;
                    NSLog(@"LOADING-ERROR: plugin at path %@ does not implement method screenSccpPacketInbound:error:plugin:traceDestination:",filepath);
                }
                else
                {

                    if(![p respondsToSelector:@selector(loadConfigFromFile:)])
                    {
                        [ph close];
                        _mtp3_screeningPlugin = NULL;
                        _mtp3_screeningPluginName = NULL;
                        NSLog(@"LOADING-ERROR: plugin at path %@ does not implement method screenSccpPacketInbound:error:plugin:traceDestination::",filepath);
                    }
                    else
                    {
                        [p loadConfigFromFile:_sccp_screeningPluginConfigFileName];
                        _sccp_screeningPlugin = p;
                    }
                }
            }
        }
    }
}
@end
