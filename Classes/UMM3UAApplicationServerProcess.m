//
//  UMM3UAApplicationServerProcess.m
//  ulibmtp3
//
//  Created by Andreas Fink on 24.01.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMM3UAApplicationServerProcess.h"
#import "UMM3UAApplicationServer.h"
#import "UMMTP3PointCode.h"
#import "UMMTP3Label.h"
#import "UMMTP3Route.h"
#import "ulibmtp3_version.h"
#import "UMM3UATrafficMode.h"
#import "UMLayerMTP3.h"

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


@implementation UMM3UAApplicationServerProcess

- (BOOL)sctp_connecting
{
    if(_status == M3UA_STATUS_OOS)
    {
        return YES;
    }
    return NO;
}

- (BOOL)sctp_up
{
    switch(_status)
    {
        case M3UA_STATUS_UNUSED:
        case  M3UA_STATUS_OFF:
        case M3UA_STATUS_OOS:
            return NO;
        case M3UA_STATUS_BUSY:
        case M3UA_STATUS_INACTIVE:
        case M3UA_STATUS_IS:
            return YES;
    }
    return NO;
}

- (BOOL)up
{
    switch(_status)
    {
        case M3UA_STATUS_UNUSED:
        case  M3UA_STATUS_OFF:
        case M3UA_STATUS_OOS:
        case M3UA_STATUS_BUSY:
            return NO;
        case M3UA_STATUS_INACTIVE:
        case M3UA_STATUS_IS:
            return YES;
    }
    return NO;
}

- (BOOL)active
{
    switch(_status)
    {
        case M3UA_STATUS_UNUSED:
        case M3UA_STATUS_OFF:
        case M3UA_STATUS_OOS:
        case M3UA_STATUS_BUSY:
        case M3UA_STATUS_INACTIVE:
            return NO;
        case M3UA_STATUS_IS:
            return YES;
    }
    return NO;

}

- (UMM3UAApplicationServerProcess *)init
{
    self = [super init];
    if(self)
    {
        _incomingStream0 = [[NSMutableData alloc]init];
        _incomingStream1 = [[NSMutableData alloc]init];
        _speedometer = [[UMThroughputCounter alloc]initWithResolutionInSeconds: 1.0 maxDuration: 1260.0];
        _submission_speed = [[UMThroughputCounter alloc]initWithResolutionInSeconds: 1.0 maxDuration: 1260.0];
        _speed_within_limit = YES;
        self.logLevel = UMLOG_MAJOR;
        _aspLock = [[UMMutex alloc]initWithName:@"m3ua-asp-lock"];
        _sctp_status = SCTP_STATUS_OFF;
        _status = M3UA_STATUS_OFF;
        _houseKeepingTimer = [[UMTimer alloc]initWithTarget:self
                                                   selector:@selector(housekeeping)
                                                     object:NULL
                                                    seconds:1.1
                                                       name:@"housekeeping"
                                                    repeats:YES];
    }
    return self;
}

- (void)setParam:(UMSynchronizedSortedDictionary *)p identifier:(uint16_t)param_id value:(NSData *)data
{
    p[ @(param_id)] = data;
}

- (NSData *)getParam:(UMSynchronizedSortedDictionary *)p identifier:(uint16_t)param_id
{
    return p[ @(param_id)];
}

- (uint32_t)getIntParam:(UMSynchronizedSortedDictionary *)p identifier:(uint16_t)param_id
{
    NSData *d = p[ @(param_id)];
    const uint8_t *bytes = d.bytes;

    if(d.length == 4)
    {
        uint32_t r = (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
        return r;
    }
    else if(d.length == 2)
    {
        uint32_t r =  (bytes[0] << 8) | bytes[1];
        return r;
    }
    else if(d.length == 1)
    {
        uint32_t r =  bytes[0];
        return r;
    }
    return 0;
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
        *mask = 0;
        return NULL;
    }
    *mask = bytes[0];
    int int_pc = (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
    UMMTP3PointCode *pc = [[UMMTP3PointCode alloc]initWithPc:int_pc variant:_as.variant];
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
    UMMTP3PointCode *pc = [[UMMTP3PointCode alloc]initWithPc:int_pc variant:_as.variant];
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

#pragma unused(network_appearance)
#pragma unused(correlation_id)
#pragma unused(routing_context)

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
    opc =     [[UMMTP3PointCode alloc]initWithPc:opc_int variant:_as.variant];
    i += 4;

    uint32_t dpc_int  = ntohl(*(uint32_t *)&data3[i]);
    i += 4;
    dpc =     [[UMMTP3PointCode alloc]initWithPc:dpc_int variant:_as.variant];

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
    NSData *protocolData2 = [NSData dataWithBytes:&data3[i] length:protocolData.length-i];
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
            [_as msuIndication2:protocolData2
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
#pragma mark SS7 Signalling Network Management (SSNM) Messages (See Section 3.4)


- (void)processDUNA:(UMSynchronizedSortedDictionary *)params
{
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"processDUNA"];
    }

    //  NSData *network_appearance	= [self getParam:params identifier:M3UA_PARAM_NETWORK_APPEARANCE];
    //  NSData *routing_context		= [self getParam:params identifier:M3UA_PARAM_ROUTING_CONTEXT];
    //  NSData *infoString          = [self getParam:params identifier:M3UA_PARAM_INFO_STRING];
    NSArray *affpcs = [self getAffectedPointcodes:params];
    for (NSData *d in affpcs)
    {
        int mask = 0;
        UMMTP3PointCode *pc = [self extractAffectedPointCode:d mask:&mask];
        [_as updateRouteUnavailable:pc mask:mask forAsp:self];
    }
}

- (void)processDAVA:(UMSynchronizedSortedDictionary *)params
{
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"processDAVA"];
    }

    //  NSData *network_appearance	= [self getParam:params identifier:M3UA_PARAM_NETWORK_APPEARANCE];
    //  NSData *routing_context		= [self getParam:params identifier:M3UA_PARAM_ROUTING_CONTEXT];
    //  NSData *infoString          = [self getParam:params identifier:M3UA_PARAM_INFO_STRING];
    NSArray *affpcs = [self getAffectedPointcodes:params];
    for (NSData *d in affpcs)
    {
        int mask = 0;
        UMMTP3PointCode *pc = [self extractAffectedPointCode:d mask:&mask];
        [_as updateRouteAvailable:pc mask:mask forAsp:self];
    }
}


