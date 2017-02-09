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

@implementation UMMTP3Task_m2paDataIndication

@synthesize slc;
@synthesize userId;
@synthesize data;


- (UMMTP3Task_m2paDataIndication *)initWithReceiver:(UMLayerMTP3 *)rx
                                               sender:(id)tx
                                                  slc:(int)xslc
                                               userId:(id)uid
                                               data:(NSData *)d;
{
    self = [super initWithName:[[self class]description]  receiver:rx sender:tx requiresSynchronisation:NO];
    if(self)
    {
        self.name = @"UMMTP3Task_m2paDataIndication";
        self.slc = xslc;
        self.userId = uid;
        self.data = d;
    }
    return self;
}

- (void)main
{
    UMLayerMTP3 *mtp3 = (UMLayerMTP3 *)receiver;
    [mtp3 _m2paDataIndicationTask:self];
}

@end
