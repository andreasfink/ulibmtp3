//
//  UMMTP3Task_adminAttachOrder.h
//  ulibmtp3
//
//  Created by Andreas Fink on 08/12/14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import <ulib/ulib.h>
#import <ulibm2pa/ulibm2pa.h>

@class UMLayerMTP3;

@interface UMMTP3Task_adminAttachOrder : UMLayerTask
{
    int 		_slc;
    UMLayerM2PA *_m2pa;
    NSString    *_linkSetName;
	NSString 	*_linkName;
}

@property(readwrite,assign)   int 			slc;
@property(readwrite,strong)   UMLayerM2PA 	*m2pa;
@property(readwrite,strong)   NSString 		*linkSetName;
@property(readwrite,strong)   NSString 		*linkName;

- (UMMTP3Task_adminAttachOrder *)initWithReceiver:(UMLayerMTP3 *)rx
                                           sender:(id)tx
                                              slc:(int)xslc
                                             m2pa:(UMLayerM2PA *)xm2pa
									  linkSetName:(NSString *)linkSetName
										 linkName:(NSString *)linkName;


@end
