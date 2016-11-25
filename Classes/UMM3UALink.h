//
//  UMM3UALink.h
//  ulibmtp3
//
//  Created by Andreas Fink on 25.11.16.
//  Copyright © 2016 Andreas Fink. All rights reserved.
//

#import <ulib/ulib.h>
#import <ulibsctp/ulibsctp.h>

#import "UMMTP3LinkSet.h"
#import "UMM3UATrafficMode.h"

/* note: a M3UA "link" is the same as in traditional SS7 which is called a linkset */
/* it corresponds to an association of two MTP nodes */
/* while a traditional linkset has multiple physical links separated with SLC's */
/* this is not necessary in M3UA. So think of UMM3UALink as a linkset with */
/* a fixed prebuiltin link */
@interface UMM3UALink : UMMTP3LinkSet
{
    /* config params */
    UMM3UATrafficMode   trafficMode;
    NSInteger			routingKey;
    NSInteger           networkAppearance;

    UMLayerSctp         *sctpLink;
}

- (void)processERR:(NSDictionary *)params;
- (void)processNTFY:(NSDictionary *)params;
- (void)processDATA:(NSDictionary *)params;
- (void)processDUNA:(NSDictionary *)params;
- (void)processDAVA:(NSDictionary *)params;
- (void)processSCON:(NSDictionary *)params;
- (void)processDUPU:(NSDictionary *)params;
- (void)processDRST:(NSDictionary *)params;
- (void)processASPUP:(NSDictionary *)params;
- (void)processASPDN:(NSDictionary *)params;
- (void)processBEAT:(NSDictionary *)params;
- (void)processASPUP_ACK:(NSDictionary *)params;
- (void)processASPDN_ACK:(NSDictionary *)params;
- (void)processASPAC:(NSDictionary *)params;
- (void)processASPIA:(NSDictionary *)params;
- (void)processASPAC_ACK:(NSDictionary *)params;
- (void)processASPIA_ACK:(NSDictionary *)params;
- (void)processREG_REQ:(NSDictionary *)params;
- (void)processREG_RSP:(NSDictionary *)params;
- (void)processDEREG_REQ:(NSDictionary *)params;
- (void)processDEREG_RSP:(NSDictionary *)params;

@end