/* audit request */
- (void)processDAUD:(UMSynchronizedSortedDictionary *)params
{
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"processDAUD"];
    }

    //  NSData *network_appearance	= [self getParam:params identifier:M3UA_PARAM_NETWORK_APPEARANCE];
    //  NSData *routing_context		= [self getParam:params identifier:M3UA_PARAM_ROUTING_CONTEXT];
    //  NSData *infoString          = [self getParam:params identifier:M3UA_PARAM_INFO_STRING];
    NSArray *affpcs = [self getAffectedPointcodes:params];
    if(affpcs.count==0)
    {
        [self logDebug:@"processDAUD with no affected pointcodes specified"];
    }
    for (NSData *d in affpcs)
    {

        int mask = 0;
        UMMTP3PointCode *pc = [self extractAffectedPointCode:d mask:&mask];
        [self logDebug:[NSString stringWithFormat:@" affected pointcode %@",pc]];
        if(mask != 0)
        {
            [self.logFeed minorErrorText:@"affected pointcode with a mask > 0 are not supported and ignored"];
        }
        else
        {
            if(pc)
            {
                BOOL answered = NO;

                [self logDebug:[NSString stringWithFormat:@" as.localPointCode: %@",_as.localPointCode]];
                [self logDebug:[NSString stringWithFormat:@" as.mtp3.opc: %@",_as.mtp3.opc]];

                if(_as.localPointCode)
                {
                    if(_as.localPointCode.integerValue == pc.integerValue)
                    {
                        [self advertizePointcodeAvailable:pc mask:0];
                        answered=YES;
                    }
                }
                else if((_as.mtp3.opc) && (!answered))
                {
                    if(_as.mtp3.opc.integerValue == pc.integerValue)
                    {
                        [self advertizePointcodeAvailable:_as.mtp3.opc mask:0];
                        answered=YES;
                    }
                }

                if(answered==NO)
                {
                    UMMTP3RouteStatus rstatus = [_as isRouteAvailable:pc mask:mask forAsp:self];
                    if(rstatus == UMMTP3_ROUTE_ALLOWED)
                    {
                        [self logDebug:@" rstatus=UMMTP3_ROUTE_ALLOWED"];
                        [self advertizePointcodeAvailable:pc mask:mask];

                    }
                    else if(rstatus == UMMTP3_ROUTE_PROHIBITED)
                    {
                        [self logDebug:@" rstatus=UMMTP3_ROUTE_PROHIBITED"];
                        [self advertizePointcodeUnavailable:pc mask:mask];
                    }
                    else if(rstatus == UMMTP3_ROUTE_RESTRICTED)
                    {
                        [self logDebug:@" rstatus=UMMTP3_ROUTE_RESTRICTED"];
                        [self advertizePointcodeRestricted:pc mask:mask];
                    }
                    else if(rstatus == UMMTP3_ROUTE_UNKNOWN)
                    {
                        [self logDebug:[NSString stringWithFormat:@"    status of pointcode %@ is unknown",pc]];
                    }
                }
            }
        }
    }
}

- (void)processSCON:(UMSynchronizedSortedDictionary *)params
{
    /* Signalling Congestion */
    int sls = -200;

    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"processSCON"];
    }

    uint32_t network_appearance	= [self getIntParam:params identifier:M3UA_PARAM_NETWORK_APPEARANCE];
    //  NSData *routing_context		= [self getParam:params identifier:M3UA_PARAM_ROUTING_CONTEXT];
    //  NSData *infoString          = [self getParam:params identifier:M3UA_PARAM_INFO_STRING];
    UMMTP3PointCode *concernedPc = [self getConcernedPointcode:params];
    uint32_t congestionIndicator  = [self getIntParam:params identifier:M3UA_PARAM_CONGESTION_INDICATIONS];

    NSArray *affpcs = [self getAffectedPointcodes:params];

    UMMTP3Label *label = [[UMMTP3Label alloc]init];
    label.opc = _adjacentPointCode;
    label.dpc = _localPointCode;
    label.sls = sls;

    for (NSData *d in affpcs)
    {
        int mask = 14;
        UMMTP3PointCode *aff_pc = [self extractAffectedPointCode:d mask:&mask];
        if(aff_pc)
        {
            [_as m3uaCongestion:self
             affectedPointCode:aff_pc
                          mask:mask
             networkAppearance:network_appearance
            concernedPointcode:concernedPc
           congestionIndicator:congestionIndicator];
        }
    }
}

- (void)processDUPU:(UMSynchronizedSortedDictionary *)params
{
    /* Destination User Part Unavailable */
}

- (void)processDRST:(UMSynchronizedSortedDictionary *)params
{
    int sls = -200;

    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"processDRST"];
    }

    //  NSData *network_appearance	= [self getParam:params identifier:M3UA_PARAM_NETWORK_APPEARANCE];
    //  NSData *routing_context		= [self getParam:params identifier:M3UA_PARAM_ROUTING_CONTEXT];
    //  NSData *infoString          = [self getParam:params identifier:M3UA_PARAM_INFO_STRING];
    NSArray *affpcs = [self getAffectedPointcodes:params];

    UMMTP3Label *label = [[UMMTP3Label alloc]init];
    label.opc = _adjacentPointCode;
    label.dpc = _localPointCode;
    label.sls = sls;

    for (NSData *d in affpcs)
    {
        int mask;
        UMMTP3PointCode *pc = [self extractAffectedPointCode:d mask:&mask];
#pragma unused(pc)
        //[self processTFR:label destination:pc ni:ni mp:mp slc:0 link:NULL mask:mask];
    }
}


#pragma mark -
#pragma mark ASP State Maintenance (ASPSM) Messages (See Section 3.5)

- (void)processASPUP:(UMSynchronizedSortedDictionary *)params
{
    /* ASP Up */
    [self sendASPUP_ACK:NULL];
    self.status = M3UA_STATUS_INACTIVE;
    [_as aspUp:self];
}

- (void)processASPDN:(UMSynchronizedSortedDictionary *)params
{
    /* ASP Down */
    [self sendASPDN_ACK:NULL];
    self.status = M3UA_STATUS_BUSY;
    [_as aspDown:self];
}

