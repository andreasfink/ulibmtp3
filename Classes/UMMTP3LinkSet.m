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
#import "UMMTP3RoutingTable.h"
#import "UMMTP3LinkRoutingTable.h"
#import "UMMTP3InstanceRoutingTable.h"

@implementation UMMTP3LinkSet

- (UMMTP3LinkSet *)init
{
    self = [super init];
    if(self)
    {
        _links = [[UMSynchronizedSortedDictionary alloc]init];
        _linksLock = [[UMMutex alloc]initWithName:@"mtp3linkset-links-mutex"];
        _slsLock = [[UMMutex alloc]initWithName:@"mtp3-sls-lock"];
        _name = @"untitled";

        _activeLinks = -1;
        _inactiveLinks = -1;
        _readyLinks = -1;
        _totalLinks = -1;
        _congestionLevel = 0;
        _networkIndicator = -1;
        _logLevel = UMLOG_MAJOR;
        _routingTable = [[UMMTP3LinkRoutingTable alloc]init];
    }
    return self;
}

- (void)addLink:(UMMTP3Link *)lnk
{
    [_linksLock lock];
    lnk.name = [NSString stringWithFormat:@"%@:%d",_name,lnk.slc];
    _links[lnk.name]=lnk;
    lnk.linkset = self;
    _totalLinks++;
    [_linksLock unlock];
}

- (void)removeLink:(UMMTP3Link *)lnk
{
    [_linksLock lock];
    lnk.linkset = NULL;
    [_links removeObjectForKey:lnk.name];
    _totalLinks--;
    [_linksLock unlock];

}
- (void)removeAllLinks
{
    [_linksLock lock];
    _links = NULL;
    _links = [[UMSynchronizedSortedDictionary alloc]init];
    _totalLinks=0;
    [_linksLock unlock];
}

- (void)removeLinkByName:(NSString *)n
{
    UMMTP3Link *lnk = _links[n];
    lnk.linkset = NULL;
    [_links removeObjectForKey:n];

}

- (UMMTP3Link *)getLinkByName:(NSString *)n
{
    UMMTP3Link *lnk = _links[n];
    return lnk;
}

- (UMMTP3Link *)getAnyLink
{
    NSArray *linkKeys = [_links allKeys];
    NSMutableArray *activeLinkKeys = [[NSMutableArray alloc]init];
    for(NSString *key in linkKeys)
    {
        UMMTP3Link *link = _links[key];
        if(link.m2pa_status == M2PA_STATUS_IS)
        {
            [activeLinkKeys addObject:key];
        }
    }
    NSUInteger n = [activeLinkKeys count];
    if(n==0)
    {
        return NULL;
    }
    _linkSelector = _linkSelector + 1;
    _linkSelector = _linkSelector % n;
    NSString *key = activeLinkKeys[_linkSelector];
    UMMTP3Link *link = _links[key];
    return link;
}

/* as we use link names in the form <linkset>:<slc> we can not allow colons in linkset names so we remove them */
- (NSString *)name
{
    return _name;
}

- (void)setName:(NSString *)n
{
    _name = [n stringByReplacingOccurrencesOfString:@":" withString:@""];
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
        [logFeed debugText:@" FISU (Fill-in Signal Unit). (We should not get this on M2PA data link)"];
    }
}


-(void) protocolViolation
{
    [logFeed majorErrorText:@"protocolViolation"];
}

- (void)lssuIndication:(const unsigned char *)data maxlen:(size_t)maxlen slc:(int)slc
{
    if(maxlen < 2)
    {
        [logFeed majorErrorText:@"LSSU received with less than 2 byte"];
        [self protocolViolation];
        return;
    }

    int sf = data[1];
    if(_logLevel <=UMLOG_DEBUG)
    {
        [logFeed debugText:@" LSSU (m3link Status Signal Unit) (We should not get this on M2PA data link)"];
        [logFeed debugText:[NSString stringWithFormat:@" Status Field (SF): [%d]",sf]];
        switch(sf & 0x07)
        {
            case 0:
                [logFeed debugText:@"  {SIO} OUT OF ALIGNMENT"];
                break;
            case 1:
                [logFeed debugText:@"  {SIN} NORMAL ALIGNMENT"];
                break;
            case 2:
                [logFeed debugText:@"  {SIE} EMERGENCY ALIGNMENT"];
                break;
            case 3:
                [logFeed debugText:@"  {SIOS} OUT OF SERVICE"];
                break;
            case 4:
                [logFeed debugText:@"  {SIPO} PROCESSOR OUTAGE"];
                break;
            case 5:
                [logFeed debugText:@"  {SIB} BUSY"];
                break;
            default:
                [logFeed debugText:@"  {unknown}"];
                break;
        }
    }
}

- (void)dataIndication:(NSData *)dataIn slc:(int)slc
{
    const unsigned char *data = dataIn.bytes;
    size_t maxlen = dataIn.length;

    if(maxlen <1)
    {
        /* an empty packet to ack the outstanding FSN/BSN */
        /* kind of a FISU */
        if(_logLevel <= UMLOG_DEBUG)
        {
            [logFeed debugText:@" empty MSU"];
        }
        return;
    }
    size_t li = data[0] & 0x3F; /* length indicator */
    switch(li)
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
            [logFeed minorErrorText:@" LSSU (m3link Status Signal Unit 2 bytes) not permitted for M2PA"];
            break;
        default:
            [self msuIndication:data maxlen:maxlen slc:slc];
            break;
    }
}

