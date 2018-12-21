//
//  UMMTP3TranslationTableMap.h
//  ulibmtp3
//
//  Created by Andreas Fink on 21.12.18.
//  Copyright © 2018 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/ulib.h>

@interface UMMTP3TranslationTableMap : UMObject
{
    int _map[256];
}

- (int)mapTT:(int)input;
- (void)setCondig:(NSDictionary *)config;

@end