- (void)processBEAT:(NSData *)data
{
    self.lastBeatReceived = [NSDate date];

    /* Heartbeat */
    [self sendBEAT_ACK:data];
}

- (void)processBEAT_ACK:(NSData *)data
{
    self.lastBeatAckReceived = [NSDate date];
}

- (void)processASPUP_ACK:(UMSynchronizedSortedDictionary *)params
{
    /* ASP Up acknlowledgment */

    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"processASPUP_ACK"];
    }
    self.status = M3UA_STATUS_INACTIVE;
    _aspup_received = YES;
    if(_standby_mode)
    {
        [self sendASPIA:NULL];
    }
    else
    {
        if(self.logLevel <= UMLOG_DEBUG)
        {
            [self logDebug:@"processASPUP_ACK"];
            [self logDebug:@" status is now BUSY"];
        }
        UMSynchronizedSortedDictionary *pl = [[UMSynchronizedSortedDictionary alloc]init];
        pl[@(M3UA_PARAM_TRAFFIC_MODE_TYPE)] = @(_as.trafficMode);
        [self sendASPAC:pl];
    }
}

- (void)processASPDN_ACK:(UMSynchronizedSortedDictionary *)params
{
    self.status = M3UA_STATUS_BUSY;
    /* ASP Down acknlowledgment */
}

#pragma mark -
#pragma mark ASP Traffic Maintenance (ASPTM) Messages (See Section 3.7)


- (void)processASPAC:(UMSynchronizedSortedDictionary *)params
{
    /* ASP Active*/
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"processASPAC"];
    }

    [_as aspActive:self];
    self.status =  M3UA_STATUS_IS;
    [self sendASPAC_ACK:params];
}

- (void)processASPIA:(UMSynchronizedSortedDictionary *)params
{
    /* ASP Inactive */
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"processASPIA"];
    }

    [_as aspInactive:self];
    self.status =  M3UA_STATUS_INACTIVE;
    [self sendASPIA_ACK:params];
}

- (void)processASPAC_ACK:(UMSynchronizedSortedDictionary *)params
{
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"processASPAC_ACK"];
        [self logDebug:@" status is now IS"];
        [self logDebug:@" stop reopen timer1"];
        [self logDebug:@" stop reopen timer2"];
        [self logDebug:@" start linktest timer"];
    }
    [_reopen_timer1 stop];
    [_reopen_timer2 stop];
    [_linktest_timer stop];
    if(_linktest_timer_value > 0)
    {
        [_linktest_timer start];
    }
    self.status =  M3UA_STATUS_IS;
    [_as aspActive:self];
}

- (void)processASPIA_ACK:(UMSynchronizedSortedDictionary *)params
{
    /* ASP Inactive acknowledgment */
    self.status =  M3UA_STATUS_INACTIVE;
    [_as aspInactive:self];

}

#pragma mark -
#pragma mark Routing Key Management Messages

- (void)processREG_REQ:(UMSynchronizedSortedDictionary *)params
{
    /* Registration Request */
}

- (void)processREG_RSP:(UMSynchronizedSortedDictionary *)params
{
    /* Registration Response */

}

- (void)processDEREG_REQ:(UMSynchronizedSortedDictionary *)params
{
    /* Deregistration Request */
}

- (void)processDEREG_RSP:(UMSynchronizedSortedDictionary *)params
{
    /* Deregistration Response */
}

#pragma mark -
#pragma mark Sending messages


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
                 ni:ni
                 mp:mp
                 si:si
       ackRequest:ackRequest
      correlationId:correlation_id
            options:NULL];
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
    uint8_t header[12];
    uint32_t opc = label.opc.integerValue;
    uint32_t dpc = label.dpc.integerValue;

    header[0] = (opc & 0xFF000000) >> 24;
    header[1] = (opc & 0x00FF0000) >> 16;
    header[2] = (opc & 0x0000FF00) >> 8;
    header[3] = (opc & 0x000000FF) >> 0;
    header[4] = (dpc & 0xFF000000) >> 24;
    header[5] = (dpc & 0x00FF0000) >> 16;
    header[6] = (dpc & 0x0000FF00) >> 8;
    header[7] = (dpc & 0x000000FF) >> 0;
    header[8] = si & 0xFF;
    header[9] = ni & 0xFF;
    header[10] = mp & 0xFF;
    header[11] = label.sls & 0xFF;
    NSMutableData *pdu = [NSMutableData dataWithBytes:header length:12];
    [pdu appendData:data];

    UMSynchronizedSortedDictionary *pl = [[UMSynchronizedSortedDictionary alloc]init];
    if(_as.useNetworkAppearance)
    {
        pl[@(M3UA_PARAM_NETWORK_APPEARANCE)] = @(_as.networkAppearance);
    }
    if(_as.useRoutingKey)
    {
        pl[@(M3UA_PARAM_ROUTING_CONTEXT)] = @(_as.routingKey);
    }
    pl[@(M3UA_PARAM_PROTOCOL_DATA)] = pdu;
    pl[@(M3UA_PARAM_CORRELATION_ID)] = @(correlation_id);
    
    if(logLevel <= UMLOG_DEBUG)
    {
        [self.logFeed debugText:[NSString stringWithFormat:@"sending PDU %@",pdu]];
    }

    if(options)
    {
        if(options[@"info-string"])
        {
            pl[@(M3UA_PARAM_INFO_STRING)] = options[@"info-string"];
        }
    }
    [self sendDATA:pl];
}

-(void)sendPduCT:(int)classType pdu:(NSData *)paramsPdu stream:(int)stream
{
    [self sendPduClass: ((classType >> 8) & 0xFF) type:(classType & 0xFF) pdu:paramsPdu stream:stream];
}

