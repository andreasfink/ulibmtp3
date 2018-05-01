//
//  UMM3UALink.m
//  ulibmtp3
//
//  Created by Andreas Fink on 25.11.16.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMM3UAApplicationServer.h"
#import "UMMTP3PointCode.h"
#import "UMMTP3Label.h"
#import "UMMTP3Route.h"
#import "ulibmtp3_version.h"
#import "UMLayerMTP3ApplicationContextProtocol.h"
#import "UMM3UAApplicationServerProcess.h"
#import "UMMTP3LinkRoutingTable.h"
#import "UMMTP3HeadingCode.h"

/* for arc4random */
#ifdef __APPLE__
#include <stdlib.h>
#else
#include <bsd/stdlib.h>
#endif


#define	M3UA_CLASS_TYPE_ERR			0x0000
#define M3UA_CLASS_TYPE_NTFY		0x0001
#define	M3UA_CLASS_TYPE_DATA		0x0101
#define M3UA_CLASS_TYPE_DUNA		0x0201
#define M3UA_CLASS_TYPE_DAVA		0x0202
#define M3UA_CLASS_TYPE_DAUD		0x0203
#define M3UA_CLASS_TYPE_SCON		0x0204
#define M3UA_CLASS_TYPE_DUPU		0x0205
#define M3UA_CLASS_TYPE_DRST		0x0206
#define M3UA_CLASS_TYPE_ASPUP		0x0301
#define M3UA_CLASS_TYPE_ASPDN		0x0302
#define M3UA_CLASS_TYPE_BEAT		0x0303
#define M3UA_CLASS_TYPE_ASPUP_ACK	0x0304
#define M3UA_CLASS_TYPE_ASPDN_ACK	0x0305
#define M3UA_CLASS_TYPE_BEAT_ACK	0x0306
#define M3UA_CLASS_TYPE_ASPAC		0x0401
#define M3UA_CLASS_TYPE_ASPIA		0x0402
#define M3UA_CLASS_TYPE_ASPAC_ACK	0x0403
#define M3UA_CLASS_TYPE_ASPIA_ACK	0x0504
#define M3UA_CLASS_TYPE_REG_REQ		0x0901
#define M3UA_CLASS_TYPE_REG_RSP		0x0902
#define M3UA_CLASS_TYPE_DEREG_REQ	0x0903
#define M3UA_CLASS_TYPE_DEREG_RSP	0x0904

#define M3UA_PARAM_INFO_STRING					0x0004
#define M3UA_PARAM_ROUTING_CONTEXT				0x0006
#define M3UA_PARAM_DIAGNOSTIC_INFORMATION		0x0007
#define M3UA_PARAM_HEARTBEAT_DATA				0x0009
#define M3UA_PARAM_TRAFFIC_MODE_TYPE			0x000b
#define M3UA_PARAM_ERROR_CODE					0x000c
#define M3UA_PARAM_STATUS						0x000d
#define M3UA_PARAM_ASP_IDENTIFIER				0x0011
#define M3UA_PARAM_AFFECTED_POINT_CODE			0x0012
#define M3UA_PARAM_CORRELATION_ID				0x0013
#define M3UA_PARAM_NETWORK_APPEARANCE			0x0200
#define M3UA_PARAM_USER_CAUSE					0x0204
#define M3UA_PARAM_CONGESTION_INDICATIONS		0x0205
#define M3UA_PARAM_CONCERNED_DESTINATION		0x0206
#define M3UA_PARAM_ROUTING_KEY					0x0207
#define M3UA_PARAM_REGISTRATION_RESULT			0x0208
#define M3UA_PARAM_DEREGISTRATION_RESULT		0x0209
#define M3UA_PARAM_LOCAL_ROUTING_KEY_IDENTIFIER 0x020a
#define M3UA_PARAM_DESTINATION_POINT_CODE		0x020b
#define M3UA_PARAM_SERVICE_INDICATORS			0x020c
#define M3UA_PARAM_ORIGINATING_POINTCODE_LIST	0x020e
#define M3UA_PARAM_CIRCUIT_RANGE				0x020f
#define M3UA_PARAM_PROTOCOL_DATA				0x0210
#define M3UA_PARAM_REGISTRATION_STATUS			0x0212
#define M3UA_PARAM_DEREGISTRATION_STATUS		0x0213

