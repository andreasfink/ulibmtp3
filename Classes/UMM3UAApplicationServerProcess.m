//
//  UMM3UAApplicationServerProcess.m
//  ulibmtp3
//
//  Created by Andreas Fink on 24.01.17.
//  Copyright © 2017 Andreas Fink. All rights reserved.
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
@synthesize as;
@synthesize name;
@synthesize m3ua_status;

- (UMM3UAApplicationServerProcess *)init
{
    self = [super init];
    if(self)
    {
        incomingStream0 = [[NSMutableData alloc]init];
        incomingStream1 = [[NSMutableData alloc]init];
        speedometer = [[UMThroughputCounter alloc]init];
        submission_speed = [[UMThroughputCounter alloc]init];
        speed_within_limit = YES;
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
            [as msuIndication2:protocolData label:label si:si ni:ni mp:mp slc:0 link:NULL];
            break;
    }
}

#pragma mark -
#pragma mark SS7 Signalling Network Management (SSNM) Messages (See Section 3.4)


- (void)processDUNA:(UMSynchronizedSortedDictionary *)params
{
    int mp;
    int sls = -200;
    int 	ni;
    if(logLevel == UMLOG_DEBUG)
    {
        [self logDebug:@"processDUNA"];
    }

    //  NSData *network_appearance	= [self getParam:params identifier:M3UA_PARAM_NETWORK_APPEARANCE];
    //  NSData *routing_context		= [self getParam:params identifier:M3UA_PARAM_ROUTING_CONTEXT];
    //  NSData *infoString          = [self getParam:params identifier:M3UA_PARAM_INFO_STRING];
    NSArray *affpcs = [self getAffectedPointcodes:params];

    UMMTP3Label *label = [[UMMTP3Label alloc]init];
    label.opc = adjacentPointCode;
    label.dpc = localPointCode;
    label.sls = sls;

    for (NSData *d in affpcs)
    {
        int mask;
        UMMTP3PointCode *pc = [self extractAffectedPointCode:d mask:&mask];
        [as processTFP:label destination:pc ni:ni mp:mp slc:0 link:NULL mask:mask];
    }
}

- (void)processDAVA:(UMSynchronizedSortedDictionary *)params
{
    int mp;
    int sls = -200;
    int 	ni;

    if(logLevel == UMLOG_DEBUG)
    {
        [self logDebug:@"processDAVA"];
    }

    //  NSData *network_appearance	= [self getParam:params identifier:M3UA_PARAM_NETWORK_APPEARANCE];
    //  NSData *routing_context		= [self getParam:params identifier:M3UA_PARAM_ROUTING_CONTEXT];
    //  NSData *infoString          = [self getParam:params identifier:M3UA_PARAM_INFO_STRING];
    NSArray *affpcs = [self getAffectedPointcodes:params];

    UMMTP3Label *label = [[UMMTP3Label alloc]init];
    label.opc = adjacentPointCode;
    label.dpc = localPointCode;
    label.sls = sls;

    for (NSData *d in affpcs)
    {
        int mask;
        UMMTP3PointCode *pc = [self extractAffectedPointCode:d mask:&mask];
        [as processTFA:label destination:pc ni:ni mp:mp slc:0 link:NULL mask:mask];
    }
}

- (void)processDAUD:(UMSynchronizedSortedDictionary *)params
{
    int sls = -200;

    if(logLevel == UMLOG_DEBUG)
    {
        [self logDebug:@"processDAUD"];
    }

    //  NSData *network_appearance	= [self getParam:params identifier:M3UA_PARAM_NETWORK_APPEARANCE];
    //  NSData *routing_context		= [self getParam:params identifier:M3UA_PARAM_ROUTING_CONTEXT];
    //  NSData *infoString          = [self getParam:params identifier:M3UA_PARAM_INFO_STRING];
    NSArray *affpcs = [self getAffectedPointcodes:params];

    UMMTP3Label *label = [[UMMTP3Label alloc]init];
    label.opc = adjacentPointCode;
    label.dpc = localPointCode;
    label.sls = sls;

    for (NSData *d in affpcs)
    {
        int mask;
        UMMTP3PointCode *pc = [self extractAffectedPointCode:d mask:&mask];
#pragma unused(pc)
        /* FIXME: what to do here?
         [self processTFP:label destination:pc ni:ni mp:mp slc:0 link:NULL mask:mask];
         */
    }
}

