//
//  UMMTP3Task_adminAttachOrder.h
//  ulibmtp3
//
//  Created by Andreas Fink on 08/12/14.
//  Copyright (c) 2016 Andreas Fink
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import <ulib/ulib.h>
#import <ulibm2pa/ulibm2pa.h>

@class UMLayerMTP3;

@interface UMMTP3Task_adminAttachOrder : UMLayerTask
{
    int slc;
    UMLayerM2PA *m2pa;
    NSString    *linkset;
}

@property(readwrite,assign)   int slc;
@property(readwrite,strong)   UMLayerM2PA *m2pa;
@property(readwrite,strong)   NSString *linkset;

- (UMMTP3Task_adminAttachOrder *)initWithReceiver:(UMLayerMTP3 *)rx
                                           sender:(id)tx
                                              slc:(int)xslc
                                             m2pa:(UMLayerM2PA *)xm2pa
                                          linkset:(NSString *)linksetName;


@end