#define	SCTP_PROTOCOL_IDENTIFIER_M3UA	3

#define SOURCE_POS_DICT @{ @"file": @(__FILE__) , @"line":@(__LINE__) , @"func":@(__func__) }

#import "UMLayerMTP3.h"

static const char *m3ua_param_name(uint16_t param_type);



static const char *m3ua_param_name(uint16_t param_type)
{
    switch(param_type)
    {
        case M3UA_PARAM_INFO_STRING:
            return "INFO_STRING";
        case M3UA_PARAM_ROUTING_CONTEXT:
            return "ROUTING_CONTEXT";
        case M3UA_PARAM_DIAGNOSTIC_INFORMATION:
            return "DIAGNOSTIC_INFORMATION";
        case M3UA_PARAM_HEARTBEAT_DATA:
            return "HEARTBEAT_DATA";
        case M3UA_PARAM_TRAFFIC_MODE_TYPE:
            return "TRAFFIC_MODE_TYPE";
        case M3UA_PARAM_ERROR_CODE:
            return "ERROR_CODE";
        case M3UA_PARAM_STATUS:
            return "STATUS";
        case M3UA_PARAM_ASP_IDENTIFIER:
            return "ASP_IDENTIFIER";
        case M3UA_PARAM_AFFECTED_POINT_CODE:
            return "AFFECTED_POINT_CODE";
        case M3UA_PARAM_CORRELATION_ID:
            return "CORRELATION_ID";
        case M3UA_PARAM_NETWORK_APPEARANCE:
            return "NETWORK_APPEARANCE";
        case M3UA_PARAM_USER_CAUSE:
            return "USER_CAUSE";
        case M3UA_PARAM_CONGESTION_INDICATIONS:
            return "CONGESTION_INDICATIONS";
        case M3UA_PARAM_CONCERNED_DESTINATION:
            return "CONCERNED_DESTINATION";
        case M3UA_PARAM_ROUTING_KEY:
            return "ROUTING_KEY";
        case M3UA_PARAM_REGISTRATION_RESULT:
            return "REGISTRATION_RESULT";
        case M3UA_PARAM_DEREGISTRATION_RESULT:
            return "DEREGISTRATION_RESULT";
        case M3UA_PARAM_LOCAL_ROUTING_KEY_IDENTIFIER:
            return "LOCAL_ROUTING_KEY_IDENTIFIER";
        case M3UA_PARAM_DESTINATION_POINT_CODE:
            return "DESTINATION_POINT_CODE";
        case M3UA_PARAM_SERVICE_INDICATORS:
            return "SERVICE_INDICATORS";
        case M3UA_PARAM_ORIGINATING_POINTCODE_LIST:
            return "ORIGINATING_POINTCODE_LIST";
        case M3UA_PARAM_CIRCUIT_RANGE:
            return "CIRCUIT_RANGE";
        case M3UA_PARAM_PROTOCOL_DATA:
            return "PROTOCOL_DATA";
        case M3UA_PARAM_REGISTRATION_STATUS:
            return "REGISTRATION_STATUS";
        case M3UA_PARAM_DEREGISTRATION_STATUS:
            return "DEREGISTRATION_STATUS";
    }
    return "unknown";
}

@implementation UMM3UAApplicationServer
@synthesize m3ua_status;
@synthesize trafficMode;
@synthesize networkAppearance;
@synthesize routingKey;

- (UMM3UAApplicationServer *)init
{
    self = [super init];
    if(self)
    {
        applicationServerProcesses = [[UMSynchronizedSortedDictionary alloc]init];
        self.logLevel = UMLOG_MAJOR;
        m3ua_status = M3UA_STATUS_OFF;
    }
    return self;
}

- (NSData *)getParam:(UMSynchronizedSortedDictionary *)p identifier:(uint16_t)param_id
{
    return p[ @(param_id)];
}

- (NSString *)paramName:(uint16_t)param_id
{
    return @(m3ua_param_name(param_id));
}