- (void)processSCON:(UMSynchronizedSortedDictionary *)params
{
    /* Signalling Congestion */
    int sls = -200;

    if(logLevel == UMLOG_DEBUG)
    {
        [self logDebug:@"processSCON"];
    }

    NSData *network_appearance	= [self getParam:params identifier:M3UA_PARAM_NETWORK_APPEARANCE];
    //  NSData *routing_context		= [self getParam:params identifier:M3UA_PARAM_ROUTING_CONTEXT];
    //  NSData *infoString          = [self getParam:params identifier:M3UA_PARAM_INFO_STRING];
    UMMTP3PointCode *concernedPc = [self getConcernedPointcode:params];
    NSData *congestionIndicator  = [self getParam:params identifier:M3UA_PARAM_CONGESTION_INDICATIONS];

    NSArray *affpcs = [self getAffectedPointcodes:params];

    UMMTP3Label *label = [[UMMTP3Label alloc]init];
    label.opc = adjacentPointCode;
    label.dpc = localPointCode;
    label.sls = sls;

    for (NSData *d in affpcs)
    {
        int mask;
        UMMTP3PointCode *pc = [self extractAffectedPointCode:d mask:&mask];
        [as m3uaCongestion:self
         affectedPointCode:pc
                      mask:mask
         networkAppearance:network_appearance
        concernedPointcode:concernedPc
       congestionIndicator:congestionIndicator];
    }
}

- (void)processDUPU:(UMSynchronizedSortedDictionary *)params
{
    /* Destination User Part Unavailable */
}

- (void)processDRST:(UMSynchronizedSortedDictionary *)params
{
    int sls = -200;

    if(logLevel == UMLOG_DEBUG)
    {
        [self logDebug:@"processDRST"];
    }

    //  NSData *network_appearance	= [self getParam:params identifier:M3UA_PARAM_NETWORK_APPEARANCE];
    //  NSData *routing_context		= [self getParam:params identifier:M3UA_PARAM_ROUTING_CONTEXT];
    //  NSData *infoString          = [self getParam:params identifier:M3UA_PARAM_INFO_STRING];
    NSArray *affpcs = [self getAffectedPointcodes:params];

    UMMTP3Label *label = [[UMMTP3Label alloc]init];
    label.opc = adjacentPointCode;
    label.dpc = localPointCode;
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
    [self routingUpdateRequired];
}

- (void)processASPDN:(UMSynchronizedSortedDictionary *)params
{
    /* ASP Down */
    [self allRoutesProhibited];
    [self sendASPDN_ACK:NULL];
    [self routingUpdateRequired];

}

- (void)processBEAT:(NSData *)data
{
    /* Heartbeat */
    [self sendBEAT_ACK:data];
}

- (void)processASPUP_ACK:(UMSynchronizedSortedDictionary *)params
{
    /* ASP Up acknlowledgment */

e    if(logLevel == UMLOG_DEBUG)
    {
        [self logDebug:@"processASPUP_ACK"];
        [self logDebug:@" status is now BUSY"];
    }
    self.m3ua_status = M3UA_STATUS_BUSY;
    aspup_received = YES;
    if(standby_mode)
    {
        [self sendASPIA:NULL];
    }
    else
    {
        if(logLevel == UMLOG_DEBUG)
        {
            [self logDebug:@"processASPUP_ACK"];
            [self logDebug:@" status is now BUSY"];
        }
        UMSynchronizedSortedDictionary *pl = [[UMSynchronizedSortedDictionary alloc]init];
        pl[@(M3UA_PARAM_TRAFFIC_MODE_TYPE)] = @(as.trafficMode);
        [self sendASPAC:pl];
    }
}

- (void)processASPDN_ACK:(UMSynchronizedSortedDictionary *)params
{
    /* ASP Down acknlowledgment */
    [self routingUpdateRequired];
}

#pragma mark -
#pragma mark ASP Traffic Maintenance (ASPTM) Messages (See Section 3.7)


