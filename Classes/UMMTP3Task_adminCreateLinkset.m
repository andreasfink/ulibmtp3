//
//  UMMTP3Task_adminCreateLinkset.m
//  ulibmtp3
//
//  Created by Andreas Fink on 09.12.14.
//  Copyright (c) 2016 Andreas Fink
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import "UMMTP3Task_adminCreateLinkset.h"
#import "UMLayerMTP3.h"
@implementation UMMTP3Task_adminCreateLinkset


@synthesize linkset;

- (UMMTP3Task_adminCreateLinkset *)initWithReceiver:(UMLayerMTP3 *)rx
                                          sender:(id)tx
                                         linkset:(NSString *)xlinkset
{
    self = [super initWithName:[[self class]description]  receiver:rx sender:tx requiresSynchronisation:YES];
    if(self)
    {
        self.linkset = xlinkset;
    }
    return self;
}

- (void)main
{
    UMLayerMTP3 *mtp3 = (UMLayerMTP3 *)receiver;
    [mtp3 _adminCreateLinksetTask:self];
}
@end
