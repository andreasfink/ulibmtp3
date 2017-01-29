//
//  UMMTP3PointCode.m
//  ulibmtp3
//
//  Created by Andreas Fink on 04/12/14.
//  Copyright (c) 2016 Andreas Fink
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import "UMMTP3PointCode.h"
@implementation UMMTP3PointCode
@synthesize variant;
@synthesize pc;


- (UMMTP3PointCode *)initWitPc:(int)pcode variant:(UMMTP3Variant)var
{
    self = [super init];
    if(self)
    {
        pc = pcode;
        variant = var;
    }
    return self;
}

- (UMMTP3PointCode *)initWithString:(NSString *)str variant:(UMMTP3Variant)var
{
    self = [super init];
    if(self)
    {
        const char *in = str.UTF8String;
        
        long a = 0;
        long b = 0;
        long c = 0;
        long res = 0;
        char *pos = NULL;
        variant = var;

        pos = strstr(in,":");
        if(pos != NULL)
        {
            sscanf(in,"%ld:%ld:%ld",&a,&b,&c);	/* for pointocdes named X:X:X we presume China */
        }
        else
        {
            pos = strstr(in,".");
            if(pos != NULL)
            {
                sscanf(in,"%ld.%ld.%ld",&a,&b,&c);
            }
            else
            {
                pos = strstr(in,"-");
                if(pos != NULL)
                {
                    sscanf(in,"%ld-%ld-%ld",&a,&b,&c);
                }
                else
                {
                    sscanf(in,"%ld",&res);
                }
            }
        }
        
        if((variant == UMMTP3Variant_China)  || (variant == UMMTP3Variant_ANSI))
        {
            res += a << 16;
            res += b << 8;
            res += c;
        }
        else
        {
            res += a << 11;
            res += b << 3;
            res += c;
        }
        pc = (int)res;
    }
    return self;
}

- (UMMTP3PointCode *)initWithBytes:(const unsigned char *)data pos:(int *)p variant:(UMMTP3Variant)var
{
    self = [super init];
    if(self)
    {
        variant = var;
        switch(var)
        {
            case UMMTP3Variant_ITU:
            {
                pc = data[(*p)++];
                pc +=  (data[(*p)++] << 8 );
                pc = pc & 0x3F;
            }
                break;
            case UMMTP3Variant_ANSI:
            {
                pc = data[(*p)++];
                pc +=  (data[(*p)++] << 8 );
                pc +=  (data[(*p)++] << 16 );
            }
                break;
            case UMMTP3Variant_China:
            {
                pc = data[(*p)++];
                pc +=  (data[(*p)++] << 8 );
                pc +=  (data[(*p)++] << 16 );
            }
                break;
            default:
                UMAssert(0,@"Unknown Pointcode Variant %d", var);
                break;
        }
    }
    return self;
}


- (UMMTP3PointCode *)initWithBytes:(const unsigned char *)data pos:(int *)p variant:(UMMTP3Variant) var status:(int *)s maxlen:(size_t)maxlen;
{
    self = [super init];
    if(self)
    {
        variant = var;
        switch(var)
        {
            case UMMTP3Variant_ITU:
            {
                if((*p+2) >maxlen)
                {
                    @throw([NSException exceptionWithName:@"MTP_DECODE"
                                                   reason:NULL
                                                 userInfo:@{
                                                            @"sysmsg" : @"not-enough-bytes",
                                                            @"func": @(__func__),
                                                            @"obj":self
                                                            }
                            ]);
                }
                *s = data[*p] >> 6;
                pc = data[(*p)++];
                pc |=  (data[(*p)++] & 0x3F) << 8;
            }
                break;
            case UMMTP3Variant_ANSI:
            case UMMTP3Variant_China:
            case UMMTP3Variant_Japan:
            {
                if((*p+4) >maxlen)
                {
                    @throw([NSException exceptionWithName:@"MTP_DECODE"
                                                   reason:NULL
                                                 userInfo:@{
                                                            @"sysmsg" : @"not-enough-bytes",
                                                            @"func": @(__func__),
                                                            @"obj":self
                                                            }
                            ]);
                }
                *s = data[(*p)++] & 0x03;
                pc = data[(*p)++];
                pc |=  (data[(*p)++] << 8 );
                pc |=  (data[(*p)++] << 16 );
            }
                break;
            default:
                UMAssert(0,@"Unknown Pointcode Variant %d", var);
                break;
        }
    }
    return self;
}