- (void)processASPAC:(UMSynchronizedSortedDictionary *)params
{
    /* ASP Active*/
    if(logLevel == UMLOG_DEBUG)
    {
        [self logDebug:@"processASPAC"];
    }

    [self routeAllowed:adjacentPointCode];
    [self sendASPAC_ACK:params];
}

- (void)processASPIA:(UMSynchronizedSortedDictionary *)params
{
    /* ASP Inactive */
    if(logLevel == UMLOG_DEBUG)
    {
        [self logDebug:@"processASPIA"];
    }

    [self routeProhibited:adjacentPointCode];
    self.m3ua_status = M3UA_STATUS_OOS;
    [sctpLink powerdown];
    [self routingUpdateRequired];
}

- (void)processASPAC_ACK:(UMSynchronizedSortedDictionary *)params
{
    if(logLevel == UMLOG_DEBUG)
    {
        [self logDebug:@"processASPAC_ACK"];
        [self logDebug:@" status is now IS"];
        [self logDebug:@" stop reopen timer1"];
        [self logDebug:@" stop reopen timer2"];
        [self logDebug:@" start linktest timer"];
    }
    [reopen_timer1 stop];
    [reopen_timer2 stop];
    [linktest_timer stop];
    if(linktest_timer_value > 0)
    {
        [linktest_timer start];
    }
    if(M3UA_STATUS_IS != self.m3ua_status)
    {
        [self routeUpdateAll:UMMTP3_ROUTE_ALLOWED];
    }
    self.m3ua_status = M3UA_STATUS_IS;
    [self routingUpdateRequired];
}

- (void)processASPIA_ACK:(UMSynchronizedSortedDictionary *)params
{
    /* ASP Inactive acknowledgment */
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
            case 2:
                [d appendByte:0x00];
            case 1:
                [d appendByte:0x00];
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

    [sctpLink dataFor:self
                 data:data
             streamId:streamId
           protocolId:SCTP_PROTOCOL_IDENTIFIER_M3UA
           ackRequest:NULL];
    if(logLevel == UMLOG_DEBUG)
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
    if(logLevel == UMLOG_DEBUG)
    {
        [self logDebug:@"sendASPUP"];
    }
    NSData *paramsPdu = [self paramsList:params];
    [self sendPduCT:M3UA_CLASS_TYPE_ASPUP pdu:paramsPdu stream:0];
}

-(void)sendASPUP_ACK:(UMSynchronizedSortedDictionary *)params
{
    if(logLevel == UMLOG_DEBUG)
    {
        [self logDebug:@"sendASPUP_ACK"];
    }
    NSData *paramsPdu = [self paramsList:params];
    [self sendPduCT:M3UA_CLASS_TYPE_ASPUP_ACK pdu:paramsPdu stream:0];
}

-(void)sendASPIA:(UMSynchronizedSortedDictionary *)params
{
    if(logLevel == UMLOG_DEBUG)
    {
        [self logDebug:@"sendASPIA"];
    }
    NSData *paramsPdu = [self paramsList:params];
    [self sendPduCT:M3UA_CLASS_TYPE_ASPIA pdu:paramsPdu stream:0];
}

-(void)sendASPAC:(UMSynchronizedSortedDictionary *)params
{
    if(logLevel == UMLOG_DEBUG)
    {
        [self logDebug:@"sendASPAC"];
    }
    NSData *paramsPdu = [self paramsList:params];
    [self sendPduCT:M3UA_CLASS_TYPE_ASPAC pdu:paramsPdu stream:0];
}

-(void)sendASPAC_ACK:(UMSynchronizedSortedDictionary *)params
{
    if(logLevel == UMLOG_DEBUG)
    {
        [self logDebug:@"sendASPAC_ACK"];
    }
    NSData *paramsPdu = [self paramsList:params];
    [self sendPduCT:M3UA_CLASS_TYPE_ASPAC_ACK pdu:paramsPdu stream:0];
}


-(void)sendASPDN:(UMSynchronizedSortedDictionary *)params
{
    if(logLevel == UMLOG_DEBUG)
    {
        [self logDebug:@"sendASPDN"];
    }
    NSData *paramsPdu = [self paramsList:params];
    [self sendPduCT:M3UA_CLASS_TYPE_ASPDN pdu:paramsPdu stream:0];
}