- (void)missingMandatoryParameterError:(uint16_t)param_id
{
    NSString *s = [NSString stringWithFormat:@"Mandatory Parameter missing: 0x%04d %@",param_id, [self paramName:param_id]];
    [self logMajorError:s];
}

- (void)parameterLengthError:(uint16_t)param_id
{
    NSString *s = [NSString stringWithFormat:@"Parameter length error for: 0x%04d %@",param_id, [self paramName:param_id]];
    [self logMajorError:s];
}

- (UMMTP3PointCode *)extractAffectedPointCode:(NSData *)d mask:(int *)mask
{
    NSUInteger len = d.length;
    const uint8_t *bytes = d.bytes;
    if(len != 4)
    {
        [self parameterLengthError:M3UA_PARAM_AFFECTED_POINT_CODE];
        return NULL;
    }

    *mask = bytes[0];
    int int_pc = (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
    UMMTP3PointCode *pc = [[UMMTP3PointCode alloc]initWithPc:int_pc variant:_variant];
    return pc;
}

- (NSArray *)getAffectedPointcodes:(UMSynchronizedSortedDictionary *)params
{
    NSMutableArray *arr = [[NSMutableArray alloc]init];
    NSData *affpc_data = [self getParam:params identifier:M3UA_PARAM_AFFECTED_POINT_CODE];
    if((affpc_data.length  % 4 !=0) && (affpc_data.length == 0))
    {
        [self parameterLengthError:M3UA_PARAM_AFFECTED_POINT_CODE];
        return NULL;
    }
    const uint8_t *bytes = affpc_data.bytes;
    int i = 0;
    while(i < affpc_data.length)
    {
        NSData *d = [NSData dataWithBytes:&bytes[i] length:4];
        [arr addObject:d];
        i = i + 4;
    }
    return arr;
}

- (UMMTP3PointCode *)getConcernedPointcode:(UMSynchronizedSortedDictionary *)params
{
    NSData *affpc_data = [self getParam:params identifier:M3UA_PARAM_AFFECTED_POINT_CODE];
    if(affpc_data.length  != 4)
    {
        [self parameterLengthError:M3UA_PARAM_AFFECTED_POINT_CODE];
        return NULL;
    }
    const uint8_t *bytes = affpc_data.bytes;

    int int_pc = (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
    UMMTP3PointCode *pc = [[UMMTP3PointCode alloc]initWithPc:int_pc variant:_variant];
    return pc;
}


#pragma mark -
#pragma mark Management (MGMT) Messages (See Section 3.8)

- (void)processERR:(UMSynchronizedSortedDictionary *)params
{

}

- (void)processNTFY:(UMSynchronizedSortedDictionary *)params
{

}

#pragma mark -
#pragma mark Transfer Messages (See Section 3.3)

- (void)processDATA:(UMSynchronizedSortedDictionary *)params
{
    NSData *network_appearance;
    NSData *routing_context;
    NSData *correlation_id;
    NSData *protocolData;

    int i;
    int mp;
    int si;
    UMMTP3PointCode *opc;
    UMMTP3PointCode *dpc;
    int sls = -200;
    int 	ni;
    const uint8_t *data3;

    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"process_DATA"];
    }

    protocolData = [self getParam:params identifier:M3UA_PARAM_PROTOCOL_DATA];
    if(!protocolData)
    {
        [self missingMandatoryParameterError:M3UA_PARAM_PROTOCOL_DATA];
        return;
    }

    network_appearance	= [self getParam:params identifier:M3UA_PARAM_NETWORK_APPEARANCE];
    correlation_id		= [self getParam:params identifier:M3UA_PARAM_CORRELATION_ID];
    routing_context		= [self getParam:params identifier:M3UA_PARAM_ROUTING_CONTEXT];

    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"process_DATA"];
        [self logDebug:[NSString stringWithFormat: @" PDU: %@", [protocolData hexString]]];
    }
    if(protocolData.length < 12)
    {
        [self logMajorError:@"Packet too short!"];
        return;
    }

    data3 = protocolData.bytes;
    i = 0;
    /* here M3UA starts */
    uint32_t opc_int = ntohl(*(uint32_t *)&data3[i]);
    opc =     [[UMMTP3PointCode alloc]initWithPc:opc_int variant:_variant];
    i += 4;

    uint32_t dpc_int  = ntohl(*(uint32_t *)&data3[i]);
    i += 4;
    dpc =     [[UMMTP3PointCode alloc]initWithPc:dpc_int variant:_variant];

    si	= data3[i++];
    ni	= data3[i++];
    mp	= data3[i++];
    sls = data3[i++];

    if(self.logLevel <= UMLOG_DEBUG)
    {
        NSString *s = [NSString stringWithFormat:@"Originating Pointcode OPC: %@",opc.description];
        [self logDebug:s];
        s = [NSString stringWithFormat:@"Destination Pointcode DPC: %@",dpc.description];
        [self logDebug:s];
    }

    if(self.logLevel <= UMLOG_DEBUG)
    {
        switch(si)
        {
            case 0x00:
                [self logDebug:@" Service Indicator: [0x00] Signalling network management messages"];
                break;
            case 0x01:
                [self logDebug:@" Service Indicator: [0x01] Signalling network testing and maintenance messages"];
                break;
            case 0x03:
                [self logDebug:@" Service Indicator: [0x03] SCCP"];
                break;
            case 0x04:
                [self logDebug:@" Service Indicator: [0x04] TUP"];
                break;
            case 0x05:
                [self logDebug:@" Service Indicator: [0x05] ISUP"];
                break;
            case 0x06:
                [self logDebug:@" Service Indicator: [0x06] DUP (call/circuit related)"];
                break;
            case 0x07:
                [self logDebug:@" Service Indicator: [0x07] DUP (facility related)"];
                break;
            case 0x08:
                [self logDebug:@" Service Indicator: [0x08] MTP Testing User Part"];
                break;
            case 0x09:
                [self logDebug:@" Service Indicator: [0x09] Broadband ISUP"];
                break;
            case 0x0A:
                [self logDebug:@" Service Indicator: [0x0A] Satellite ISUP"];
                break;
            default:
                [self logDebug:[NSString stringWithFormat:@" Service Indicator: [0x%02x] spare",si]];
                break;
        }

        switch(ni)
        {
            case 0x00:
                [self logDebug:@" Network Indicator: [0] International"];
                break;
            case 0x01:
                [self logDebug:@" Network Indicator: [1] International spare"];
                break;
            case 0x02:
                [self logDebug:@" Network Indicator: [2] National"];
                break;
            case 0x03:
                [self logDebug:@" Network Indicator: [3] National spare"];
                break;
        }

        [self logDebug:[NSString stringWithFormat:@" Message Priority (MP): [%d]",mp]];
        [self logDebug:[NSString stringWithFormat:@" Signalling link Selector (SLS): [%d]",sls]];
    }

    UMMTP3Label *label = [[UMMTP3Label alloc]init];
    label.opc = opc;
    label.dpc = dpc;
    label.sls = sls;

    switch(si)
    {
        case 0x00:
            /* Signalling network management messages */
            //[self processSignallingNetworkManagementMessages];
            break;
        case 0x01:
            /* Signalling network testing and maintenance messages */
            break;
        default:
            [self msuIndication2:protocolData
                           label:label
                              si:si
                              ni:ni
                              mp:mp
                             slc:0
                            link:NULL
               networkAppearance:network_appearance
                   correlationId:correlation_id
                  routingContext:routing_context];
            break;
    }
}