- (UMMTP3TransitPermission_result)screenIncomingLabel:(UMMTP3Label *)label error:(NSError **)err
{
    /* here we check if we allow the incoming pointcode from this link */
    if(label.opc.variant != self.variant)
    {
        if(err)
        {
            *err = [NSError errorWithDomain:@"mtp_decode" code:0 userInfo:@{@"sysinfo":@"opc-variant does not match local variant",@"backtrace": UMBacktrace(NULL,0)}];
        }
        return UMMTP3TransitPermission_errorResult;
    }
    if(label.dpc.variant != self.variant)
    {
        if(err)
        {
            *err = [NSError errorWithDomain:@"mtp_decode" code:0 userInfo:@{@"sysinfo":@"dpc-variant does not match local variant",@"backtrace": UMBacktrace(NULL,0)}];
        }
        return UMMTP3TransitPermission_errorResult;
    }
    
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

- (void)msuIndication:(const unsigned char *)data maxlen:(size_t)maxlen slc:(int)slc
{
    UMMTP3Link *link = [self linkForSlc:slc];
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
            [logFeed debugText:@" MSU (Message Signal Unit)"];
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
        NSData *pdu = [NSData dataWithBytes:&data[idx] length:(maxlen - idx)];
        [self msuIndication2:pdu
                       label:label
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
        [logFeed majorErrorText:desc];
        [self protocolViolation];
        return;
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
    @try
    {
        if(_logLevel <= UMLOG_DEBUG)
        {
            [logFeed debugText:[NSString stringWithFormat:@"  data2: [%@]",pdu]];
            [logFeed debugText:[NSString stringWithFormat:@" maxlen: [%d]",(int)maxlen]];
            [logFeed debugText:[NSString stringWithFormat:@"     si: [%d]",si]];
            [logFeed debugText:[NSString stringWithFormat:@"     ni: [%d]",ni]];
            [logFeed debugText:[NSString stringWithFormat:@"     mp: [%d]",mp]];
            [logFeed debugText:[NSString stringWithFormat:@"    opc: %@",label.opc.description]];
            [logFeed debugText:[NSString stringWithFormat:@"    dpc: %@",label.dpc.description]];
        }
        if(ni != _networkIndicator)
        {
            [logFeed majorErrorText:[NSString stringWithFormat:@"NI received is %d but is expected to be %d",ni,_networkIndicator]];
            [self protocolViolation];
            @throw([NSException exceptionWithName:@"MTP_PACKET_INVALID"
                                           reason:NULL
                                         userInfo:@{
                                                    @"sysmsg" : @"non-matching network indicator",
                                                    @"func": @(__func__),
                                                    @"obj":self,
                                                    @"backtrace": UMBacktrace(NULL,0)
                                                    }
                    ]);

        }
        if(link && (link.m2pa_status != M2PA_STATUS_IS))
        {
            /* All messages to another destination received at a signalling point whose MTP is restarting are discarded.*/
            if(![label.dpc isEqualToPointCode:_localPointCode])
            {
                [self logMinorError:@"MTP_DECODE: no-relay-during-startup"];
                @throw([NSException exceptionWithName:@"MTP_DECODE"
                                               reason:NULL
                                             userInfo:@{
                                                        @"sysmsg" : @"no-relay-during-startup",
                                                        @"func": @(__func__),
                                                        @"obj":self,
                                                        @"backtrace": UMBacktrace(NULL,0)
                                                        }
                        ]);
            }
        };
        NSError *e = NULL;

        UMMTP3TransitPermission_result perm = [self screenIncomingLabel:label error:&e];
        switch(perm)
        {
            case UMMTP3TransitPermission_errorResult:
                @throw([NSException exceptionWithName:@"UMMTP3TransitPermission_errorResult"
                                               reason:NULL
                                             userInfo:@{
                                                        @"sysmsg" : @"screening failed",
                                                        @"func": @(__func__),
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
                    [logFeed debugText:[NSString stringWithFormat:@"  screening: explicitly denied"]];
                }
                break;
            }
            case UMMTP3TransitPermission_implicitlyDenied:
            {
                if(_logLevel <= UMLOG_DEBUG)
                {
                    [logFeed debugText:[NSString stringWithFormat:@"  screening: implicitly denied"]];
                    break;
                }
            }
            case UMMTP3TransitPermission_explicitlyPermitted:
            {
                if(_logLevel <= UMLOG_DEBUG)
                {
                    [logFeed debugText:[NSString stringWithFormat:@"  screening: explicitly permitted"]];
                }
                break;
            }
            case UMMTP3TransitPermission_implicitlyPermitted:
            {
                if(_logLevel <= UMLOG_DEBUG)
                {
                    [logFeed debugText:[NSString stringWithFormat:@"  screening: implicitly permitted"]];
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
                    [logFeed debugText:[NSString stringWithFormat:@"  Service Indicator: [%d] Signalling network testing and maintenance messages",si]];
                }
                int heading;
                GRAB_BYTE(heading,data,idx,maxlen);
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
                            [logFeed majorErrorText:@"SLTM: SLC received is not matching the links configured SLC"];
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
                            [self logMajorError:@"MTP_DECODE: SLTA SLC received is not matching the links configured SLC"];
                            [self protocolViolation];
                        }
                        if ((idx+len)>maxlen)
                        {
                            @throw([NSException exceptionWithName:@"MTP_DECODE"
                                                           reason:NULL
                                                         userInfo:@{
                                                                    @"sysmsg" : @"too-short-packet in SLTA",
                                                                    @"func": @(__func__),
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
                    [logFeed debugText:[NSString stringWithFormat:@"  Service Indicator: [%d] Signalling network management messages",si]];
                }
                int heading;
                GRAB_BYTE(heading,data,idx,maxlen);
                switch(heading)
                {
                    case MTP3_MGMT_COO:
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
                        [self processCOO:label lastFSN:fsn ni:ni mp:mp slc:slc link:link];
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
                            [logFeed debugText:[NSString stringWithFormat:@"  H0/H1: [0x%02X] RST Signalling-route-set-test signal for prohibited destination",heading]];
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
                    case MTP3_MGMT_UPT:
                        break;
                }
            }
                break;
            case MTP3_SERVICE_INDICATOR_SCCP:
            {
                NSData *pdu2 = [NSData dataWithBytes:&data[idx] length:(maxlen-idx)];
                if(_logLevel <= UMLOG_DEBUG)
                {
                    [logFeed debugText:[NSString stringWithFormat:@"  Service Indicator: [%d] SCCP",si]];
                    [logFeed debugText:[NSString stringWithFormat:@"  Data: %@ ",pdu2]];
                    [logFeed debugText:[NSString stringWithFormat:@"  idx=: %d ",idx]];
                }
                [_mtp3 processIncomingPdu:label data:pdu2 userpartId:si ni:ni mp:mp linksetName:_name];
            }
                break;
            case MTP3_SERVICE_INDICATOR_TUP:
            {
                if(_logLevel <= UMLOG_DEBUG)
                {
                    [logFeed debugText:[NSString stringWithFormat:@"  Service Indicator: [%d] SPARE_TUP",si]];
                }
                NSData *pdu = [NSData dataWithBytes:data+idx length:maxlen-idx];
                [_mtp3 processIncomingPdu:label data:pdu userpartId:si ni:ni mp:mp linksetName:_name];

            }
                break;
            case MTP3_SERVICE_INDICATOR_ISUP:
            {
                if(_logLevel <= UMLOG_DEBUG)
                {
                    [logFeed debugText:[NSString stringWithFormat:@"  Service Indicator: [%d] SPARE_ISUP",si]];
                }
                NSData *pdu = [NSData dataWithBytes:data+idx length:maxlen-idx];
                [_mtp3 processIncomingPdu:label data:pdu userpartId:si ni:ni mp:mp linksetName:_name];

            }
                break;
            case MTP3_SERVICE_INDICATOR_DUP_C:
            {
                if(_logLevel <= UMLOG_DEBUG)
                {
                    [logFeed debugText:[NSString stringWithFormat:@"  Service Indicator: [%d] SPARE_DUP_C",si]];
                }
                NSData *pdu = [NSData dataWithBytes:data+idx length:maxlen-idx];
                [_mtp3 processIncomingPdu:label data:pdu userpartId:si ni:ni mp:mp linksetName:_name];

            }
                break;
            case MTP3_SERVICE_INDICATOR_DUP_F:
            {
                if(_logLevel <= UMLOG_DEBUG)
                {
                    [logFeed debugText:[NSString stringWithFormat:@"  Service Indicator: [%d] SPARE_DUP_F",si]];
                }
                NSData *pdu = [NSData dataWithBytes:data+idx length:maxlen-idx];
                [_mtp3 processIncomingPdu:label data:pdu userpartId:si ni:ni mp:mp linksetName:_name];

            }
                break;
            case MTP3_SERVICE_INDICATOR_RES_TESTING:
            {
                if(_logLevel <= UMLOG_DEBUG)
                {
                    [logFeed debugText:[NSString stringWithFormat:@"  Service Indicator: [%d] SPARE_RES_TESTING",si]];
                }
                NSData *pdu = [NSData dataWithBytes:data+idx length:maxlen-idx];
                [_mtp3 processIncomingPdu:label data:pdu userpartId:si ni:ni mp:mp linksetName:_name];

            }
                break;
            case MTP3_SERVICE_INDICATOR_BROADBAND_ISUP:
            {
                if(_logLevel <= UMLOG_DEBUG)
                {
                    [logFeed debugText:[NSString stringWithFormat:@"  Service Indicator: [%d] SPARE_ISUP",si]];
                }
                NSData *pdu = [NSData dataWithBytes:data+idx length:maxlen-idx];
                [_mtp3 processIncomingPdu:label data:pdu userpartId:si ni:ni mp:mp linksetName:_name];

            }
                break;
            case MTP3_SERVICE_INDICATOR_SAT_ISUP:
            {
                if(_logLevel <= UMLOG_DEBUG)
                {
                    [logFeed debugText:[NSString stringWithFormat:@"  Service Indicator: [%d] SPARE_SAT_ISUP",si]];
                }
                NSData *pdu = [NSData dataWithBytes:data+idx length:maxlen-idx];
                [_mtp3 processIncomingPdu:label data:pdu userpartId:si ni:ni mp:mp linksetName:_name];

            }
                break;
            case MTP3_SERVICE_INDICATOR_SPARE_B:
            {
                if(_logLevel <= UMLOG_DEBUG)
                {
                    [logFeed debugText:[NSString stringWithFormat:@"  Service Indicator: [%d] SPARE_B",si]];
                }
                NSData *pdu = [NSData dataWithBytes:data+idx length:maxlen-idx];
                [_mtp3 processIncomingPdu:label data:pdu userpartId:si ni:ni mp:mp linksetName:_name];

            }
                break;
            case MTP3_SERVICE_INDICATOR_SPARE_C:
            {
                if(_logLevel <= UMLOG_DEBUG)
                {
                    [logFeed debugText:[NSString stringWithFormat:@"  Service Indicator: [%d] SPARE_C",si]];
                }
                NSData *pdu = [NSData dataWithBytes:data+idx length:maxlen-idx];
                [_mtp3 processIncomingPdu:label data:pdu userpartId:si ni:ni mp:mp linksetName:_name];

            }
                break;
            case MTP3_SERVICE_INDICATOR_SPARE_D:
            {
                if(_logLevel <= UMLOG_DEBUG)
                {
                    [logFeed debugText:[NSString stringWithFormat:@"  Service Indicator: [%d] SPARE_D",si]];
                }
                NSData *pdu = [NSData dataWithBytes:data+idx length:maxlen-idx];
                [_mtp3 processIncomingPdu:label data:pdu userpartId:si ni:ni mp:mp linksetName:_name];

            }
                break;
            case MTP3_SERVICE_INDICATOR_SPARE_E:
            {
                if(_logLevel <= UMLOG_DEBUG)
                {
                    [logFeed debugText:[NSString stringWithFormat:@"  Service Indicator: [%d] SPARE_E",si]];
                }
                NSData *pdu = [NSData dataWithBytes:data+idx length:maxlen-idx];
                [_mtp3 processIncomingPdu:label data:pdu userpartId:si ni:ni mp:mp linksetName:_name];

            }
                break;
            case MTP3_SERVICE_INDICATOR_SPARE_F:
            {
                if(_logLevel <= UMLOG_DEBUG)
                {
                    [logFeed debugText:[NSString stringWithFormat:@"  Service Indicator: [%d] SPARE_F",si]];
                }
                NSData *pdu = [NSData dataWithBytes:data+idx length:maxlen-idx];
                [_mtp3 processIncomingPdu:label data:pdu userpartId:si ni:ni mp:mp linksetName:_name];

            }
                break;
        }
    }
    @catch(NSException *e)
    {
        //NSDictionary *d = e.userInfo;
        //NSString *desc = d[@"sysmsg"];
        [logFeed majorErrorText:[NSString stringWithFormat:@"Exception %@",e]];
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
    if(![self isFromAdjacentToLocal:label])
    {
        [self logMajorError:[NSString stringWithFormat:@"unexpected STLM transiting Label = %@. Should be %@->%@", label.logDescription,_adjacentPointCode.logDescription,_localPointCode.logDescription]];
        [self protocolViolation];
        return;
    }

    UMMTP3Label *reverse_label = [label reverseLabel];
    [self sendSLTA:reverse_label pattern:pattern ni:ni mp:mp slc:slc link:link];
    [self updateLinksetStatus];
}

- (void)processSLTA:(UMMTP3Label *)label
            pattern:(NSData *)pattern
                 ni:(int)ni
                 mp:(int)mp
                slc:(int)slc
               link:(UMMTP3Link *)link
{
    if(![self isFromAdjacentToLocal:label])
    {
        [self logMajorError:[NSString stringWithFormat:@"unexpected STLM transiting Label = %@. Should be %@->%@", label.logDescription,_adjacentPointCode.logDescription,_localPointCode.logDescription]];
        [self protocolViolation];
        return;
    }
    if(_sendTRA)
    {
        UMMTP3Label *reverse_label = [label reverseLabel];

        [self sendTRA:reverse_label ni:ni mp:mp slc:slc link:link];
        _sendTRA = NO;
    }
    [self updateLinksetStatus];
}

- (void)processSSLTM:(UMMTP3Label *)label
            pattern:(NSData *)pattern
                 ni:(int)ni
                 mp:(int)mp
                slc:(int)slc
               link:(UMMTP3Link *)link
{

    if(![self isFromAdjacentToLocal:label])
    {
        [self logMajorError:[NSString stringWithFormat:@"unexpected SSTLM transiting Label = %@. Should be %@->%@", label.logDescription,_adjacentPointCode.logDescription,_localPointCode.logDescription]];
        [self protocolViolation];
        return;
    }
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
    if(![self isFromAdjacentToLocal:label])
    {
        [self logMajorError:[NSString stringWithFormat:@"unexpected STLM transiting Label = %@. Should be %@->%@", label.logDescription,_adjacentPointCode.logDescription,_localPointCode.logDescription]];
        [self protocolViolation];
        return;
    }
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
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"processTFC (Transfer-controlled signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" destination: %@",pc.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",self.name]];
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

- (void)processTFP:(UMMTP3Label *)label destination:(UMMTP3PointCode *)pc ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"processTFP (Transfer-prohibited signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" destination: %@",pc.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",self.name]];
    }
    [self updateRouteUnavailable:pc mask:0];

}


- (void)processTFR:(UMMTP3Label *)label destination:(UMMTP3PointCode *)pc ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"processTFR (Transfer-restricted signal (national option))"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" destination: %@",pc.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",self.name]];
    }
    [self updateRouteRestricted:pc mask:0];
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

