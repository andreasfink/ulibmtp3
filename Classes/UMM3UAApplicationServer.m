//
//  UMM3UALink.m
//  ulibmtp3
//
//  Created by Andreas Fink on 25.11.16.
//  Copyright © 2016 Andreas Fink. All rights reserved.
//

#import "UMM3UAApplicationServer.h"
#import "UMMTP3PointCode.h"
#import "UMMTP3Label.h"
#import "UMMTP3Route.h"
#import "ulibmtp3_version.h"
#import "UMLayerMTP3ApplicationContextProtocol.h"
#import "UMM3UAApplicationServerProcess.h"

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

static const char *m3ua_class_string(uint8_t pclass);
static const char *m3ua_type_string(uint8_t pclass,uint8_t ptype);
static const char *m3ua_param_name(uint16_t param_type);
static const char *get_sctp_status_string(SCTP_Status status);

static const char *m3ua_class_string(uint8_t pclass)
{
    switch(pclass)
    {
        case 0:
            return "MGMT (Management)";
        case 1:
            return "Transfer";
        case 2:
            return "SSNM (SS7 Signalling Network Management)";
        case 3:
            return "ASPSM (ASP State Maintenance)";
        case 4:
            return "ASPTM (ASP Traffic Maintenance)";
        case 9:
            return "RKM (Routing Key Management)";
    }
    return "Reserved";
}

static const char *m3ua_type_string(uint8_t pclass,uint8_t ptype)
{
    uint16_t	classtype;

    classtype = (pclass << 8) | ptype;

    switch(classtype)
    {
        case M3UA_CLASS_TYPE_ERR: /* management */
            return "ERR";
        case M3UA_CLASS_TYPE_NTFY:
            return "NTFY";
        case M3UA_CLASS_TYPE_DATA:
            return "DATA";
        case M3UA_CLASS_TYPE_DUNA:
            return "DUNA";
        case M3UA_CLASS_TYPE_DAVA:
            return "DAVA";
        case M3UA_CLASS_TYPE_DAUD:
            return "DAUD";
        case M3UA_CLASS_TYPE_SCON:
            return "SCON";
        case M3UA_CLASS_TYPE_DUPU:
            return "DUPU";
        case M3UA_CLASS_TYPE_DRST:
            return "DRST";
        case M3UA_CLASS_TYPE_ASPUP:
            return "ASPUP";
        case M3UA_CLASS_TYPE_ASPDN:
            return "ASPDN";
        case M3UA_CLASS_TYPE_BEAT:
            return "BEAT";
        case M3UA_CLASS_TYPE_ASPUP_ACK:
            return "ASPUP_ACK";
        case M3UA_CLASS_TYPE_ASPDN_ACK:
            return "ASPDN_ACK";
        case M3UA_CLASS_TYPE_ASPAC:
            return "ASPA";
        case M3UA_CLASS_TYPE_ASPIA:
            return "ASPIA";
        case M3UA_CLASS_TYPE_ASPAC_ACK:
            return "ASPAC_ACK";
        case M3UA_CLASS_TYPE_ASPIA_ACK:
            return "ASPIA_ACK";
        case M3UA_CLASS_TYPE_REG_REQ:
            return "REG_REQ";
        case M3UA_CLASS_TYPE_REG_RSP:
            return "REG_RSP";
        case M3UA_CLASS_TYPE_DEREG_REQ:
            return "DEREG_REQ";
        case M3UA_CLASS_TYPE_DEREG_RSP:
            return "DEREG_RSP";
    }
    return "Reserved";
}

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

static const char *get_sctp_status_string(SCTP_Status status)
{
    switch(status)
    {
        case SCTP_STATUS_OFF:
            return "SCTP_STATUS_OFF";
        case SCTP_STATUS_OOS:
            return "SCTP_STATUS_OOS";
        case SCTP_STATUS_IS:
            return "SCTP_STATUS_IS";
        case SCTP_STATUS_M_FOOS:
            return "SCTP_STATUS_M_FOOS";
        default:
            return "SCTP_UNKNOWN";
    }
}


@implementation UMM3UAApplicationServer
@synthesize m3ua_status;
@synthesize trafficMode;

- (UMM3UAApplicationServer *)init
{
    self = [super init];
    if(self)
    {
        applicationServerProcesses = [[UMSynchronizedSortedDictionary alloc]init];
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
    UMMTP3PointCode *pc = [[UMMTP3PointCode alloc]initWitPc:int_pc variant:variant];
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
    UMMTP3PointCode *pc = [[UMMTP3PointCode alloc]initWitPc:int_pc variant:variant];
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

    if(logLevel == UMLOG_DEBUG)
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

#pragma unused(network_appearance)
#pragma unused(correlation_id)
#pragma unused(routing_context)

    if(logLevel == UMLOG_DEBUG)
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
    opc =     [[UMMTP3PointCode alloc]initWitPc:opc_int variant:variant];
    i += 4;

    uint32_t dpc_int  = ntohl(*(uint32_t *)&data3[i]);
    i += 4;
    dpc =     [[UMMTP3PointCode alloc]initWitPc:dpc_int variant:variant];

    si	= data3[i++];
    ni	= data3[i++];
    mp	= data3[i++];
    sls = data3[i++];

    if(logLevel == UMLOG_DEBUG)
    {
        NSString *s = [NSString stringWithFormat:@"Originating Pointcode OPC: %@",opc.description];
        [self logDebug:s];
        s = [NSString stringWithFormat:@"Destination Pointcode DPC: %@",dpc.description];
        [self logDebug:s];
    }

    if(logLevel == UMLOG_DEBUG)
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
                if(logLevel == UMLOG_DEBUG)
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
            [self msuIndication2:protocolData label:label si:si ni:ni mp:mp slc:0 link:NULL];
            break;
    }
}


