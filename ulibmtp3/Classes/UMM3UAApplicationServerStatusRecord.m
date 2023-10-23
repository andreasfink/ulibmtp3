//
//  UMM3UAApplicationServerStatusRecord.m
//  ulibmtp3
//
//  Created by Andreas Fink on 15.08.22.
//  Copyright © 2022 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMM3UAApplicationServerStatusRecord.h"

@implementation UMM3UAApplicationServerStatusRecord


- (UMM3UAApplicationServerStatusRecord *)initWithString:(NSString *)s
{
    self = [super init];
    if(self)
    {
        _date = [NSDate date];
        _reason = s;
    }
    return self;
}
- (NSString *)stringValue
{
    return [NSString stringWithFormat:@"%@ (%@)",_date.stringValue,_reason];
}

@end