- (void)processTFA:(UMMTP3Label *)label destination:(UMMTP3PointCode *)pc ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"processTFA (Transfer-allowed signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" destination: %@",pc.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",self.name]];
    }
    [self updateRouteAvailable:pc mask:0];
}



/* Group RSM */
- (void)processRST:(UMMTP3Label *)label destination:(UMMTP3PointCode *)pc ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"processRST (Signalling-route-set-test signal for prohibited destination)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" destination: %@",pc.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",self.name]];
    }
}

- (void)processRSR:(UMMTP3Label *)label destination:(UMMTP3PointCode *)pc ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"processRSR (Signalling-route-set-test signal for restricted destination (national option))"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" destination: %@",pc.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",self.name]];
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
- (void)processTRA:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    [self updateLinksetStatus];
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"processTRA (Traffic-restart-allowed signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",self.name]];
    }
    [self updateRouteAvailable:_adjacentPointCode mask:0];
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
    if(_variant != UMMTP3Variant_ANSI)
    {
        [self logMajorError:@"unexpected TCA packet in non ANSI mode"];
        [self logMajorError:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logMajorError:[NSString stringWithFormat:@" destination: %@",pc]];
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
        [self logMajorError:[NSString stringWithFormat:@" destination: %@",pc]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",self.name]];
    }
}