#pragma mark -
#pragma mark Route Management

- (void)aspUp:(UMM3UAApplicationServerProcess *)asp
{
    upCount++;
    [self updateLinksetStatus];

}

- (void)aspDown:(UMM3UAApplicationServerProcess *)asp
{
    upCount--;
    [self updateLinksetStatus];
}

- (void)aspActive:(UMM3UAApplicationServerProcess *)asp
{
    activeCount++;
    [_routingTable updateRouteAvailable:_adjacentPointCode mask:0 linksetName:_name];
    if(trafficMode == UMM3UATrafficMode_override)
    {
        NSArray *keys = [applicationServerProcesses allKeys];
        for(id key in keys)
        {
            UMM3UAApplicationServerProcess *asp2 = applicationServerProcesses[key];
            if(asp2 == asp)
            {
                continue;
            }
            if(asp2.active)
            {
                [asp goInactive];
                break;
            }
        }
    }
    [self updateLinksetStatus];
}

- (void)aspInactive:(UMM3UAApplicationServerProcess *)asp
{
    activeCount--;
    BOOL somethingsActive = NO;
    NSArray *keys = [applicationServerProcesses allKeys];
    for(id key in keys)
    {
        UMM3UAApplicationServerProcess *asp2 = applicationServerProcesses[key];
        if(asp2 == asp)
        {
            continue;
        }
        if(asp2.active)
        {
            somethingsActive = YES;
            break;
        }
    }
    if(somethingsActive == NO)
    {
        [_routingTable updateRouteUnavailable:_adjacentPointCode mask:0 linksetName:_name];
    }
    [self updateLinksetStatus];
}