- (NSData *)paramsList:(UMSynchronizedSortedDictionary *)paramsList
{
    NSMutableData *d = [[NSMutableData alloc]init];

    NSArray *keys = [paramsList sortedKeys];
    for(id key in keys)
    {
        int ikey = [key  intValue];
        id value = paramsList[key];
        NSData *data;

        if([value isKindOfClass:[NSData class]])
        {
            data = (NSData *)value;
        }
        else if([value isKindOfClass:[NSString class]])
        {
            data =  [value dataUsingEncoding:NSUTF8StringEncoding];
        }
        else if([value isKindOfClass:[NSNumber class]])
        {
            uint32_t t = htonl([value intValue]);
            data = [[NSData alloc]initWithBytes:&t length:4];
        }
        else
        {
            @throw([NSException exceptionWithName:@"UNKNOWN_DATATYPE"
                                           reason:@"parameter of unknonw type to be encoded for M3UA parameters"
                                         userInfo:@{ @"location" :SOURCE_POS_DICT} ]);
        }
        [d appendByte:((ikey >> 8) & 0xFF)];
        [d appendByte:((ikey >> 0) & 0xFF)];

        NSUInteger len = data.length + 4;
        [d appendByte:((len >> 8) & 0xFF)];
        [d appendByte:((len >> 0) & 0xFF)];
        [d appendData:data];
        switch(len % 4) /* padding to 4 byte boundary */
        {
            case 3:
                [d appendByte:0x00];
                break;
            case 2:
                [d appendByte:0x00];
                [d appendByte:0x00];
                break;
            case 1:
                [d appendByte:0x00];
                [d appendByte:0x00];
                [d appendByte:0x00];
                break;
            case 0:
                break;
        }
    }
    return d;
}

- (void)sendPduClass:(uint8_t) pclass type:(uint8_t)ptype pdu:(NSData *)pdu stream:(int)streamId
{
    NSUInteger packlen = pdu.length + 8;
    NSMutableData *data = [[NSMutableData alloc]init];
    [data appendByte:0x01]; /* version 1 */
    [data appendByte:0x00];
    [data appendByte:pclass];
    [data appendByte:ptype];
    [data appendByte:((packlen & 0xFF000000) >> 24)];
    [data appendByte:((packlen & 0x00FF0000) >> 16)];
    [data appendByte:((packlen & 0x0000FF00) >> 8)];
    [data appendByte:((packlen & 0x000000FF) >> 0)];
    [data appendData:pdu];

    [_sctpLink dataFor:self
                  data:data
              streamId:streamId
            protocolId:SCTP_PROTOCOL_IDENTIFIER_M3UA
            ackRequest:NULL];
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"SEND_PDU:"];
        [self logDebug:[[NSString alloc]initWithFormat:@" class: %d",(int)pclass]];
        [self logDebug:[[NSString alloc]initWithFormat:@" type: %d",(int)ptype]];
        [self logDebug:[[NSString alloc]initWithFormat:@" pdu: %@",[pdu hexString]]];
        [self logDebug:[[NSString alloc]initWithFormat:@" stream: %d",streamId ]];

    }
}

-(void)sendASPUP:(UMSynchronizedSortedDictionary *)params
{
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"sendASPUP"];
    }
    NSData *paramsPdu = [self paramsList:params];
    [self sendPduCT:M3UA_CLASS_TYPE_ASPUP pdu:paramsPdu stream:0];
}

-(void)sendASPUP_ACK:(UMSynchronizedSortedDictionary *)params
{
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"sendASPUP_ACK"];
    }
    NSData *paramsPdu = [self paramsList:params];
    [self sendPduCT:M3UA_CLASS_TYPE_ASPUP_ACK pdu:paramsPdu stream:0];
}

-(void)sendASPIA:(UMSynchronizedSortedDictionary *)params
{
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"sendASPIA"];
    }
    NSData *paramsPdu = [self paramsList:params];
    [self sendPduCT:M3UA_CLASS_TYPE_ASPIA pdu:paramsPdu stream:0];
}

-(void)sendASPAC:(UMSynchronizedSortedDictionary *)params
{
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"sendASPAC"];
    }
    NSData *paramsPdu = [self paramsList:params];
    [self sendPduCT:M3UA_CLASS_TYPE_ASPAC pdu:paramsPdu stream:0];
}

-(void)sendASPAC_ACK:(UMSynchronizedSortedDictionary *)params
{
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"sendASPAC_ACK"];
    }
    NSData *paramsPdu = [self paramsList:params];
    [self sendPduCT:M3UA_CLASS_TYPE_ASPAC_ACK pdu:paramsPdu stream:0];
}

-(void)sendASPIA_ACK:(UMSynchronizedSortedDictionary *)params
{
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"sendASPIA_ACK"];
    }
    NSData *paramsPdu = [self paramsList:params];
    [self sendPduCT:M3UA_CLASS_TYPE_ASPIA_ACK pdu:paramsPdu stream:0];
}

-(void)sendASPDN:(UMSynchronizedSortedDictionary *)params
{
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"sendASPDN"];
    }
    NSData *paramsPdu = [self paramsList:params];
    [self sendPduCT:M3UA_CLASS_TYPE_ASPDN pdu:paramsPdu stream:0];
}

-(void)sendASPDN_ACK:(UMSynchronizedSortedDictionary *)params
{
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"sendASPDN_ACK"];
    }
    NSData *paramsPdu = [self paramsList:params];
    [self sendPduCT:M3UA_CLASS_TYPE_ASPDN_ACK pdu:paramsPdu stream:0];
}


-(void)sendDAUD:(UMSynchronizedSortedDictionary *)params
{
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"sendDAUD"];
    }
    NSData *paramsPdu = [self paramsList:params];
    [self sendPduCT:M3UA_CLASS_TYPE_DAUD pdu:paramsPdu stream:0];
}


-(void)sendDAVA:(UMSynchronizedSortedDictionary *)params
{
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"sendDAVA"];
    }
    NSData *paramsPdu = [self paramsList:params];
    [self sendPduCT:M3UA_CLASS_TYPE_DAVA pdu:paramsPdu stream:0];
}

-(void)sendDUNA:(UMSynchronizedSortedDictionary *)params
{
    if(logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"sendDUNA"];
    }
    NSData *paramsPdu = [self paramsList:params];
    [self sendPduCT:M3UA_CLASS_TYPE_DUNA pdu:paramsPdu stream:0];
}

-(void)sendDATA:(UMSynchronizedSortedDictionary *)params
{
    if(logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"sendDATA"];
    }
    NSData *paramsPdu = [self paramsList:params];
    [self sendPduCT:M3UA_CLASS_TYPE_DATA pdu:paramsPdu stream:1];
}