-(void)sendASPDN_ACK:(UMSynchronizedSortedDictionary *)params
{
    if(logLevel == UMLOG_DEBUG)
    {
        [self logDebug:@"sendASPDN_ACK"];
    }
    NSData *paramsPdu = [self paramsList:params];
    [self sendPduCT:M3UA_CLASS_TYPE_ASPDN_ACK pdu:paramsPdu stream:0];
}


-(void)sendDAUD:(UMSynchronizedSortedDictionary *)params
{
    if(logLevel == UMLOG_DEBUG)
    {
        [self logDebug:@"sendDAUD"];
    }
    NSData *paramsPdu = [self paramsList:params];
    [self sendPduCT:M3UA_CLASS_TYPE_DAUD pdu:paramsPdu stream:0];
}


-(void)sendDAVA:(UMSynchronizedSortedDictionary *)params
{
    if(logLevel == UMLOG_DEBUG)
    {
        [self logDebug:@"sendDAUD"];
    }
    NSData *paramsPdu = [self paramsList:params];
    [self sendPduCT:M3UA_CLASS_TYPE_DAVA pdu:paramsPdu stream:0];
}

-(void)sendDATA:(UMSynchronizedSortedDictionary *)params
{
    if(logLevel == UMLOG_DEBUG)
    {
        [self logDebug:@"sendDATA"];
    }
    NSData *paramsPdu = [self paramsList:params];
    [self sendPduCT:M3UA_CLASS_TYPE_DATA pdu:paramsPdu stream:1];
}


-(void)sendBEAT:(NSData *)data
{
    if(logLevel == UMLOG_DEBUG)
    {
        [self logDebug:@"sendBEAT"];
    }
    [self sendPduCT:M3UA_CLASS_TYPE_BEAT pdu:data stream:0];
}

-(void)sendBEAT_ACK:(NSData *)data
{
    if(logLevel == UMLOG_DEBUG)
    {
        [self logDebug:@"sendBEAT_ACK"];
    }
    [self sendPduCT:M3UA_CLASS_TYPE_BEAT_ACK pdu:data stream:0];
}


/////////////////////////////


#pragma mark -
#pragma mark Internal messages

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

- (void) sctpStatusIndication:(UMLayer *)caller
                       userId:(id)uid
                       status:(SCTP_Status)new_status
{
    SCTP_Status	old_status;
    old_status = sctp_status;
    if(logLevel == UMLOG_DEBUG)
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
    sctp_status = new_status;
    switch(sctp_status)
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
    [sctpLink openFor:self];
}

- (void)stop
{
    [sctpLink closeFor:self];
}



- (void)powerOn
{
    @synchronized(self)
    {
        if(logLevel == UMLOG_DEBUG)
        {
            [self logDebug:@"powerOn"];
        }
        if(M3UA_STATUS_IS == self.m3ua_status)
        {
            [self logMinorError:@" already in service"];
            if(![reopen_timer2 isRunning])
            {
                [self logDebug:@" starting reopen timer 2 which was not running"];
                [reopen_timer2 start];
            }
            if(![linktest_timer isRunning])
            {
                if(linktest_timer_value > 0)
                {
                    [self logDebug:@" starting linktest_timer which was not running"];
                    [linktest_timer start];
                }
            }
            return;
        }
        [self routeProhibited:adjacentPointCode];
        if(logLevel == UMLOG_DEBUG)
        {
            [self logDebug:@" setting status OOS"];
            [self logDebug:@" sending ASPUP"];
        }

        NSString *infoString = [NSString stringWithFormat: @"ulibmtp3 %s",ULIBMTP3_VERSION];
        UMSynchronizedSortedDictionary *pl = [[UMSynchronizedSortedDictionary alloc]init];
        pl[@(M3UA_PARAM_INFO_STRING)] = infoString;

        aspup_received=0;
        [self sendASPUP:pl];
        self.m3ua_status = M3UA_STATUS_OOS;
        sltm_serial = 0;
        [self logDebug:@" starting reopen timer 2"];
        [reopen_timer2 start];
        if(linktest_timer_value > 0)
        {
            [self logDebug:@" starting linktest_timer"];
            [linktest_timer stop];
            [linktest_timer start];
        }
    }
}