#pragma mark -
#pragma mark Route Management

- (void)routingUpdateRequired
{

}

- (void) routeAllowed:(UMMTP3PointCode *)pc
{

}

-(void)routeProhibited:(UMMTP3PointCode *)pc
{

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
    return name;
}


- (void)powerOn
{
    if(logLevel == UMLOG_DEBUG)
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
    if(logLevel == UMLOG_DEBUG)
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
    applicationServerProcesses[asp.name] = asp;
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
    config[@"dpc"] = [adjacentPointCode stringValue];
    return config;
}

- (void)setConfig:(NSDictionary *)cfg applicationContext:(id<UMLayerMTP3ApplicationContextProtocol>)appContext
{
    variant = UMMTP3Variant_Undefined;
    networkIndicator = -1;
    speed = -1;
    trafficMode = UMM3UATrafficMode_loadshare;

    for(NSString *key in cfg)
    {
        id value = cfg[key];
        if([key isCaseInsensitiveLike:@"name"])
        {
            self.name =  [value stringValue];
        }
        else if([key isCaseInsensitiveLike:@"mtp3"])
        {
            mtp3 = [appContext getMTP3:[value stringValue]];
        }
        else if([key isCaseInsensitiveLike:@"apc"])
        {
            self.adjacentPointCode = [[UMMTP3PointCode alloc]initWithString:value variant:variant];
        }
        else if ([key isCaseInsensitiveLike:@"speed"])
        {
            speed = [value doubleValue];
        }
        else if ([key isCaseInsensitiveLike:@"variant"])
        {
            NSString *s = [value stringValue];
            if([s isCaseInsensitiveLike:@"itu"])
            {
                variant = UMMTP3Variant_ITU;
            }
            else if([s isCaseInsensitiveLike:@"ansi"])
            {
                variant = UMMTP3Variant_ANSI;
            }
            else if([s isCaseInsensitiveLike:@"china"])
            {
                variant = UMMTP3Variant_China;
            }
            else if([s isCaseInsensitiveLike:@"japan"])
            {
                variant = UMMTP3Variant_Japan;
            }
            else
            {
                [self logMajorError:[NSString stringWithFormat:@"Unknown M3UA variant '%@'",s]];
            }
        }
        else if ([key isCaseInsensitiveLike:@"network-indicator"])
        {
            NSString *s = [value stringValue];
            if((  [s isCaseInsensitiveLike:@"international"])
               || ([s isCaseInsensitiveLike:@"int"])
               || ([s isCaseInsensitiveLike:@"0"]))
            {
                networkIndicator = 0;
            }
            else if(([s isCaseInsensitiveLike:@"national"])
                || ([s isCaseInsensitiveLike:@"nat"])
                || ([s isCaseInsensitiveLike:@"2"]))
            {
                networkIndicator = 1;
            }
            else if(([s isCaseInsensitiveLike:@"spare"])
                || ([s isCaseInsensitiveLike:@"international-spare"])
                || ([s isCaseInsensitiveLike:@"int-spare"])
                || ([s isCaseInsensitiveLike:@"1"]))
            {
                networkIndicator = 2;
            }
            else if(([s isCaseInsensitiveLike:@"reserved"])
                || ([s isCaseInsensitiveLike:@"national-reserved"])
                || ([s isCaseInsensitiveLike:@"nat-reserved"])
                || ([s isCaseInsensitiveLike:@"3"]))
            {
                networkIndicator = 3;
            }
            else
            {
                [self logMajorError:[NSString stringWithFormat:@"Unknown M3UA network-indicator '%@' defaulting to international",s]];
                networkIndicator = 0;
            }
        }
        else if([key isCaseInsensitiveLike:@"routing-key"])
        {
            routingKey = [value integerValue];
        }
        else if([key isCaseInsensitiveLike:@"network-appearance"])
        {
            networkAppearance = [value integerValue];
        }
        else if([key isCaseInsensitiveLike:@"traffic-mode"])
        {

            NSString *s = [value stringValue];
            if([s isCaseInsensitiveLike:@"loadshare"])
            {
                trafficMode = UMM3UATrafficMode_loadshare;
            }
            else if([s isCaseInsensitiveLike:@"override"])
            {
                trafficMode = UMM3UATrafficMode_override;
            }
            else if([s isCaseInsensitiveLike:@"broadcast"])
            {
                trafficMode = UMM3UATrafficMode_broadcast;
            }
            else
            {
                [self logMajorError:[NSString stringWithFormat:@"Unknown M3UA traffic-mode '%@'. Defaulting to loadshare",s]];
                trafficMode = UMM3UATrafficMode_loadshare;
            }
        }
    }
    if(localPointCode == NULL)
    {
        localPointCode = mtp3.opc;
    }
    if(variant==UMMTP3Variant_Undefined)
    {
        variant = mtp3.variant;
    }
    if(networkIndicator == -1)
    {
        networkIndicator = mtp3.networkIndicator;
    }
    if(speed < 0.0)
    {
        speed = 100.0;
    }
}

- (void)m3uaCongestion:(UMM3UAApplicationServerProcess *)asp
     affectedPointCode:(UMMTP3PointCode *)pc
                  mask:(uint32_t)mask
     networkAppearance:(uint32_t)network_appearance
    concernedPointcode:(UMMTP3PointCode *)concernedPc
   congestionIndicator:(uint32_t)congestionIndicator
{
    [mtp3 m3uaCongestion:self
       affectedPointCode:pc
                    mask:mask
       networkAppearance:networkAppearance
      concernedPointcode:concernedPc
     congestionIndicator:congestionIndicator];
}
@end