- (void)processTCP:(UMMTP3Label *)label destination:(UMMTP3PointCode *)pc ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_variant != UMMTP3Variant_ANSI)
    {
        [self logMajorError:@"unexpected TCP packet in non ANSI mode"];
        [self logMajorError:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logMajorError:[NSString stringWithFormat:@" destination: %@",pc]];
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
        [self logMajorError:[NSString stringWithFormat:@" destination: %@",pc]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",self.name]];
    }
}

- (void)processTCR:(UMMTP3Label *)label destination:(UMMTP3PointCode *)pc ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_variant != UMMTP3Variant_ANSI)
    {
        [self logMajorError:@"unexpected TCR packet in non ANSI mode"];
        [self logMajorError:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logMajorError:[NSString stringWithFormat:@" destination: %@",pc]];
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
        [self logMajorError:[NSString stringWithFormat:@" destination: %@",pc]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",self.name]];
    }
}

- (void)processRCP:(UMMTP3Label *)label destination:(UMMTP3PointCode *)pc ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_variant != UMMTP3Variant_ANSI)
    {
        [self logMajorError:@"unexpected RCP packet in non ANSI mode"];
        [self logMajorError:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logMajorError:[NSString stringWithFormat:@" destination: %@",pc]];
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
        [self logMajorError:[NSString stringWithFormat:@" destination: %@",pc]];
        [self logDebug:[NSString stringWithFormat:@" ni: %d",ni]];
        [self logDebug:[NSString stringWithFormat:@" slc: %d",slc]];
        [self logDebug:[NSString stringWithFormat:@" link: %@",link.name]];
        [self logDebug:[NSString stringWithFormat:@" linkset: %@",self.name]];
    }
}

