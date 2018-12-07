//
//  UMMTP3Task_m2paDataIndication.m
//  ulibmtp3
//
//  Created by Andreas Fink on 05/12/14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import "UMMTP3Task_m2paDataIndication.h"
#import "UMLayerMTP3.h"
#import "UMMTP3Link.h"

@implementation UMMTP3Task_m2paDataIndication



- (UMMTP3Task_m2paDataIndication *)initWithReceiver:(UMLayerMTP3 *)rx
											 sender:(id)tx
												slc:(int)slc
										   mtp3link:(UMMTP3Link *)m3link
											   data:(NSData *)d
									   priorityByte:(int)prio
{
    self = [super initWithName:[[self class]description]  receiver:rx sender:tx requiresSynchronisation:NO];
    if(self)
    {
        self.name = @"UMMTP3Task_m2paDataIndication";
        _slc = slc;
        _data = d;
		_m3link = m3link;
		_prio = prio;
    }
    return self;
}

- (void)main
{
    UMLayerMTP3 *mtp3 = (UMLayerMTP3 *)receiver;
    [mtp3 _m2paDataIndicationTask:self];
}

@end
