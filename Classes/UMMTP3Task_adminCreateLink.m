//
//  UMMTP3Task_adminCreateLink.m
//  ulibmtp3
//
//  Created by Andreas Fink on 09.12.14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import "UMMTP3Task_adminCreateLink.h"
#import "UMLayerMTP3.h"

@implementation UMMTP3Task_adminCreateLink

@synthesize slc;
@synthesize linkset;
@synthesize link;

- (UMMTP3Task_adminCreateLink *)initWithReceiver:(UMLayerMTP3 *)rx
                                           sender:(id)tx
                                              slc:(int)xslc
                                          linkset:(NSString *)xlinkset
                                             link:(NSString *)xlink
{
    self = [super initWithName:[[self class]description]  receiver:rx sender:tx requiresSynchronisation:NO];
    if(self)
    {
        self.slc = xslc;
        self.linkset = xlinkset;
        self.link = xlink;
    }
    return self;
}

- (void)main
{
    @autoreleasepool
    {
        UMLayerMTP3 *mtp3 = (UMLayerMTP3 *)receiver;
        [mtp3 _adminCreateLinkTask:self];
    }
}

@end