- (void)processRCR:(UMMTP3Label *)label destination:(UMMTP3PointCode *)pc ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    if(_variant != UMMTP3Variant_ANSI)
    {
        [self logMajorError:@"unexpected RCR packet in non ANSI mode"];
        [self logMajorError:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logMajorError:[NSString stringWithFormat:@" destination: %@",pc]];
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
        [self logMajorError:[NSString stringWithFormat:@" destination: %@",pc]];
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
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:@"processUPU (User part unavailable signal)"];
        [self logDebug:[NSString stringWithFormat:@" label: %@",label.description]];
        [self logDebug:[NSString stringWithFormat:@" destination: %@",pc.description]];
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
    [self sendPdu:pdu
            label:label
          heading:MTP3_TESTING_SLTA
             link:link
              slc:slc
               ni:ni
               mp:mp
               si:MTP3_SERVICE_INDICATOR_TEST
       ackRequest:NULL];
}

- (void)sendSLTM:(UMMTP3Label *)label
         pattern:(NSData *)pattern
              ni:(int)ni
              mp:(int)mp
             slc:(int)slc
            link:(UMMTP3Link *)link
{
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
    [self sendPdu:pdu
            label:label
          heading:MTP3_TESTING_SLTM
             link:link
              slc:slc
               ni:ni
               mp:mp
               si:MTP3_SERVICE_INDICATOR_TEST
       ackRequest:NULL];
}

- (void)sendSSLTA:(UMMTP3Label *)label
         pattern:(NSData *)pattern
              ni:(int)ni
              mp:(int)mp
             slc:(int)slc
            link:(UMMTP3Link *)link
{
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
    [self sendPdu:pdu
            label:label
          heading:MTP3_ANSI_TESTING_SSLTA
             link:link
              slc:slc
               ni:ni
               mp:mp
               si:MTP3_ANSI_SERVICE_INDICATOR_TEST
       ackRequest:NULL];
}