- (void)updateRouteAvailable:(UMMTP3PointCode *)pc mask:(int)mask forAsp:(UMM3UAApplicationServerProcess *)asp
{
    [_routingTable updateRouteAvailable:pc mask:mask linksetName:_name];
}

-(void)updateRouteUnavailable:(UMMTP3PointCode *)pc mask:(int)mask forAsp:(UMM3UAApplicationServerProcess *)asp
{
    [_routingTable updateRouteUnavailable:pc mask:mask linksetName:_name];
}

-(void)updateRouteRestricted:(UMMTP3PointCode *)pc mask:(int)mask forAsp:(UMM3UAApplicationServerProcess *)asp
{
    [_routingTable updateRouteRestricted:pc mask:mask linksetName:_name];
}

-(UMMTP3RouteStatus)isRouteAvailable:(UMMTP3PointCode *)pc
                                mask:(int)mask
                              forAsp:(UMM3UAApplicationServerProcess *)asp
{
    if(self.localPointCode)
    {
        if(pc.integerValue == self.localPointCode.integerValue)
        {
            return UMMTP3_ROUTE_ALLOWED;
        }
    }
    else
    {
        if(pc.integerValue == self.mtp3.opc.integerValue)
        {
            return UMMTP3_ROUTE_ALLOWED;
        }
    }
    if(_routingTable)
    {
        return [_routingTable isRouteAvailable:pc
                                     mask:mask
                              linksetName:_name];
    }
    return UMMTP3_ROUTE_UNKNOWN;
}

- (void)routeUpdateAll:(UMMTP3RouteStatus)status
{
}

- (void)allRoutesProhibited
{

}


#pragma mark -
#pragma mark SCTP callbacks


- (NSString *)layerName
{
    return _name;
}


- (void)powerOn
{
    m3ua_status = M3UA_STATUS_OOS;
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"start"];
    }
    id keys = [applicationServerProcesses allKeys];
    for(id key in keys)
    {
        UMM3UAApplicationServerProcess *asp = applicationServerProcesses[key];
        [asp start];
    }
}

- (void)powerOff
{
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"stop"];
    }
    id keys = [applicationServerProcesses allKeys];
    for(id key in keys)
    {
        UMM3UAApplicationServerProcess *asp = applicationServerProcesses[key];
        [asp stop];
    }
}

- (void) addAsp:(UMM3UAApplicationServerProcess *)asp
{
    asp.as = self;
    applicationServerProcesses[asp.layerName] = asp;
}

- (void) adminAttachConfirm:(UMLayer *)attachedLayer
                     userId:(id)uid
{

}


- (void) adminAttachFail:(UMLayer *)attachedLayer
                  userId:(id)uid
                  reason:(NSString *)reason
{

}


- (void) adminDetachConfirm:(UMLayer *)attachedLayer
                     userId:(id)uid
{

}


- (void) adminDetachFail:(UMLayer *)attachedLayer
                  userId:(id)uid
                  reason:(NSString *)reason
{

}


- (NSDictionary *)config
{
    NSMutableDictionary *config = [[NSMutableDictionary alloc]init];
    config[@"dpc"] = [_adjacentPointCode stringValue];
    return config;
}

