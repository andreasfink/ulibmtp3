//
//  UMMTP3Variant.m
//  ulibmtp3
//
//  Created by Andreas Fink on 17.07.2025.
//  Copyright © 2025 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/ulib.h>
#import <ulibmtp3/UMMTP3Variant.h>

NSString *ummtp3_variant_to_string(UMMTP3Variant v)
{
    switch(v)
    {
        case UMMTP3Variant_ITU:
            return @"itu";
        case UMMTP3Variant_ANSI:
            return @"ansi";
        case UMMTP3Variant_China:
            return @"china";
        case UMMTP3Variant_Japan:
            return @"japan";
        default:
            return @"undefined";
    }
}

UMMTP3Variant ummtp3_string_toVariant(NSString *s)
{
    if([s isEqualToStringCaseInsensitive:@"itu"])
    {
        return UMMTP3Variant_ITU;
    }
    else if([s isEqualToStringCaseInsensitive:@"ansi"])
    {
        return UMMTP3Variant_ANSI;
    }
    else if([s isEqualToStringCaseInsensitive:@"china"])
    {
        return UMMTP3Variant_China;
    }
    else if([s isEqualToStringCaseInsensitive:@"japan"])
    {
        return UMMTP3Variant_Japan;
    }
    else
    {
        return UMMTP3Variant_Undefined;
    }
}
