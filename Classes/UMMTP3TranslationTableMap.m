//
//  UMMTP3TranslationTableMap.m
//  ulibmtp3
//
//  Created by Andreas Fink on 21.12.18.
//  Copyright © 2018 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMMTP3TranslationTableMap.h"

@implementation UMMTP3TranslationTableMap


- (int)mapTT:(int)input
{
    return _map[input % 256];
}

- (void)setCondig:(NSDictionary *)config
{
    for(int i=0;i<256;i++)
    {
        NSString *n = [NSString stringWithFormat:@"%d",i];
        if(config[n]==NULL)
        {
            _map[i]=i;
        }
        else
        {
            _map[i] = [config[n] intValue];
        }
    }
}

@end