- (void)setConfig:(NSDictionary *)cfg applicationContext:(id<UMLayerMTP3ApplicationContextProtocol>)appContext
{
    _variant = UMMTP3Variant_Undefined;
    _networkIndicator = -1;
    _speed = -1;
    trafficMode = UMM3UATrafficMode_loadshare;
    NSString *apc;
    NSString *opc;
    self.logLevel = UMLOG_MAJOR;


    if(cfg[@"name"])
    {
        self.name =  [cfg[@"name"] stringValue];
    }
    if(cfg[@"log-level"])
    {
        self.logLevel = [cfg[@"log-level"] intValue];
    }
    if(_logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:[NSString stringWithFormat:@"M3UA-AS: setConfig: \n%@",cfg]];
    }
    if(cfg[@"mtp3"])
    {
        NSString *mtp3Name = [cfg[@"mtp3"] stringValue];
        _mtp3 = [appContext getMTP3:mtp3Name];
        if(_mtp3 == NULL)
        {
            [self logMajorError:[NSString stringWithFormat:@"M3UA-ASP: attaching to MTP3 '%@' failed. layer not found",mtp3Name]];
        }
        else
        {
            [_mtp3 addLinkset:self];
        }
    }

    if(cfg[@"apc"])
    {
        apc = [cfg[@"apc"] stringValue];
    }
    if(cfg[@"opc"])
    {
        opc = [cfg[@"opc"] stringValue];
    }

    if (cfg[@"speed"])
    {
        _speed = [cfg[@"speed"] doubleValue];
    }

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

    if (cfg[@"network-indicator"])
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
    if(cfg[@"routing-key"])
    {
        NSString *s = [cfg[@"routing-key"] stringValue];
        if([s isEqualToStringCaseInsensitive:@"none"])
        {
            _useRoutingKey = NO;
        }
        else
        {
            _useRoutingKey = YES;
            routingKey = [s integerValue];
        }
    }

    _useNetworkAppearance = NO;
    if(cfg[@"network-appearance"])
    {
        NSString *s = cfg[@"network-appearance"];
        if([s isEqualToStringCaseInsensitive:@"none"])
        {
            _useNetworkAppearance = NO;
        }
        else
        {
            _useNetworkAppearance = YES;
            networkAppearance = [s integerValue];
        }
    }
    if(cfg[@"traffic-mode"])
    {

        NSString *s = [cfg[@"traffic-mode"] stringValue];
        if([s isEqualToStringCaseInsensitive:@"loadshare"])
        {
            trafficMode = UMM3UATrafficMode_loadshare;
        }
        else if([s isEqualToStringCaseInsensitive:@"override"])
        {
            trafficMode = UMM3UATrafficMode_override;
        }
        else if([s isEqualToStringCaseInsensitive:@"broadcast"])
        {
            trafficMode = UMM3UATrafficMode_broadcast;
        }
        else
        {
            [self logMajorError:[NSString stringWithFormat:@"Unknown M3UA traffic-mode '%@'. Defaulting to loadshare",s]];
            trafficMode = UMM3UATrafficMode_loadshare;
        }
    }
    
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
    if(_speed < 0.0)
    {
        _speed = 100.0;
    }
    self.adjacentPointCode = [[UMMTP3PointCode alloc]initWithString:apc variant:_variant];
}

- (void)m3uaCongestion:(UMM3UAApplicationServerProcess *)asp
     affectedPointCode:(UMMTP3PointCode *)pc
                  mask:(uint32_t)mask
     networkAppearance:(uint32_t)network_appearance
    concernedPointcode:(UMMTP3PointCode *)concernedPc
   congestionIndicator:(uint32_t)congestion_indicator
{
    [_mtp3 m3uaCongestion:self
       affectedPointCode:pc
                    mask:mask
       networkAppearance:network_appearance
      concernedPointcode:concernedPc
     congestionIndicator:congestion_indicator];
}


- (void)protocolViolation
{

}


- (NSArray *)activeApplicationServerProcessesToUse
{
    NSMutableArray *applicableProcesses = [[NSMutableArray alloc]init];

    NSArray *keys = [applicationServerProcesses allKeys];
    for(id key in keys)
    {
        UMM3UAApplicationServerProcess *asp = applicationServerProcesses[key];
        if(asp.active)
        {
            [applicableProcesses addObject:asp];
        }
    }
    if (trafficMode == UMM3UATrafficMode_broadcast)
    {
        /* in broadcast mode, we send to all */
        return applicableProcesses;
    }
    /* in any other mode, we only send to one */
    NSInteger n = [applicableProcesses count];
    if(n<=1)
    {
        return applicableProcesses;
    }
    uint32_t r =[UMUtil random:(uint32_t)n];
    return @[applicableProcesses[r]]; /* we return array including only one of many */
}

