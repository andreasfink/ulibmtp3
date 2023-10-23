//
//  UMM3UAApplicationServerStatusRecord.h
//  ulibmtp3
//
//  Created by Andreas Fink on 15.08.22.
//  Copyright © 2022 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/ulib.h>


@interface UMM3UAApplicationServerStatusRecord : UMObject
{
    NSDate      *_date;
    NSString    *_reason;
}

@property(readwrite,strong,atomic)  NSDate      *date;
@property(readwrite,strong,atomic)  NSString    *reason;

- (UMM3UAApplicationServerStatusRecord *)initWithString:(NSString *)s;
- (NSString *)stringValue;
@end

