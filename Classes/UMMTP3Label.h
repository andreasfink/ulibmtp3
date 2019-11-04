//
//  UMMTP3Label.h
//  ulibmtp3
//
//  Created by Andreas Fink on 05/12/14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import <ulib/ulib.h>
#import "UMMTP3PointCode.h"
#import "UMMTP3Variant.h"

@class UMMTP3PointCode;

@interface UMMTP3Label : UMObject<NSCopying>
{
    UMMTP3PointCode *opc;
    UMMTP3PointCode *dpc;
    int sls;
}

@property (readwrite,strong) UMMTP3PointCode *opc;
@property (readwrite,strong) UMMTP3PointCode *dpc;
@property (readwrite,assign) int sls;

- (UMMTP3Label *)initWithBytes:(const unsigned char *)bytes pos:(int *)pos variant:(UMMTP3Variant) variant;
- (NSString *)description;
- (void) appendToMutableData:(NSMutableData *)d;
- (NSString *)opc_dpc;
- (UMMTP3Label *)reverseLabel;
- (NSString *)logDescription;
- (UMMTP3Label *)copyWithZone:(NSZone *)zone;

@end
