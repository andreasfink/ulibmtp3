//
//  UMMTP3Task_m2paStatusIndication.h
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

@interface UMMTP3Task_m2paStatusIndication : UMLayerTask
{
    int slc;
    id userId;
    M2PA_Status status;
}

@property(readwrite,assign) int slc;
@property(readwrite,strong) id userId;
@property(readwrite,assign) M2PA_Status status;

- (UMMTP3Task_m2paStatusIndication *)initWithReceiver:(UMLayerMTP3 *)rx
                                               sender:(id)tx
                                                  slc:(int)slc
                                               userId:(id)uid
                                               status:(M2PA_Status)s;
- (void)main;

@end
