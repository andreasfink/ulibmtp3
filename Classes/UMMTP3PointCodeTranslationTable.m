//
//  UMMTP3PointCodeTranslationTable.m
//  ulibmtp3
//
//  Created by Andreas Fink on 04.11.19.
//  Copyright © 2019 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMMTP3PointCodeTranslationTable.h"

@implementation UMMTP3PointCodeTranslationTable


- (UMMTP3PointCodeTranslationTable *)init
{
    return [self initWithConfig:NULL];
}

- (UMMTP3PointCodeTranslationTable *)initWithConfig:(NSDictionary *)dict
{
    self = [super init];
    if(self)
    {
        _localToRemote = [[UMSynchronizedSortedDictionary alloc]init];
        _remoteToLocal = [[UMSynchronizedSortedDictionary alloc]init];
        if(dict)
        {
            [self setConfig:dict];
        }
    }
    return self;
}

- (void)setConfig:(NSDictionary *)dict
{
    if(dict[@"name"])
    {
        _name = dict[@"name"];
    }
    if(dict[@"default-local-pc"])
    {
        _defaultLocalPointCode = [[UMMTP3PointCode alloc]initWithString:dict[@"default-local-pc"] variant:UMMTP3Variant_Undefined];
    }
    if(dict[@"default-remote-pc"])
    {
        _defaultRemotePointCode = [[UMMTP3PointCode alloc]initWithString:dict[@"default-remote-pc"] variant:UMMTP3Variant_Undefined];
    }

    if(dict[@"local-ni"])
    {
        _localNetworkIndicator = @([dict[@"local-ni"] intValue]);
    }

    if(dict[@"remote-ni"])
    {
        _remoteNetworkIndicator = @([dict[@"remote-ni"] intValue]);
    }

    if(dict[@"map"])
    {
        _localToRemote = [[UMSynchronizedSortedDictionary alloc]init];
        _remoteToLocal = [[UMSynchronizedSortedDictionary alloc]init];

        id map =dict[@"map"];
        NSArray *a = NULL;
        if([map isKindOfClass:[NSString class]])
        {
            NSString *s = (NSString *)map;
            a = [s componentsSeparatedByString:@";"];
        }
        else if([map isKindOfClass:[NSArray class]])
        {
            a = (NSArray *)map;
        }
        for(NSString *s in a)
        {
            NSArray *components = [s componentsSeparatedByString:@","];
            if(components.count==2)
            {
                NSString *localPc = components[0];
                UMMTP3PointCode *lpc =  [[UMMTP3PointCode alloc]initWithString:localPc variant:UMMTP3Variant_Undefined];
                NSString *remotePc = components[1];
                UMMTP3PointCode *rpc =  [[UMMTP3PointCode alloc]initWithString:remotePc variant:UMMTP3Variant_Undefined];
                _localToRemote[@(lpc.pc)] = @(rpc.pc);
                _remoteToLocal[@(rpc.pc)] = @(lpc.pc);
            }
            else
            {
                NSArray *components = [s componentsSeparatedByString:@"<"];
                if(components.count==2)
                {
                    NSString *localPc = components[0];
                    UMMTP3PointCode *lpc =  [[UMMTP3PointCode alloc]initWithString:localPc variant:UMMTP3Variant_Undefined];
                    NSString *remotePc = components[1];
                    UMMTP3PointCode *rpc =  [[UMMTP3PointCode alloc]initWithString:remotePc variant:UMMTP3Variant_Undefined];
                    _remoteToLocal[@(rpc.pc)] = @(lpc.pc);
                }
                else
                {
                    NSArray *components = [s componentsSeparatedByString:@">"];
                    if(components.count==2)
                    {
                        NSString *localPc = components[0];
                        UMMTP3PointCode *lpc =  [[UMMTP3PointCode alloc]initWithString:localPc variant:UMMTP3Variant_Undefined];
                        NSString *remotePc = components[1];
                        UMMTP3PointCode *rpc =  [[UMMTP3PointCode alloc]initWithString:remotePc variant:UMMTP3Variant_Undefined];
                        _localToRemote[@(lpc.pc)] = @(rpc.pc);
                    }
                }
            }
        }
    }
}

- (UMMTP3PointCode *)translateLocalToRemote:(UMMTP3PointCode *)pc
{
    NSNumber *pc1 = _localToRemote[@(pc.pc)];
    if(pc1==NULL)
    {
        return _defaultLocalPointCode;
    }
    UMMTP3PointCode *pc2 = [[UMMTP3PointCode alloc]initWithPc:pc1.intValue variant:pc.variant];
    return pc2;
}

- (UMMTP3PointCode *)translateRemoteToLocal:(UMMTP3PointCode *)pc
{
    NSNumber *pc1 = _remoteToLocal[@(pc.pc)];
    if(pc1==NULL)
    {
        return _defaultRemotePointCode;
    }
    UMMTP3PointCode *pc2 = [[UMMTP3PointCode alloc]initWithPc:pc1.intValue variant:pc.variant];
    return pc2;
}

@end