- (void)powerOff
{
    @synchronized (self)
    {
        if(logLevel == UMLOG_DEBUG)
        {
            [self logDebug:@"powerOff"];
        }

        UMM3UA_Status old_status  = self.m3ua_status;
        self.m3ua_status = M3UA_STATUS_OFF;
        [reopen_timer1 stop];
        [reopen_timer1 start];

        if(M3UA_STATUS_OFF != old_status)
        {
            [sctpLink closeFor:self];
        }
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
        incomingStream = incomingStream0;
    }
    else
    {
        incomingStream = incomingStream1;

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
            if(logLevel == UMLOG_DEBUG)
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

        if(logLevel == UMLOG_DEBUG)
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
    if(logLevel == UMLOG_DEBUG)
    {
        [self logDebug:@"sctpDataIndication"];
        [self logDebug:[NSString stringWithFormat:@" rx-streamid: %d",streamID]];
        [self logDebug:[NSString stringWithFormat:@" rx-data: %@",[data hexString]]];
    }
    if(streamID == 0)
    {
        if(incomingStream0 == NULL)
        {
            incomingStream0 = [[NSMutableData alloc]init];
        }
        [incomingStream0 appendData:data];
    }
    else
    {
        if(incomingStream1 == NULL)
        {
            incomingStream1 = [[NSMutableData alloc]init];
        }
        [incomingStream1 appendData:data];
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
    config[@"dpc"] = [adjacentPointCode stringValue];
    return config;
}


- (void)setConfig:(NSDictionary *)cfg applicationContext:(id<UMLayerMTP3ApplicationContextProtocol>)appContext
{

    reopen_timer1_value  = M3UA_DEFAULT_REOPEN1_TIMER;
    reopen_timer2_value  = M3UA_DEFAULT_REOPEN2_TIMER;
    linktest_timer_value = M3UA_DEFAULT_LINKTEST_TIMER;
    speed = M3UA_DEFAULT_SPEED;
    name = NULL;
    variant = UMMTP3Variant_Undefined;


    for(NSString *key in cfg)
    {
        id value = cfg[key];
        if([key isCaseInsensitiveLike:@"name"])
        {
            name =  [value stringValue];
        }
        else if([key isCaseInsensitiveLike:@"attach-to"])
        {
            NSString *attachTo =  [value stringValue];
            sctpLink = [appContext getSCTP:attachTo];
        }
        else if([key isCaseInsensitiveLike:@"m3ua-as"])
        {
            NSString *as_name =  [value stringValue];
            as = [appContext getM3UA_AS:as_name];
        }
        else if ([key isCaseInsensitiveLike:@"speed"])
        {
            speed = [value doubleValue];
        }
        else if ([key isCaseInsensitiveLike:@"reopen-timer1"])
        {
            reopen_timer1_value = [value doubleValue];
        }
        else if ([key isCaseInsensitiveLike:@"reopen-timer2"])
        {
            reopen_timer2_value = [value doubleValue];
        }
        else if ([key isCaseInsensitiveLike:@"linktest-timer"])
        {
            linktest_timer_value = [value doubleValue];
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
    }
    reopen_timer1 = [[UMTimer alloc]initWithTarget:self
                                          selector:@selector(reopen_timer1_fires:)];
    reopen_timer2 = [[UMTimer alloc]initWithTarget:self
                                          selector:@selector(reopen_timer2_fires:)];
    if(linktest_timer_value>0)
    {
        linktest_timer = [[UMTimer alloc]initWithTarget:self
                                               selector:@selector(linktest_timer_fires:)];
    }


    UMLayerSctpUserProfile *profile = [[UMLayerSctpUserProfile alloc]init];
    profile.statusUpdates = YES;
    [sctpLink adminAttachFor:self
                     profile:profile
                      userId:name];
}

- (void)reopen_timer1_fires:(id)param
{
    @synchronized(self)
    {
        if(logLevel == UMLOG_DEBUG)
        {
            [self logDebug:@"reopen_timer1_fires"];
        }
        switch(self.m3ua_status)
        {
            case M3UA_STATUS_UNUSED:
                if(logLevel == UMLOG_DEBUG)
                {
                    [self logDebug:@"M3UA_STATUS_UNUSED state. Ignoring timer event"];
                }
                [reopen_timer1 stop];
                [reopen_timer2 stop];
                [linktest_timer stop];
                break;
            case M3UA_STATUS_OFF:
                if(logLevel == UMLOG_DEBUG)
                {
                    [self logDebug:@"M3UA_STATUS_OFF state. Asking SCTP to power on the link"];
                }
                [reopen_timer1 stop];
                [reopen_timer2 stop];
                [linktest_timer stop];
                [sctpLink openFor:self];
                [reopen_timer2 start];
                break;
            case M3UA_STATUS_OOS:
                if(logLevel == UMLOG_DEBUG)
                {
                    [self logDebug:@"M3UA_STATUS_OOS state. Ignoring Timer Event"];
                }
                [reopen_timer1 stop];
                break;
            case M3UA_STATUS_BUSY:
                if(logLevel == UMLOG_DEBUG)
                {
                    [self logDebug:@"M3UA_STATUS_BUSY state. Ignoring Timer Event"];
                }
                [reopen_timer1 stop];
                break;
            case M3UA_STATUS_IS:
                if(logLevel == UMLOG_DEBUG)
                {
                    [self logDebug:@"M3UA_STATUS_IS state. Ignoring Timer Event"];
                }
                [reopen_timer1 stop];
                [reopen_timer2 stop];
                break;
        }
    }
}


- (void)reopen_timer2_fires:(id)param
{
    @synchronized(self)
    {

        if(logLevel == UMLOG_DEBUG)
        {
            [self logDebug:@"reopen_timer1_fires"];
        }
        switch(self.m3ua_status)
        {
            case M3UA_STATUS_UNUSED:
                if(logLevel == UMLOG_DEBUG)
                {
                    [self logDebug:@"M3UA_STATUS_UNUSED state. Ignoring timer event"];
                }
                [reopen_timer1 stop];
                [reopen_timer2 stop];
                [linktest_timer stop];
                break;
            case M3UA_STATUS_OFF:
            case M3UA_STATUS_OOS:
            case M3UA_STATUS_BUSY:
                /* reopen timer 1 has expired and the sctp link has been asked to power on
                 after that reopen timer 2 has excpired. So if its still not in "on" state
                 we have to restart from scratch */
                if(logLevel == UMLOG_DEBUG)
                {
                    [self logDebug:@"SCTP is not in SCTP_STATUS_IS state. Asking SCTP to power off/on the link"];
                }
                [sctpLink closeFor:self];
                [reopen_timer1 stop];
                [reopen_timer2 stop];
                [reopen_timer1 start];
                break;
            case M3UA_STATUS_IS:
                if(logLevel == UMLOG_DEBUG)
                {
                    [self logDebug:@"SCTP has status IS. Stopping timers"];
                }
                [reopen_timer1 stop];
                [reopen_timer2 stop];
                break;
        }
    }
}


- (void)linktest_timer_fires:(id)param
{
    @synchronized(self)
    {

        if(logLevel == UMLOG_DEBUG)
        {
            [self logDebug:@"linktest_timer_fires"];
        }

        uint32_t traffic_mode_type = htonl(traffic_mode_type);

        if(aspup_received==1)
        {
            /* Lets send ASPAC or ASPIA */
            if(standby_mode==1)
            {
                [self sendASPIA:NULL];
            }
            else
            {
                UMSynchronizedSortedDictionary *pl = [[UMSynchronizedSortedDictionary alloc]init];
                pl[@(M3UA_PARAM_TRAFFIC_MODE_TYPE)] = @(traffic_mode_type);
                [self sendASPAC:pl];
            }
        }
        if(linktest_timer_value > 0)
        {
            if(logLevel == UMLOG_DEBUG)
            {
                [self logDebug:@"restarting linktest timers"];
            }
            [linktest_timer start];
        }
    }
}

- (void)sctpReportsUp
{
    /***************************************************************************
     **
     ** called upon SCTP reporting a association to be up
     */

    @synchronized(self)
    {
        [self logInfo:@"sctpReportsUp"];
        [self powerOn];
        self.m3ua_status = M3UA_STATUS_OOS;
        [speedometer clear];
        [submission_speed clear];
        speed_within_limit = YES;
    }
}

- (void)sctpReportsDown
{
    [self logInfo:@"sctpReportsDown"];
    self.m3ua_status = M3UA_STATUS_OFF;

}

@end
