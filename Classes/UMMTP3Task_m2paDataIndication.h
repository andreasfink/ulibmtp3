//
//  UMMTP3Task_m2paDataIndication.h
//  ulibmtp3
//
//  Created by Andreas Fink on 05/12/14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import <ulib/ulib.h>
#import <ulibm2pa/ulibm2pa.h>
@class UMLayerMTP3;
@class UMMTP3Link;
@interface UMMTP3Task_m2paDataIndication : UMLayerTask
{
    int		_slc;
    NSString *_m3linkName;
    NSData	*_data;
	int 	_prio;
}

@property(readwrite,assign) int slc;
@property(readwrite,strong) NSString *m3linkName;
@property(readwrite,strong) NSData *data;
@property(readwrite,assign) int prio;

- (UMMTP3Task_m2paDataIndication *)initWithReceiver:(UMLayerMTP3 *)rx
											 sender:(id)tx
												slc:(int)slc
									   mtp3linkName:(NSString *)m3linkName
											   data:(NSData *)d
									   priorityByte:(int)prio;

- (void)main;

@end
