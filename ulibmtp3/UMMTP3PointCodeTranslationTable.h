//
//  UMMTP3PointCodeTranslationTable.h
//  ulibmtp3
//
//  Created by Andreas Fink on 04.11.19.
//  Copyright © 2019 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/ulib.h>

#import "UMMTP3PointCode.h"

@interface UMMTP3PointCodeTranslationTable : UMObject
{
    NSString        *_name;
    UMMTP3PointCode *_defaultLocalPointCode;
    NSNumber        *_localNetworkIndicator;

    UMMTP3PointCode *_defaultRemotePointCode;
    NSNumber        *_remoteNetworkIndicator;

    UMSynchronizedSortedDictionary *_localToRemote;
    UMSynchronizedSortedDictionary *_remoteToLocal;

}

@property(readwrite,strong,atomic)  NSString        *name;
@property(readwrite,strong,atomic)  UMMTP3PointCode *defaultLocalPointCode;
@property(readwrite,strong,atomic)  NSNumber        *localNetworkIndicator;
@property(readwrite,strong,atomic)  UMMTP3PointCode *defaultRemotePointCode;
@property(readwrite,strong,atomic)  NSNumber        *remoteNetworkIndicator;

- (UMMTP3PointCode *)translateLocalToRemote:(UMMTP3PointCode *)pc;
- (UMMTP3PointCode *)translateRemoteToLocal:(UMMTP3PointCode *)pc;
- (UMMTP3PointCodeTranslationTable *)initWithConfig:(NSDictionary *)dict;
- (void)setConfig:(NSDictionary *)dict;


@end

