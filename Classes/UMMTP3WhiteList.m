//
//  UMMTP3WhiteList.m
//  ulibmtp3
//
//  Created by Andreas Fink on 21/12/14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import "UMMTP3WhiteList.h"
#import "UMMTP3PointCode.h"
#import "UMMTP3Label.h"
#import "UMMTP3TransitPermission.h"

@implementation UMMTP3WhiteList

- (UMMTP3WhiteList *)init
{
    self = [super init];
    if(self)
    {
        _permittedTransits = [[NSMutableDictionary alloc]init];
    }
    return self;
}

- (void)addPermission:(UMMTP3TransitPermission *)p
{
    
}

- (void)removePermission:(UMMTP3TransitPermission *)p
{
    
}

- (UMMTP3TransitPermission_result)isTransferAllowed:(UMMTP3Label *)label
{
    NSString *opc_dpc = [NSString stringWithFormat:@"%d>%d",label.opc.pc,label.dpc.pc];
    UMMTP3TransitPermission *t;
    @synchronized(_permittedTransits)
    {
        t = _permittedTransits[opc_dpc];
    }
    if(t)
    {
        return UMMTP3TransitPermission_explicitlyPermitted;
    }
    return UMMTP3TransitPermission_undefined;
}

@end
