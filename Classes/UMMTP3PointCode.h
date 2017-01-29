//
//  UMMTP3PointCode.h
//  ulibmtp3
//
//  Created by Andreas Fink on 04/12/14.
//  Copyright (c) 2016 Andreas Fink
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import <ulib/ulib.h>
#import "UMMTP3Variant.h"

@interface UMMTP3PointCode : UMObject
{
    UMMTP3Variant variant;
    int pc;
}

@property(readwrite,assign) UMMTP3Variant variant;
@property(readwrite,assign) int pc;

- (UMMTP3PointCode *)initWitPc:(int)pcode variant:(UMMTP3Variant)var;
- (UMMTP3PointCode *)initWithBytes:(const unsigned char *)data pos:(int *)p variant:(UMMTP3Variant) var;

/* These do throw NSErrors if length is not ok */
- (UMMTP3PointCode *)initWithBytes:(const unsigned char *)data pos:(int *)p variant:(UMMTP3Variant) var status:(int *)s maxlen:(size_t)maxlen;
- (UMMTP3PointCode *)initWithBytes:(const unsigned char *)data pos:(int *)p variant:(UMMTP3Variant) var maxlen:(size_t)maxlen;

- (NSString *)description;
- (BOOL)isEqualToPointCode:(UMMTP3PointCode *)otherPc;
- (NSData *)asData;
- (NSData *)asDataWithStatus:(int)status;
- (NSString *)stringValue;
- (int) integerValue;
- (UMMTP3PointCode *)initWithString:(NSString *)str variant:(UMMTP3Variant)var;
- (NSString *)logDescription;
@end
