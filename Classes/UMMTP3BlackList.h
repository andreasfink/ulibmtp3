//
//  UMMTP3BlackList.h
//  ulibmtp3
//
//  Created by Andreas Fink on 21/12/14.
//  Copyright (c) 2016 Andreas Fink
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import <ulib/ulib.h>
#import "UMMTP3TransitPermission.h"
@class UMMTP3Label;

@interface UMMTP3BlackList : UMObject
{
    NSMutableDictionary *_deniedTransits;
}

- (UMMTP3TransitPermission_result)isTransferDenied:(UMMTP3Label *)label;

@end