-(void)sendBEAT:(NSData *)data
{
    self.lastBeatSent = [NSDate date];
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"sendBEAT"];
    }
    [self sendPduCT:M3UA_CLASS_TYPE_BEAT pdu:data stream:0];
}

-(void)sendBEAT_ACK:(NSData *)data
{
    self.lastBeatAckSent = [NSDate date];
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"sendBEAT_ACK"];
    }
    [self sendPduCT:M3UA_CLASS_TYPE_BEAT_ACK pdu:data stream:0];
}


/////////////////////////////



#pragma mark -
#pragma mark SCTP callbacks


- (NSString *)name
{
    return self.layerName;
}

- (void)setName:(NSString *)name
{
    self.layerName = name;
}

- (void) sctpStatusIndication:(UMLayer *)caller
                       userId:(id)uid
                       status:(SCTP_Status)new_status
{
    SCTP_Status	old_status;
    old_status = _sctp_status;
    if(self.logLevel <= UMLOG_DEBUG)
    {
        NSString *s = [NSString stringWithFormat:@"sctpStatusIndication: %s->%s",
                       get_sctp_status_string(old_status),
                       get_sctp_status_string(new_status) ];
        [self logDebug:s];
    }
    if(old_status == new_status)
    {
        return;
    }
    _sctp_status = new_status;
    switch(_sctp_status)
    {
        case SCTP_STATUS_M_FOOS:
        case SCTP_STATUS_OFF:
        case SCTP_STATUS_OOS:
            [self sctpReportsDown];
            break;
        case SCTP_STATUS_IS:
            [self sctpReportsUp];
            break;
    }
}

- (void)start
{
    [_sctpLink openFor:self];
    /* as we are in point to multipoint mode, we can just send (we dont call connectx anymore) so if we initiate the connection we need to send data to establish it */
    
    NSString *infoString = [NSString stringWithFormat: @"ulibmtp3 %s",ULIBMTP3_VERSION];
    UMSynchronizedSortedDictionary *pl = [[UMSynchronizedSortedDictionary alloc]init];
    pl[@(M3UA_PARAM_INFO_STRING)] = infoString;
    _aspup_received=0;


    if(_beatTime >= 1.0)
    {
        if(_beatTimer==NULL)
        {
            _beatTimer = [[UMTimer alloc]initWithTarget:self
                                               selector:@selector(housekeeping)
                                                 object:NULL
                                                seconds:_beatTime
                                                   name:@"beat-timer"
                                                repeats:YES];
        }
        else
        {
            _beatTimer.seconds = _beatTime;
        }
        [_beatTimer stop];
        [_beatTimer start];
    }
    [self sendASPUP:pl];
}

- (void)stop
{
    [_sctpLink closeFor:self];
}



- (void)powerOn
{
    [_aspLock lock];
    @try
    {
        if(self.logLevel <= UMLOG_DEBUG)
        {
            [self logDebug:@"powerOn"];
        }
        if(self.active)
        {
            [self logMinorError:@" already active"];
            if(![_reopen_timer2 isRunning])
            {
                [self logDebug:@" starting reopen timer 2 which was not running"];
                [_reopen_timer2 start];
            }
            if(![_linktest_timer isRunning])
            {
                if((_linktest_timer_value > 0) && (_linktest_timer))
                {
                    [self logDebug:@" starting linktest_timer which was not running"];
                    [_linktest_timer start];
                }
            }
            return;
        }
        if(self.logLevel <= UMLOG_DEBUG)
        {
            [self logDebug:@" setting status OOS"];
            [self logDebug:@" sending ASPUP"];
        }

        if(_aspup_received==0)
        {
            NSString *infoString = [NSString stringWithFormat: @"ulibmtp3 %s",ULIBMTP3_VERSION];
            UMSynchronizedSortedDictionary *pl = [[UMSynchronizedSortedDictionary alloc]init];
            pl[@(M3UA_PARAM_INFO_STRING)] = infoString;
            [self sendASPUP:pl];
        }
        self.status = M3UA_STATUS_BUSY;
        [_speedometer clear];
        [_submission_speed clear];
        _speed_within_limit = YES;

        sltm_serial = 0;
        [self logDebug:@" starting reopen timer 2"];
        [_reopen_timer2 start];
        if((_linktest_timer_value > 0) && (_linktest_timer))
        {
            [self logDebug:@" starting linktest_timer"];
            [_linktest_timer stop];
            [_linktest_timer start];
        }
    }
    @finally
    {
        [_aspLock unlock];
    }
}

- (void)powerOff
{
    [_aspLock lock];
    @try
    {
        [_beatTimer stop];
        if(self.logLevel <= UMLOG_DEBUG)
        {
            [self logDebug:@"powerOff"];
        }

        if(self.active)
        {
            [self sendASPIA:NULL];
            self.status=M3UA_STATUS_INACTIVE; /* we dont await ASPIA_ACK */
        }
        if(self.up)
        {
            [self sendASPDN:NULL];
            self.status = M3UA_STATUS_BUSY;
            [_speedometer clear];
            [_submission_speed clear];
            _speed_within_limit = YES;
            [_reopen_timer1 stop];
            [_reopen_timer1 start];
            [_sctpLink closeFor:self];
        }
    }
    @finally
    {
        [_aspLock unlock];
    }
}

- (void)lookForIncomingPdu:(int)streamId
{
    const unsigned char *data;
    uint32_t	len;
    uint8_t		pversion;
    uint8_t		pclass;
    uint8_t		ptype;
    uint32_t	packlen;

    NSMutableData *incomingStream;
    if(streamId == 0)
    {
        incomingStream = _incomingStream0;
    }
    else
    {
        incomingStream = _incomingStream1;
    }

    len = (uint32_t)incomingStream.length;
    while(len >= 8)
    {
        data = incomingStream.bytes;

        pversion = data[0];
        pclass	= data[2];
        ptype	= data[3];
        packlen = ntohl(*(uint32_t *)&data[4]);
        if(packlen <= len)
        {
            if(self.logLevel <= UMLOG_DEBUG)
            {
                [self logDebug:@"M3UA Packet:"];
                [self logDebug:[NSString stringWithFormat:@" Version: %d",(int)pversion]];
                [self logDebug:[NSString stringWithFormat:@" Class: %d (%s)", (int)pclass,m3ua_class_string(pclass)]];
                [self logDebug:[NSString stringWithFormat:@" Type: %d (%s)",  (int)ptype, m3ua_type_string(pclass,ptype)]];
            }
            const uint8_t *d = (const uint8_t *)incomingStream.bytes;
            NSData *pdu = [NSData dataWithBytes:&d[8] length:packlen-8];

            [self processPdu:pversion class:pclass type:ptype pdu:pdu];
            [incomingStream replaceBytesInRange:NSMakeRange(0,packlen)
                                      withBytes:NULL
                                         length:0];
            len = len - packlen;
        }
    }
}