- (UMMTP3PointCode *)initWithBytes:(const unsigned char *)data pos:(int *)p variant:(UMMTP3Variant) var maxlen:(size_t)maxlen;
{
    self = [super init];
    if(self)
    {
        variant = var;
        switch(var)
        {
            case UMMTP3Variant_ITU:
            {
                if((*p+2) >maxlen)
                {
                    @throw([NSException exceptionWithName:@"MTP_DECODE"
                                                   reason:NULL
                                                 userInfo:@{
                                                            @"sysmsg" : @"not-enough-bytes",
                                                            @"func": @(__func__),
                                                            @"obj":self
                                                            }
                            ]);
                }
                pc = data[(*p)++];
                pc |=  (data[(*p)++] & 0x3F) << 8;
            }
                break;
            case UMMTP3Variant_ANSI:
            case UMMTP3Variant_China:
            case UMMTP3Variant_Japan:
            {
                if((*p+3) >maxlen)
                {
                    @throw([NSException exceptionWithName:@"MTP_DECODE"
                                                   reason:NULL
                                                 userInfo:@{
                                                            @"sysmsg" : @"not-enough-bytes",
                                                            @"func": @(__func__),
                                                            @"obj":self
                                                            }
                            ]);
                }
                pc = data[(*p)++];
                pc |=  (data[(*p)++] << 8 );
                pc |=  (data[(*p)++] << 16 );
            }
                break;
            default:
                UMAssert(0,@"Unknown Pointcode Variant %d", var);
                break;
        }
    }
    return self;
}

- (NSString *)description
{
    int a;
    int b;
    int c;
    if(variant == UMMTP3Variant_ITU)
    {
        c = pc & 0x07;
        b = (pc >> 3) & 0xFF;
        a = (pc >> 11) & 0x07;
        return [NSString stringWithFormat:@"%01d-%03d-%01d (%d)",a,b,c,pc];
    }
    c = pc & 0xFF;
    b = (pc >> 8) & 0xFF;
    a = (pc >> 16) & 0xFF;
    
    if(variant == UMMTP3Variant_China)
    {
        return [NSString stringWithFormat:@"%03d:%03d:%03d (%d)",a,b,c,pc];
    }
    if(variant == UMMTP3Variant_ANSI)
    {
        return [NSString stringWithFormat:@"%03d.%03d.%03d (%d)",a,b,c,pc];
    }
    if(variant == UMMTP3Variant_Japan)
    {
        return [NSString stringWithFormat:@"%03d_%03d_%03d (%d)",a,b,c,pc];
    }
    return [NSString stringWithFormat:@"%d", pc];
}

- (NSString *)stringValue
{
    int a;
    int b;
    int c;
    if(variant == UMMTP3Variant_ITU)
    {
        c = pc & 0x07;
        b = (pc >> 3) & 0xFF;
        a = (pc >> 11) & 0x07;
        return [NSString stringWithFormat:@"%01d-%03d-%01d",a,b,c];
    }
    c = pc & 0xFF;
    b = (pc >> 8) & 0xFF;
    a = (pc >> 16) & 0xFF;
    
    if(variant == UMMTP3Variant_China)
    {
        return [NSString stringWithFormat:@"%03d:%03d:%03d",a,b,c];
    }
    if(variant == UMMTP3Variant_ANSI)
    {
        return [NSString stringWithFormat:@"%03d.%03d.%03d",a,b,c];
    }
    if(variant == UMMTP3Variant_Japan)
    {
        return [NSString stringWithFormat:@"%03d_%03d_%03d",a,b,c];
    }
    return [NSString stringWithFormat:@"%d", pc];
}

- (int)integerValue
{
    return pc;
}

- (NSString *)logDescription
{
    return [self stringValue];
}

-(BOOL)isEqualToPointCode:(UMMTP3PointCode *)otherPc
{
    if(variant != otherPc.variant)
    {
        return NO;
    }
    if(pc != otherPc.pc)
    {
        return NO;
    }
    return YES;
}


- (NSData *) asData
{
    switch(variant)
    {
        case UMMTP3Variant_ANSI:
        {
            char buf[3];
            
            buf[0]= pc & 0xFF;
            buf[1]= (pc >> 8) & 0xFF;
            buf[2]= (pc >> 16) & 0xFF;
            return [NSData dataWithBytes:buf length:3];
        }
            break;
        case UMMTP3Variant_China:
        {
            char buf[3];
            
            buf[0]= pc & 0xFF;
            buf[1]= (pc >> 8) & 0xFF;
            buf[2]= (pc >> 16) & 0xFF;
            return [NSData dataWithBytes:buf length:3];
        }
            break;
        case UMMTP3Variant_ITU:
        {
            char buf[2];
            
            buf[0]= pc & 0xFF;
            buf[1]= (pc >> 8) & 0x3F;
            return [NSData dataWithBytes:buf length:2];
        }
            break;
        default:
            UMAssert(0,@"Undefined variant");
    }
    return NULL;
}

- (NSData *) asDataWithStatus:(int)status
{
    switch(variant)
    {
        case UMMTP3Variant_ANSI:
        case UMMTP3Variant_China:
        case UMMTP3Variant_Japan:
        {
            char buf[4];
            buf[0]= status & 0x03;
            buf[1]= pc & 0xFF;
            buf[2]= (pc >> 8) & 0xFF;
            buf[3]= (pc >> 16) & 0xFF;
            return [NSData dataWithBytes:buf length:4];
        }
            break;
        case UMMTP3Variant_ITU:
        {
            char buf[2];
            
            buf[0]= (pc & 0x3F) | ((status & 0x03) << 6);
            buf[1]= (pc >> 8) & 0x3F;
            return [NSData dataWithBytes:buf length:2];
        }
            break;
        default:
            UMAssert(0,@"Undefined variant");
    }
    return NULL;
}

@end