- (void)sendSSLTM:(UMMTP3Label *)label
         pattern:(NSData *)pattern
              ni:(int)ni
              mp:(int)mp
             slc:(int)slc
            link:(UMMTP3Link *)link
{
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
    [self sendPdu:pdu
            label:label
          heading:MTP3_ANSI_TESTING_SSLTM
             link:link
              slc:slc
               ni:ni
               mp:mp
               si:MTP3_ANSI_SERVICE_INDICATOR_TEST
       ackRequest:NULL];
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
{
    if(link == NULL)
    {
        link = [self getAnyLink];
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
        label.sls = _last_sls;
        _last_sls = (_last_sls+1) % 16;
        [_slsLock unlock];
    }
    else
    {
        label.sls = slc;
    }
    [label appendToMutableData:pdu];
    if(heading >= 0)
    {
        uint8_t heading_byte = heading & 0xFF;
        [pdu appendByte:heading_byte];
    }
    if(data)
    {
        [pdu appendData:data];
    }
    [link.m2pa dataFor:_mtp3 data:pdu ackRequest:ackRequest];
}


-(void)sendPdu:(NSData *)data
         label:(UMMTP3Label *)label
       heading:(int)heading
            ni:(int)ni
            mp:(int)mp
            si:(int)si
    ackRequest:(NSDictionary *)ackRequest
 correlationId:(uint32_t)correlation_id
{
    [self sendPdu:data
            label:label
          heading:heading
             link:NULL
              slc:-1
               ni:ni
               mp:mp
               si:si
       ackRequest:ackRequest];
}

-(void)sendPdu:(NSData *)data
         label:(UMMTP3Label *)label
       heading:(int)heading
            ni:(int)ni
            mp:(int)mp
            si:(int)si
    ackRequest:(NSDictionary *)ackRequest
{
    [self sendPdu:data
            label:label
          heading:heading
             link:NULL
              slc:-1
               ni:ni
               mp:mp
               si:si
       ackRequest:ackRequest];
}

#pragma mark -
#pragma mark Config stuff

- (NSDictionary *)config
{
    NSMutableDictionary *config = [[NSMutableDictionary alloc]init];
    NSArray *allkeys = [_links allKeys];

    for(id key in allkeys)
    {
        UMMTP3Link *link = _links[key];
        config[[NSString stringWithFormat:@"attach-slc%d",link.slc]] = link.name;
    }
    config[@"dpc"] = [_adjacentPointCode stringValue];
    return config;
}

- (void)setDefaultValues
{
    _variant = UMMTP3Variant_Undefined;
    _networkIndicator = -1;
    _speed = -1.0;
}

- (void)setDefaultValuesFromMTP3
{
    if(_localPointCode == NULL)
    {
        _localPointCode = _mtp3.opc;
    }
    if(_variant==UMMTP3Variant_Undefined)
    {
        _variant = _mtp3.variant;
    }
    if(_networkIndicator == -1)
    {
        _networkIndicator = _mtp3.networkIndicator;
    }
    if(_speed < 0)
    {
        _speed = 1000.0;
    }
}

- (void)setConfig:(NSDictionary *)cfg applicationContext:(id)appContext
{
    [self removeAllLinks];
    NSString *apcString = @"";
    NSString *opc;


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
    if(cfg[@"opc"])
    {
        opc = [cfg[@"speed"] stringValue];
    }

    for(int slc=0;slc<16;slc++)
    {
        NSString *key = [NSString stringWithFormat:@"attach-slc%d",slc];
        if(cfg[_name])
        {
            NSString *m2pa_name = cfg[key];
            UMMTP3Link *link = [[UMMTP3Link alloc]init];
            link.slc = slc;
            link.name = m2pa_name;
            link.linkset = self;
            _links[link.name] = link;
        }
    }

    if(cfg[@"attach-to"])
    {
        NSString *attachTo = [cfg[@"attach-to"] stringValue];
        _mtp3 = [appContext getMTP3:attachTo];
        if(_mtp3 == NULL)
        {
            NSString *s = [NSString stringWithFormat:@"Can not find mtp3 layer '%@' referred from mtp3 linkset '%@'",attachTo,_name];
            [self logMajorError:s];
            @throw([NSException exceptionWithName:[NSString stringWithFormat:@"CONFIG_ERROR FILE %s line:%ld",__FILE__,(long)__LINE__]
                                           reason:s
                                         userInfo:NULL]);
        }
    }


    if(cfg[@"network-indicator"])
    {
        NSString *s = [cfg[@"network-indicator"] stringValue];
        if((  [s isEqualToStringCaseInsensitive:@"international"])
           || ([s isEqualToStringCaseInsensitive:@"int"])
           || ([s isEqualToStringCaseInsensitive:@"0"]))
        {
            _networkIndicator = 0;
        }
        else if(([s isEqualToStringCaseInsensitive:@"national"])
                || ([s isEqualToStringCaseInsensitive:@"nat"])
                || ([s isEqualToStringCaseInsensitive:@"2"]))
        {
            _networkIndicator = 2;
        }
        else if(([s isEqualToStringCaseInsensitive:@"spare"])
                || ([s isEqualToStringCaseInsensitive:@"international-spare"])
                || ([s isEqualToStringCaseInsensitive:@"int-spare"])
                || ([s isEqualToStringCaseInsensitive:@"1"]))
        {
            _networkIndicator = 1;
        }
        else if(([s isEqualToStringCaseInsensitive:@"reserved"])
                || ([s isEqualToStringCaseInsensitive:@"national-reserved"])
                || ([s isEqualToStringCaseInsensitive:@"nat-reserved"])
                || ([s isEqualToStringCaseInsensitive:@"3"]))
        {
            _networkIndicator = 3;
        }
        else
        {
            [self logMajorError:[NSString stringWithFormat:@"Unknown M3UA network-indicator '%@' defaulting to international",s]];
            _networkIndicator = 0;
        }
    }
    if(cfg[@"log-level"])
    {
        _logLevel = [cfg[@"log-level"] intValue];
    }

    self.variant = _mtp3.variant;
    self.adjacentPointCode = [[UMMTP3PointCode alloc]initWithString:apcString variant:_mtp3.variant];
    self.name = _name;
    if((_mtp3) && (_variant==UMMTP3Variant_Undefined))
    {
        _variant = _mtp3.variant;
    }
    if(_variant == UMMTP3Variant_Undefined)
    {
        _variant = UMMTP3Variant_ITU;
    }
    if(opc)
    {
        self.localPointCode = [[UMMTP3PointCode alloc]initWithString:opc variant:_variant];
    }
    else
    {
        _localPointCode = _mtp3.opc;
    }
    if(_networkIndicator == -1)
    {
        _networkIndicator = _mtp3.networkIndicator;
    }
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
       ackRequest:NULL];
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
       ackRequest:NULL];
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
       ackRequest:NULL];
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
       ackRequest:NULL];
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
       ackRequest:NULL];
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
       ackRequest:NULL];
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
       ackRequest:NULL];
}