- (void)advertizePointcodeAvailable:(UMMTP3PointCode *)pc mask:(int)mask
{
    NSArray *arr = [self activeApplicationServerProcessesToUse];
    for(UMM3UAApplicationServerProcess *asp  in arr)
    {
        [asp advertizePointcodeAvailable:pc mask:mask];
    }
}

- (void)advertizePointcodeRestricted:(UMMTP3PointCode *)pc mask:(int)mask
{
    NSArray *arr = [self activeApplicationServerProcessesToUse];
    for(UMM3UAApplicationServerProcess *asp  in arr)
    {
        [asp advertizePointcodeRestricted:pc mask:mask];
    }
}

- (void)advertizePointcodeUnavailable:(UMMTP3PointCode *)pc mask:(int)mask
{
    NSArray *arr = [self activeApplicationServerProcessesToUse];
    for(UMM3UAApplicationServerProcess *asp  in arr)
    {
        [asp advertizePointcodeUnavailable:pc mask:mask];
    }
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
    NSMutableDictionary *options2=NULL;
    if((self.supportsExtendedAttributes) && (options!=NULL))
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

    NSArray *asps = [self activeApplicationServerProcessesToUse];
    if(asps.count < 1)
    {
        [logFeed majorErrorText:[NSString stringWithFormat:@"Dropping PDU due to no active ASPs present"]];
    }
    else
    {
        for(UMM3UAApplicationServerProcess *asp in asps)
        {
            [asp sendPdu:data
                   label:label
                 heading:heading
                      ni:ni
                      mp:mp
                      si:si
              ackRequest:ackRequest
           correlationId:correlation_id
                 options:options2];
        }
    }
}

- (void)updateLinksetStatus
{
    int active = 0;
    int inactive = 0;
    int ready = 0;
    BOOL activeSeen = NO;;
    BOOL inactiveSeen = NO;
    BOOL busySeen = NO;
    NSArray *keys = [applicationServerProcesses allKeys];
    for (NSString *key in keys)
    {
        UMM3UAApplicationServerProcess *link = applicationServerProcesses[key];
        switch(link.status)
        {
            case M3UA_STATUS_UNUSED:
            case M3UA_STATUS_OFF:
            case M3UA_STATUS_OOS:
                inactive++;
                break;
            case M3UA_STATUS_BUSY:
                busySeen=YES;
                ready++;
                break;
            case M3UA_STATUS_INACTIVE:
                inactiveSeen=YES;
                inactive++;
                break;
            case M3UA_STATUS_IS:
                activeSeen=YES;
                active++;
                break;
        }
    }
    _activeLinks = active;
    _inactiveLinks = inactive;
    _readyLinks = ready;
    _totalLinks = (int)keys.count;
    if(_activeLinks > 0)
    {
        _mtp3.ready = YES;
    }

    if(activeSeen)
    {
        m3ua_status = M3UA_STATUS_IS;
    }
    else if(inactiveSeen)
    {
        m3ua_status = M3UA_STATUS_INACTIVE;
    }
    else if(busySeen)
    {
        m3ua_status = M3UA_STATUS_BUSY;
    }
    else if(_totalLinks > 0)
    {
        m3ua_status = M3UA_STATUS_OOS;
    }
    else
    {
        m3ua_status = M3UA_STATUS_OFF;
    }
}


- (NSString *)statusString
{
    switch(m3ua_status)
    {
        case    M3UA_STATUS_OFF:
            return @"OFF";

        case    M3UA_STATUS_OOS:
            return @"OOS";

        case    M3UA_STATUS_BUSY:
            return @"BUSY";

        case    M3UA_STATUS_INACTIVE:
            return @"INACTIVE";

        case    M3UA_STATUS_IS:
            return @"IS";
        default:
            return @"UNDEFINED";
    }
}
@end
