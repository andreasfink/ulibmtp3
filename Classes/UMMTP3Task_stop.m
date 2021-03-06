//
//  UMMTP3Task_stop.m
//  ulibmtp3
//
//  Created by Andreas Fink on 04/04/16.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import "UMMTP3Task_stop.h"
#import "UMLayerMTP3.h"

@implementation UMMTP3Task_stop

- (UMMTP3Task_stop *)initWithReceiver:(UMLayerMTP3 *)rx
{
    self= [super initWithName:@"UMMTP3Task_stop" receiver:rx sender:NULL requiresSynchronisation:NO];
    if(self)
    {
        
    }
    return self;
}

- (void)main
{
    @autoreleasepool
    {
        UMLayerMTP3 *mtp3 = (UMLayerMTP3 *)receiver;
        [mtp3 _stop];
    }
}

@end