- (void)sendTFC:(UMMTP3Label *)label
    destination:(UMMTP3PointCode *)pc
         status:(int)status
             ni:(int)ni
             mp:(int)mp
            slc:(int)slc
           link:(UMMTP3Link *)link
{
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
    
    [self sendPdu:[pc asDataWithStatus:status]
            label:label
          heading:MTP3_MGMT_TFC
             link:link
              slc:slc
               ni:ni
               mp:mp
               si:MTP3_SERVICE_INDICATOR_MGMT
       ackRequest:NULL];
}

/* Group TFM */
- (void)sendTFP:(UMMTP3Label *)label destination:(UMMTP3PointCode *)pc ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
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
    [self sendPdu:[pc asData]
            label:label
          heading:MTP3_MGMT_TFP
             link:link
              slc:slc
               ni:ni
               mp:mp
               si:MTP3_SERVICE_INDICATOR_MGMT
       ackRequest:NULL];
}

- (void)sendTFR:(UMMTP3Label *)label destination:(UMMTP3PointCode *)pc ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
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
    [self sendPdu:[pc asData]
            label:label
          heading:MTP3_MGMT_TFR
             link:link
              slc:slc
               ni:ni
               mp:mp
               si:MTP3_SERVICE_INDICATOR_MGMT
       ackRequest:NULL];
}

- (void)sendTFA:(UMMTP3Label *)label destination:(UMMTP3PointCode *)pc ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
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
    [self sendPdu:[pc asData]
            label:label
          heading:MTP3_MGMT_TFA
             link:link
              slc:slc
               ni:ni
               mp:mp
               si:MTP3_SERVICE_INDICATOR_MGMT
       ackRequest:NULL];
}

/* Group RSM */
- (void)sendRST:(UMMTP3Label *)label destination:(UMMTP3PointCode *)pc ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
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
    [self sendPdu:[pc asData]
            label:label
          heading:MTP3_MGMT_RST
             link:link
              slc:slc
               ni:ni
               mp:mp
               si:MTP3_SERVICE_INDICATOR_MGMT
       ackRequest:NULL];
}
- (void)sendRSR:(UMMTP3Label *)label destination:(UMMTP3PointCode *)pc ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
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
    [self sendPdu:[pc asData]
            label:label
          heading:MTP3_MGMT_RSR
             link:link
              slc:slc
               ni:ni
               mp:mp
               si:MTP3_SERVICE_INDICATOR_MGMT
       ackRequest:NULL];
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
       ackRequest:NULL];
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
       ackRequest:NULL];
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
       ackRequest:NULL];
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
       ackRequest:NULL];
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
       ackRequest:NULL];
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
       ackRequest:NULL];
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
       ackRequest:NULL];
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
       ackRequest:NULL];
}

- (void)sendTRA:(UMMTP3Label *)label ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
    _tra_sent++;
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
       ackRequest:NULL];
    
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
       ackRequest:NULL];
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
       ackRequest:NULL];
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
       ackRequest:NULL];
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
       ackRequest:NULL];
}
/* group UFC */
- (void)sendUPU:(UMMTP3Label *)label destination:(UMMTP3PointCode *)pc userpartId:(int)upid cause:(int)cause ni:(int)ni mp:(int)mp slc:(int)slc link:(UMMTP3Link *)link
{
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
    NSMutableData *pdu = [[NSMutableData alloc]initWithData:[pc asData]];
    [pdu appendByte: ((upid & 0x0F) | (cause & 0x0F << 8))];
    [self sendPdu:pdu
            label:label
          heading:MTP3_MGMT_UPU
             link:link
              slc:slc
               ni:ni
               mp:mp
               si:MTP3_SERVICE_INDICATOR_MGMT
       ackRequest:NULL];
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
    NSMutableData *pdu = [[NSMutableData alloc]initWithData:[pc asData]];
    [pdu appendByte: ((upid & 0x0F) | (cause & 0x0F << 8))];
    [self sendPdu:pdu
            label:label
          heading:MTP3_MGMT_UPA
             link:link
              slc:slc
               ni:ni
               mp:mp
               si:MTP3_SERVICE_INDICATOR_MGMT
       ackRequest:NULL];
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
    NSMutableData *pdu = [[NSMutableData alloc]initWithData:[pc asData]];
    [pdu appendByte: ((upid & 0x0F) | (cause & 0x0F << 8))];
    [self sendPdu:pdu
            label:label
          heading:MTP3_MGMT_UPT
             link:link
              slc:slc
               ni:ni
               mp:mp
               si:MTP3_SERVICE_INDICATOR_MGMT
       ackRequest:NULL];
}

- (void)powerOn
{
    NSArray *linkKeys = [_links allKeys];
    for(NSString *key in linkKeys)
    {
        UMMTP3Link *link = _links[key];
        [link powerOn];
    }
}