- (void) processPdu:(int)version
              class:(int)pclass
               type:(int)ptype pdu:(NSData *)pdu
{
    int		pos = 0;
    uint16_t	param_len;	/* effective */
    uint16_t	param_len2;	/* padded, rounded to the next 4 byte boundary */
    uint16_t	classtype;

    classtype = (pclass << 8) | ptype;

    if(classtype == M3UA_CLASS_TYPE_BEAT)
    {
        [self processBEAT:pdu];
        return;
    }
    else if(classtype == M3UA_CLASS_TYPE_BEAT_ACK)
    {
        [self processBEAT_ACK:pdu];
        return;
    }

    pos=0;
    UMSynchronizedSortedDictionary	*params = [[UMSynchronizedSortedDictionary alloc]init];
    NSUInteger len = pdu.length;
    const uint8_t *bytes = pdu.bytes;

    while((pos+4)<len)
    {
        uint16_t param_type= ntohs(*(uint16_t *)&bytes[pos]);
        param_len = (bytes[pos+2] << 8) | bytes[pos+3];
        if((param_len % 4)==0)
        {
            param_len2 = param_len;
        }
        else
        {
            param_len2 = (param_len+3) & ~0x03;
        }
        if(param_len<=0)
        {
            [self logDebug:@" Parameter length is negative or zero"];
            return;
        }
        NSData *data = [NSData dataWithBytes:&bytes[pos+4] length:(param_len-4)];
        pos += param_len2;

        if(logLevel <= UMLOG_DEBUG)
        {
            [self logDebug:@"M3UA Packet:"];
            [self logDebug:[NSString stringWithFormat:@"  Parameter: 0x%04x (%s)",param_type,m3ua_param_name(param_type)]];
            [self logDebug:[NSString stringWithFormat:@"  Data: %@",[data hexString]]];
        }
        params[@(param_type)]=data;
    }

    switch(classtype)
    {
        case M3UA_CLASS_TYPE_ERR: /* management */
            [self processERR:params];
            break;
        case M3UA_CLASS_TYPE_NTFY:
            [self processNTFY:params];
            break;
        case M3UA_CLASS_TYPE_DATA:
            [self processDATA:params];
            break;
        case M3UA_CLASS_TYPE_DUNA:
            [self processDUNA:params];
            break;
        case M3UA_CLASS_TYPE_DAVA:
            [self processDAVA:params];
            break;
        case M3UA_CLASS_TYPE_DAUD:
            [self processDAUD:params];
            break;
        case M3UA_CLASS_TYPE_SCON:
            [self processSCON:params];
            break;
        case M3UA_CLASS_TYPE_DUPU:
            [self processDUPU:params];
            break;
        case M3UA_CLASS_TYPE_DRST:
            [self processDRST:params];
            break;
        case M3UA_CLASS_TYPE_ASPUP:
            [self processASPUP:params];
            break;
        case M3UA_CLASS_TYPE_ASPDN:
            [self processASPDN:params];
            break;
        case M3UA_CLASS_TYPE_ASPUP_ACK:
            [self processASPUP_ACK:params];
            break;
        case M3UA_CLASS_TYPE_ASPDN_ACK:
            [self processASPDN_ACK:params];
            break;
        case M3UA_CLASS_TYPE_ASPAC:
            [self processASPAC:params];
            break;
        case M3UA_CLASS_TYPE_ASPIA:
            [self processASPIA:params];
            break;
        case M3UA_CLASS_TYPE_ASPAC_ACK:
            [self processASPAC_ACK:params];
            break;
        case M3UA_CLASS_TYPE_ASPIA_ACK:
            [self processASPIA_ACK:params];
            break;
        case M3UA_CLASS_TYPE_REG_REQ:
            [self processREG_REQ:params];
            break;
        case M3UA_CLASS_TYPE_REG_RSP:
            [self processREG_RSP:params];
            break;
        case M3UA_CLASS_TYPE_DEREG_REQ:
            [self processDEREG_REQ:params];
            break;
        case M3UA_CLASS_TYPE_DEREG_RSP:
            [self processDEREG_RSP:params];
            break;
    }
}


- (void) sctpDataIndication:(UMLayer *)caller
                     userId:(id)uid
                   streamId:(uint16_t)streamID
                 protocolId:(uint32_t)pid
                       data:(NSData *)data
{
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"sctpDataIndication"];
        [self logDebug:[NSString stringWithFormat:@" rx-streamid: %d",streamID]];
        [self logDebug:[NSString stringWithFormat:@" rx-data: %@",[data hexString]]];
    }
    if(streamID == 0)
    {
        if(_incomingStream0 == NULL)
        {
            _incomingStream0 = [[NSMutableData alloc]init];
        }
        [_incomingStream0 appendData:data];
    }
    else
    {
        if(_incomingStream1 == NULL)
        {
            _incomingStream1 = [[NSMutableData alloc]init];
        }
        [_incomingStream1 appendData:data];
    }
    [self lookForIncomingPdu:streamID];
}

