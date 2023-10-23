//
//  UMMTP3TransitPermission.m
//  ulibmtp3
//
//  Created by Andreas Fink on 21/12/14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import "UMMTP3TransitPermission.h"

#import "UMMTP3PointCode.h"

@implementation UMMTP3TransitPermission
@synthesize opc;
@synthesize dpc;

- (NSString *)opc_dpc
{
    return [NSString stringWithFormat:@"%d>%d",opc.pc,dpc.pc];
}

@end