- (void)powerOff
{
    NSArray *linkKeys = [_links allKeys];
    for(NSString *key in linkKeys)
    {
        UMMTP3Link *link = _links[key];
        [link powerOff];
    }
}

- (UMMTP3Link *)linkForSlc:(int)slc
{
    NSString *linkName = [NSString stringWithFormat:@"%@:%d",_name,slc];
    UMMTP3Link *link = _links[linkName];
    return link;
}

- (void)attachmentConfirmed:(int)slc
{
    UMMTP3Link *link = [self linkForSlc:slc];
    [link attachmentConfirmed];
}

- (void)attachmentFailed:(int)slc reason:(NSString *)r
{
    UMMTP3Link *link = [self linkForSlc:slc];
    [link attachmentFailed:r];
}


- (void)sctpStatusUpdate:(SCTP_Status)status slc:(int)slc
{
    UMMTP3Link *link = [self linkForSlc:slc];
    [link sctpStatusUpdate:status];
    [self updateLinksetStatus];
}

- (void)m2paStatusUpdate:(M2PA_Status)status slc:(int)slc
{
    
    UMMTP3Link *link = [self linkForSlc:slc];
    [link m2paStatusUpdate:status];
    [self updateLinksetStatus];
}

- (void)start:(int)slc
{
    UMMTP3Link *link = [self linkForSlc:slc];
    [link start];
}
- (void)stop:(int)slc
{
    UMMTP3Link *link = [self linkForSlc:slc];
    [link stop];
}


- (void)updateLinksetStatus
{
    int oldActiveLinks;
    int active = 0 ;
    int inactive = 0;
    int ready = 0;

    oldActiveLinks = _activeLinks;

    NSArray *keys = [_links allKeys];
    for (NSString *key in keys)
    {
        UMMTP3Link *link = _links[key];
        switch(link.m2pa_status)
        {
            case M2PA_STATUS_UNUSED:
            case M2PA_STATUS_OFF:
            case M2PA_STATUS_OOS:
            case M2PA_STATUS_INITIAL_ALIGNMENT:
            case M2PA_STATUS_ALIGNED_NOT_READY:
                inactive++;
                break;
            case M2PA_STATUS_ALIGNED_READY:
                ready++;
                break;
            case M2PA_STATUS_IS:
                active++;
                break;
        }
    }
    /* if we now have our first active link, we should send a first TRA */
    if((oldActiveLinks == 0) && (active > 0))
    {
        UMMTP3Label *label = [[UMMTP3Label alloc]init];
        label.opc = self.localPointCode;
        label.dpc = self.adjacentPointCode;
        [self sendTRA:label
                   ni:_networkIndicator
                   mp:0
                  slc:0
                 link:NULL];
    }
    _activeLinks = active;
    _inactiveLinks = inactive;
    _readyLinks = ready;
    if(_activeLinks > 0)
    {
        _mtp3.ready = YES;
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
    [self sendSLTM:label
           pattern:pattern
                ni:_networkIndicator
                mp:0
               slc:link.slc
              link:link];
}

- (void)updateRouteAvailable:(UMMTP3PointCode *)pc mask:(int)mask
{
    [_routingTable updateRouteAvailable:pc mask:mask linksetName:_name];
    [_mtp3 updateRouteAvailable:pc mask:mask linksetName:_name];
}

- (void)updateRouteRestricted:(UMMTP3PointCode *)pc mask:(int)mask
{
    [_routingTable updateRouteRestricted:pc mask:mask linksetName:_name];
    [_mtp3 updateRouteRestricted:pc mask:mask linksetName:_name];
}

- (void)updateRouteUnavailable:(UMMTP3PointCode *)pc mask:(int)mask
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        NSString *s = [NSString stringWithFormat:@"updateRouteUnavailable:%@/%d",pc.stringValue,(pc.maxmask-mask)];
        [self logDebug:s];
    }

    [_routingTable updateRouteUnavailable:pc mask:mask linksetName:_name];
    [_mtp3 updateRouteUnavailable:pc mask:mask linksetName:_name];
}

- (void)advertizePointcodeAvailable:(UMMTP3PointCode *)pc mask:(int)mask
{
    if(mask != 0)
    {
        NSLog(@"We dont support advertizements with mask other than 0");
    }
    UMMTP3Label *label = [[UMMTP3Label alloc]init];
    label.opc = self.localPointCode;
    label.dpc = self.adjacentPointCode;
    [self sendTFA:label destination:pc ni:_networkIndicator mp:0 slc:0 link:NULL];
}

- (void)advertizePointcodeRestricted:(UMMTP3PointCode *)pc mask:(int)mask
{
    if(mask != 0)
    {
        NSLog(@"We dont support advertizements with mask other than 0");
    }
    UMMTP3Label *label = [[UMMTP3Label alloc]init];
    label.opc = self.localPointCode;
    label.dpc = self.adjacentPointCode;
    [self sendTFR:label destination:pc ni:_networkIndicator mp:0 slc:0 link:NULL];
}

- (void)advertizePointcodeUnavailable:(UMMTP3PointCode *)pc mask:(int)mask
{
    if(mask != 0)
    {
        NSLog(@"We dont support advertizements with mask other than 0");
    }
    UMMTP3Label *label = [[UMMTP3Label alloc]init];
    label.opc = self.localPointCode;
    label.dpc = self.adjacentPointCode;
    [self sendTFP:label destination:pc ni:_networkIndicator mp:0 slc:0 link:NULL];
}

@end