- (void) sctpMonitorIndication:(UMLayer *)caller
                        userId:(id)uid
                      streamId:(uint16_t)sid
                    protocolId:(uint32_t)pid
                          data:(NSData *)d
                      incoming:(BOOL)in
{

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


- (void)sentAckConfirmFrom:(UMLayer *)sender
                  userInfo:(NSDictionary *)userInfo
{

}


- (void)sentAckFailureFrom:(UMLayer *)sender
                  userInfo:(NSDictionary *)userInfo
                     error:(NSString *)err
                    reason:(NSString *)reason
                 errorInfo:(NSDictionary *)ei
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
    _reopen_timer1_value  = M3UA_DEFAULT_REOPEN1_TIMER;
    _reopen_timer2_value  = M3UA_DEFAULT_REOPEN2_TIMER;
    _linktest_timer_value = M3UA_DEFAULT_LINKTEST_TIMER;
    _speed = M3UA_DEFAULT_SPEED;

    logLevel = UMLOG_MAJOR;

    if(cfg[@"beat-time"])
    {
        self.beatTime = [cfg[@"beat-time"] doubleValue];
    }
    else
    {
        self.beatTime = M3UA_DEFAULT_BEAT_TIMER;
    }
    if(cfg[@"beat-max-outstanding"])
    {
        self.beatMaxOutstanding = [cfg[@"beat-max-outstanding"] intValue];
    }
    else
    {
        self.beatMaxOutstanding = M3UA_DEFAULT_MAX_BEAT_OUTSTANDING;
    }

    if(cfg[@"name"])
    {
        self.layerName =  [cfg[@"name"] stringValue];
    }
    if(cfg[@"log-level"])
    {
        logLevel = [cfg[@"log-level"] intValue];
    }

    if(logLevel <=UMLOG_DEBUG)
    {
        [self logDebug:[NSString stringWithFormat:@"M3UA-ASP: setConfig: \n%@",cfg]];
    }

    if(cfg[@"attach-to"])
    {
        NSString *attachTo =  [cfg[@"attach-to"] stringValue];
        _sctpLink = [appContext getSCTP:attachTo];
        if(_sctpLink==NULL)
        {
            [self logMajorError:[NSString stringWithFormat:@"M3UA-ASP: attaching to SCTP '%@' failed. layer not found",attachTo]];
        }
    }
    if(cfg[@"m3ua-as"])
    {
        NSString *as_name =  [cfg[@"m3ua-as"] stringValue];
        _as = [appContext getM3UAAS:as_name];
        if(_as==NULL)
        {
            [self logMajorError:[NSString stringWithFormat:@"M3UA-ASP: attaching to M3UA-AS '%@' failed. layer not found",as_name]];
        }
        [_as addAsp:self];
    }
    if (cfg[@"speed"])
    {
        _speed = [cfg[@"speed"] doubleValue];
    }
    if (cfg[@"reopen-timer1"])
    {
        _reopen_timer1_value = [cfg[@"reopen-timer1"] doubleValue];
    }
    if (cfg[@"reopen-timer2"])
    {
        _reopen_timer2_value = [cfg[@"reopen-timer2"] doubleValue];
    }
    if (cfg[@"linktest-timer"])
    {
        _linktest_timer_value = [cfg[@"linktest-timer"] doubleValue];
    }

    _reopen_timer1 = [[UMTimer alloc]initWithTarget:self
                                          selector:@selector(reopen_timer1_fires:)
                                             object:NULL
                                            seconds:_reopen_timer1_value
                                               name:@"umm3ua_asp_reopen_timer1"
                                            repeats:NO];

    _reopen_timer2 = [[UMTimer alloc]initWithTarget:self
                                           selector:@selector(reopen_timer2_fires:)
                                             object:NULL
                                            seconds:_reopen_timer2_value
                                               name:@"umm3ua_asp_reopen_timer2"
                                            repeats:NO];

    if(_linktest_timer_value>0.00)
    {
        if(_linktest_timer==NULL)
        {
            _linktest_timer = [[UMTimer alloc]initWithTarget:self
                                                    selector:@selector(linktest_timer_fires:)
                                                      object:NULL
                                                     seconds:_linktest_timer_value
                                                        name:@"umm3ua_asp_linktest_timer"
                                                     repeats:NO];
        }
        else
        {
            _linktest_timer.seconds = _linktest_timer_value;
        }
    }


    if(_beatTime >= 1.0)
    {
        if(_beatTimer==NULL)
        {
            _beatTimer = [[UMTimer alloc]initWithTarget:self
                                               selector:@selector(housekeeping)
                                                 object:NULL
                                                seconds:_beatTime
                                                   name:@"beat-timer"
                                                repeats:YES];
        }
        else
        {
            _beatTimer.seconds = _beatTime;
        }
    }
    UMLayerSctpUserProfile *profile = [[UMLayerSctpUserProfile alloc]init];
    profile.statusUpdates = YES;
    [_sctpLink adminAttachFor:self
                     profile:profile
                      userId:self.layerName];
}

- (void)reopen_timer1_fires:(id)param
{
    [_aspLock lock];
    @try
    {
        if(self.logLevel <= UMLOG_DEBUG)
        {
            [self logDebug:@"reopen_timer1_fires"];
        }
        switch(self.status)
        {
            case M3UA_STATUS_OOS:
                if(self.logLevel <= UMLOG_DEBUG)
                {
                    [self logDebug:@"OOS state. Ignoring Timer Event"];
                }
                [_reopen_timer1 stop];
                [_linktest_timer stop];
                break;
            case M3UA_STATUS_BUSY:
                if(self.logLevel <= UMLOG_DEBUG)
                {
                    [self logDebug:@"BUSY state. Ignoring Timer Event"];
                }
                [_reopen_timer1 stop];
                [_linktest_timer stop];
                break;
            case M3UA_STATUS_INACTIVE:
                if(self.logLevel <= UMLOG_DEBUG)
                {
                    [self logDebug:@"INACTIVE state. Ignoring Timer Event"];
                }
                [_reopen_timer1 stop];
                [_reopen_timer2 stop];
                [_linktest_timer stop];
                break;

            case M3UA_STATUS_IS:
                if(self.logLevel <= UMLOG_DEBUG)
                {
                    [self logDebug:@"IS state. Ignoring Timer Event"];
                }
                [_reopen_timer1 stop];
                [_reopen_timer2 stop];
                [_linktest_timer stop];
                break;
            case M3UA_STATUS_OFF:
            case M3UA_STATUS_UNUSED:
            default:
                if(self.logLevel <= UMLOG_DEBUG)
                {
                    [self logDebug:@"OFF state. Asking SCTP to power on the link"];
                }
                [_reopen_timer1 stop];
                [_reopen_timer2 stop];
                [_linktest_timer stop];
                [_sctpLink openFor:self];
                [_reopen_timer2 start];
                break;
        }
    }
    @finally
    {
        [_aspLock unlock];
    }
}


