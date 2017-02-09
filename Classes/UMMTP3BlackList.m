//
//  UMMTP3BlackList.m
//  ulibmtp3
//
//  Created by Andreas Fink on 21/12/14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import "UMMTP3BlackList.h"
#import "UMMTP3TransitPermission.h"
#import "UMMTP3Label.h"


@implementation UMMTP3BlackList


- (UMMTP3TransitPermission_result)isTransferDenied:(UMMTP3Label *)label
{
    UMMTP3TransitPermission *t;
    @synchronized(_deniedTransits)
    {
        t = _deniedTransits[label.opc_dpc];
    }
    if(t)
    {
        return UMMTP3TransitPermission_explicitlyDenied;
    }
    return UMMTP3TransitPermission_undefined;
}

@end
