//
//  UMMTP3Task_adminCreateLinkSet.m
//  ulibmtp3
//
//  Created by Andreas Fink on 09.12.14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import "UMMTP3Task_adminCreateLinkSet.h"
#import "UMLayerMTP3.h"
@implementation UMMTP3Task_adminCreateLinkSet


@synthesize linkset;

- (UMMTP3Task_adminCreateLinkSet *)initWithReceiver:(UMLayerMTP3 *)rx
                                          sender:(id)tx
                                         linkset:(NSString *)xlinkset
{
    self = [super initWithName:[[self class]description]  receiver:rx sender:tx requiresSynchronisation:NO];
    if(self)
    {
        self.linkset = xlinkset;
    }
    return self;
}

- (void)main
{
    UMLayerMTP3 *mtp3 = (UMLayerMTP3 *)receiver;
    [mtp3 _adminCreateLinkSetTask:self];
}
@end