- (void)reopen_timer2_fires:(id)param
{
    [_aspLock lock];
    @try
    {
        if(self.logLevel <= UMLOG_DEBUG)
        {
            [self logDebug:@"reopen_timer1_fires"];
        }
        switch(self.status)
        {
            case M3UA_STATUS_UNUSED:
                if(self.logLevel <= UMLOG_DEBUG)
                {
                    [self logDebug:@"M3UA_STATUS_UNUSED state. Ignoring timer event"];
                }
                [_reopen_timer1 stop];
                [_reopen_timer2 stop];
                [_linktest_timer stop];
                break;
            case M3UA_STATUS_OFF:
            case M3UA_STATUS_OOS:
            case M3UA_STATUS_BUSY:
                /* reopen timer 1 has expired and the sctp link has been asked to power on
                 after that reopen timer 2 has excpired. So if its still not in "on" state
                 we have to restart from scratch */
                if(self.logLevel <= UMLOG_DEBUG)
                {
                    [self logDebug:@"Status is OFF/OOS or BUSY but still not in service state. Asking SCTP to power off/on the link"];
                }
                [_sctpLink closeFor:self];
                self.status = M3UA_STATUS_OFF;
                [_reopen_timer1 stop];
                [_reopen_timer2 stop];
                [_reopen_timer1 start];
                break;
            case M3UA_STATUS_INACTIVE:
                if(self.logLevel <= UMLOG_DEBUG)
                {
                    [self logDebug:@"Status M3UA_STATUS_INACTIVE. Stopping timers"];
                }
                [_reopen_timer1 stop];
                [_reopen_timer2 stop];
                break;
            case M3UA_STATUS_IS:
                if(self.logLevel <= UMLOG_DEBUG)
                {
                    [self logDebug:@"Status M3UA_STATUS_IS. Stopping timers"];
                }
                [_reopen_timer1 stop];
                [_reopen_timer2 stop];
                break;
        }
    }
    @finally
    {
        [_aspLock unlock];
    }
}


- (void)linktest_timer_fires:(id)param
{
    [_aspLock lock];
    @try
    {
        /* if status is out of service, we restart the link */

        if(self.logLevel <= UMLOG_DEBUG)
        {
            [self logDebug:@"linktest_timer_fires"];
        }

        if(_aspup_received==1)
        {
            /* Lets send ASPAC or ASPIA */
            if(_standby_mode==1)
            {
                [self sendASPIA:NULL];
            }
            else
            {
                UMSynchronizedSortedDictionary *pl = [[UMSynchronizedSortedDictionary alloc]init];
                pl[@(M3UA_PARAM_TRAFFIC_MODE_TYPE)] = @(_as.trafficMode);
                [self sendASPAC:pl];
            }
        }
        if(_linktest_timer_value > 0)
        {
            if(self.logLevel <= UMLOG_DEBUG)
            {
                [self logDebug:@"restarting linktest timers"];
            }
            [_linktest_timer start];
        }
    }
    @finally
    {
        [_aspLock unlock];
    }
}

- (void)sctpReportsUp
{
    /***************************************************************************
     **
     ** called upon SCTP reporting a association to be up
     */

    [self logInfo:@"sctpReportsUp"];
    [self powerOn];
}

- (void)sctpReportsDown
{
    [self logInfo:@"sctpReportsDown"];
    if(self.status != M3UA_STATUS_OFF)
    {
        self.status = M3UA_STATUS_OFF;
        if([_reopen_timer1 isRunning]==NO)
        {
            [_sctpLink closeFor:self];
            [_reopen_timer1 stop];
            [_reopen_timer2 stop];
            [_reopen_timer1 start];
        }
    }
}

- (NSData *)affectedPointcode:(UMMTP3PointCode *)pc mask:(int)mask
{
    uint8_t bytes[4];

    bytes[0] = mask & 0xFF;
    bytes[1] = (pc.pc >> 16) & 0xFF;
    bytes[2] = (pc.pc >> 8) & 0xFF;
    bytes[3] = (pc.pc >> 0) & 0xFF;
    return [NSData dataWithBytes:&bytes length:4];
}

- (void)advertizePointcodeAvailable:(UMMTP3PointCode *)pc mask:(int)mask
{
    UMSynchronizedSortedDictionary *pl = [[UMSynchronizedSortedDictionary alloc]init];
    [self setParam:pl identifier:M3UA_PARAM_AFFECTED_POINT_CODE value:[self affectedPointcode:pc mask:mask]];
    [self sendDAVA:pl];
}

- (void)advertizePointcodeRestricted:(UMMTP3PointCode *)pc mask:(int)mask
{
    UMSynchronizedSortedDictionary *pl = [[UMSynchronizedSortedDictionary alloc]init];
    [self setParam:pl identifier:M3UA_PARAM_AFFECTED_POINT_CODE value:[self affectedPointcode:pc mask:mask]];
    [self sendDUNA:pl];
}

- (void)advertizePointcodeUnavailable:(UMMTP3PointCode *)pc mask:(int)mask
{
    UMSynchronizedSortedDictionary *pl = [[UMSynchronizedSortedDictionary alloc]init];
    [self setParam:pl identifier:M3UA_PARAM_AFFECTED_POINT_CODE value:[self affectedPointcode:pc mask:mask]];
    [self sendDUNA:pl];
}

- (void)goInactive
{
    if(self.active==YES)
    {
        [self sendASPIA:NULL];
    }
    self.status =  M3UA_STATUS_INACTIVE;
}

- (void)goActive
{
    if(self.active==NO)
    {
        [self sendASPAC:NULL];
    }

}

- (NSString *)statusString
{
    switch(_status)
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

- (void)beatTimerEvent
{
    NSString *str = [[NSDate date]stringValue];
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    [self sendBEAT:data];
}

- (void)housekeeping
{
    if([_beatTimer isRunning])
    {
        if(_lastBeatSent)
        {
            NSTimeInterval diff = [[NSDate date]timeIntervalSinceDate:_lastBeatReceived];
            if(diff > (_beatMaxOutstanding * _beatTime))
            {
                [self logMinorError:@"powering off due to missing beat-ack messages"];
                [self powerOff];
            }
        }
    }
}

@end
