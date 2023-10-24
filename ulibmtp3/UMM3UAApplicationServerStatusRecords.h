//
//  UMM3UAApplicationServerStatusRecords.h
//  ulibmtp3
//
//  Created by Andreas Fink on 15.08.22.
//  Copyright © 2022 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/ulib.h>
#import <ulibmtp3/UMM3UAApplicationServerStatusRecord.h>

#define UMM3UAApplicationServerStatusRecord_max_entries 10

@interface UMM3UAApplicationServerStatusRecords : UMObject
{
    UMM3UAApplicationServerStatusRecord *_entries[UMM3UAApplicationServerStatusRecord_max_entries];
    UMMutex *_aspStatusRecordLock;
}

- (void)addEvent:(NSString *)event;
- (NSString *)stringValue;

@end

