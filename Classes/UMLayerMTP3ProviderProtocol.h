//
//  UMLayerMTP3ProviderProtocol.h
//  ulibmtp3
//
//  Created by Andreas Fink on 25.11.16.
//  Copyright © 2016 Andreas Fink. All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import <ulib/ulib.h>
#import <ulib/ulib.h>
#import <ulibm2pa/ulibm2pa.h>
#import "UMMTP3Variant.h"


/* defines the methods a MTP3 layer must implement from a MTP3 Users perspective */
/* this is provided by UMLayerMTP3 and by UMLayerM3UA */

@protocol UMLayerMTP3ProviderProtocol<UMLayerUserProtocol>


#pragma mark -
#pragma mark Sending from Layer 3

- (UMMTP3Route *)findRouteForDestination:(UMMTP3PointCode *)dpc;

- (UMMTP3_Error)sendPDU:(NSData *)pdu
                    opc:(UMMTP3PointCode *)fopc
                    dpc:(UMMTP3PointCode *)fdpc
                     si:(int)si
                     mp:(int)mp;

- (UMMTP3_Error)forwardPDU:(NSData *)pdu
                       opc:(UMMTP3PointCode *)fopc
                       dpc:(UMMTP3PointCode *)fdpc
                        si:(int)si
                        mp:(int)mp
                     route:(UMMTP3Route *)route;



#pragma mark -
#pragma mark Config Management

- (void)setConfig:(NSDictionary *)cfg applicationContext:(id)appContext;
- (NSDictionary *)config;
- (void)start;
- (void)stop;
- (void)setUserPart:(int)upid user:(id<UMLayerMTP3UserProtocol>)user;

@end

