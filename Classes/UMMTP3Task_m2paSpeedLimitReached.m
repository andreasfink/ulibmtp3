//
//  UMMTP3Task_m2paSpeedLimitReached.m
//  ulibmtp3
//
//  Created by Andreas Fink on 05/12/14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import "UMMTP3Task_m2paSpeedLimitReached.h"
#import "UMLayerMTP3.h"

@implementation UMMTP3Task_m2paSpeedLimitReached

@synthesize slc;
@synthesize userId;


- (UMMTP3Task_m2paSpeedLimitReached *)initWithReceiver:(UMLayerMTP3 *)rx
                                                sender:(id)tx
                                                   slc:(int)xslc
                                                userId:(id)uid;
{
    self = [super initWithName:[[self class]description]  receiver:rx sender:tx requiresSynchronisation:NO];
    if(self)
    {
        self.name = @"UMMTP3Task_m2paSpeedLimitReached";
        self.slc = xslc;
        self.userId = uid;
    }
    return self;
}

- (void)main
{
    @autoreleasepool
    {
        UMLayerMTP3 *mtp3 = (UMLayerMTP3 *)receiver;
        [mtp3 _m2paSpeedLimitReachedTask:self];
    }
}

@end
