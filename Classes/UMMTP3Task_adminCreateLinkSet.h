//
//  UMMTP3Task_adminCreateLinkSet.h
//  ulibmtp3
//
//  Created by Andreas Fink on 09.12.14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.


#import <ulib/ulib.h>
#import <ulibm2pa/ulibm2pa.h>

@class UMLayerMTP3;

@interface UMMTP3Task_adminCreateLinkSet : UMLayerTask
{
    NSString *linkset;
}

@property (readwrite,strong) NSString *linkset;

- (UMMTP3Task_adminCreateLinkSet *)initWithReceiver:(UMLayerMTP3 *)rx
                                             sender:(id)tx
                                            linkset:(NSString *)xlinkset;
@end
