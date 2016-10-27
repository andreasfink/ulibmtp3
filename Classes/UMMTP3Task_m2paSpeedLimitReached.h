//
//  UMMTP3Task_m2paSpeedLimitReached.h
//  ulibmtp3
//
//  Created by Andreas Fink on 05/12/14.
//  Copyright (c) 2016 Andreas Fink
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import <ulib/ulib.h>
#import <ulibm2pa/ulibm2pa.h>
@class UMLayerMTP3;

@interface UMMTP3Task_m2paSpeedLimitReached : UMLayerTask
{
    int slc;
    id userId;
}

@property(readwrite,assign) int slc;
@property(readwrite,strong) id userId;

- (UMMTP3Task_m2paSpeedLimitReached *)initWithReceiver:(UMLayerMTP3 *)rx
                                                sender:(id)tx
                                                   slc:(int)slc
                                                userId:(id)uid;
- (void)main;

@end
