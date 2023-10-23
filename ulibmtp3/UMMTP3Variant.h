//
//  UMMTP3Variant.h
//  ulibmtp3
//
//  Created by Andreas Fink on 05/12/14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

typedef enum  UMMTP3Variant
{
    UMMTP3Variant_Undefined = 0,
    UMMTP3Variant_ITU       = 1,
    UMMTP3Variant_ANSI      = 2,
    UMMTP3Variant_China     = 3,
    UMMTP3Variant_Japan     = 4,
} UMMTP3Variant;

#define     UMMTP3_NATIONAL_OPTION_MESSAGE_PRIORITY 0x01
