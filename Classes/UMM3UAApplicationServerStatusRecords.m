//
//  UMM3UAApplicationServerStatusRecords.m
//  ulibmtp3
//
//  Created by Andreas Fink on 15.08.22.
//  Copyright © 2022 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMM3UAApplicationServerStatusRecords.h"

@implementation UMM3UAApplicationServerStatusRecords

- (UMM3UAApplicationServerStatusRecords *)init
{
    self = [super init];
    {
        for(int i=0;i<UMM3UAApplicationServerStatusRecord_max_entries;i++)
        {
            _entries[i] = NULL;
        }
        _lock = [[UMMutex alloc]initWithName:@"UMM3UAApplicationServerStatusRecords-lock"];
    }
    return self;
}

- (void)addEvent:(NSString *)event
{
    [_lock lock];
    UMM3UAApplicationServerStatusRecord *entry = [[UMM3UAApplicationServerStatusRecord alloc]initWithString:event];
    int i = UMM3UAApplicationServerStatusRecord_max_entries-1;
    while(i>0)
    {
        _entries[i] = _entries[i-1];
        i--;
    }
    _entries[0] = entry;
    [_lock unlock];
}

- (NSString *)stringValue
{
    if(_entries[0]==NULL)
    {
        return @"";
    }
    NSMutableString *s = [[NSMutableString alloc]init];
    [s appendFormat:@"\t%@\n",[_entries[0] stringValue]];
    for(int i=1;i<UMM3UAApplicationServerStatusRecord_max_entries;i++)
    {
        if(_entries[i] == NULL)
        {
            break;
        }
        [s appendFormat:@"\t\t%@\n",[_entries[i] stringValue]];
    }
    return s;
}
@end
