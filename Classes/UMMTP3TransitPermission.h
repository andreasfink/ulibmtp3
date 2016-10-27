//
//  UMMTP3TransitPermission.h
//  ulibmtp3
//
//  Created by Andreas Fink on 21/12/14.
//  Copyright (c) 2016 Andreas Fink
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import <ulib/ulib.h>

@class UMMTP3PointCode;

typedef enum UMMTP3TransitPermission_result
{
    UMMTP3TransitPermission_undefined=0,
    UMMTP3TransitPermission_explicitlyPermitted=1,
    UMMTP3TransitPermission_implicitlyPermitted=2,
    UMMTP3TransitPermission_explicitlyDenied=-1,
    UMMTP3TransitPermission_implicitlyDenied=-2,
    UMMTP3TransitPermission_errorResult = -99,
} UMMTP3TransitPermission_result;

@interface UMMTP3TransitPermission : UMObject
{
    UMMTP3PointCode *opc;
    UMMTP3PointCode *dpc;
}

@property (readwrite,strong) UMMTP3PointCode *opc;
@property (readwrite,strong) UMMTP3PointCode *dpc;

- (NSString *)opc_dpc;

@end
