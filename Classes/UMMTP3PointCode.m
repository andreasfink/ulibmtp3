//
//  UMMTP3PointCode.m
//  ulibmtp3
//
//  Created by Andreas Fink on 04/12/14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import "UMMTP3PointCode.h"
@implementation UMMTP3PointCode

- (UMMTP3PointCode *)initWitPc:(int)pcode variant:(UMMTP3Variant)var; /* typo version for backwards compatibility */
{
    return [self initWithPc:pcode variant:var];
}

- (UMMTP3PointCode *)initWithPc:(int)pcode variant:(UMMTP3Variant)var
{
    self = [super init];
    if(self)
    {
        _pc = pcode;
        _variant = var;
    }
    return self;
}

- (UMMTP3PointCode *)initWithString:(NSString *)str variant:(UMMTP3Variant)var
{
    if(str==NULL)
    {
        return NULL;
    }
    self = [super init];
    if(self)
    {
        const char *in = str.UTF8String;
        
        long a = 0;
        long b = 0;
        long c = 0;
        long res = 0;
        char *pos = NULL;
        _variant = var;

        pos = strstr(in,":");
        if(pos != NULL)
        {
            if(var==UMMTP3Variant_Undefined)
            {
                var = UMMTP3Variant_China;
            }
            sscanf(in,"%ld:%ld:%ld",&a,&b,&c);	/* for pointocdes named X:X:X we presume China */
        }
        else
        {
            pos = strstr(in,".");
            if(pos != NULL)
            {
                if(var==UMMTP3Variant_Undefined)
                {
                    var = UMMTP3Variant_ANSI;
                }
                sscanf(in,"%ld.%ld.%ld",&a,&b,&c);
            }
            else
            {
                pos = strstr(in,"-");

                if(pos != NULL)
                {
                    if(var==UMMTP3Variant_Undefined)
                    {
                        var = UMMTP3Variant_ITU;
                    }
                    sscanf(in,"%ld-%ld-%ld",&a,&b,&c);
                }
                else
                {
                    sscanf(in,"%ld",&res);
                }
            }
        }
        if((_variant == UMMTP3Variant_China)  || (_variant == UMMTP3Variant_ANSI))
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
        _pc = (int)res;
    }
    return self;
}

- (UMMTP3PointCode *)initWithBytes:(const unsigned char *)data pos:(int *)p variant:(UMMTP3Variant)var
{
    self = [super init];
    if(self)
    {
        _variant = var;
        switch(var)
        {
            case UMMTP3Variant_ITU:
            {
                _pc  = data[(*p)++];
                _pc +=  (data[(*p)++] << 8 );
                _pc  = _pc & 0x3F;
            }
                break;
            case UMMTP3Variant_ANSI:
            {
                _pc = data[(*p)++];
                _pc +=  (data[(*p)++] << 8 );
                _pc +=  (data[(*p)++] << 16 );
            }
                break;
            case UMMTP3Variant_China:
            {
                _pc = data[(*p)++];
                _pc +=  (data[(*p)++] << 8 );
                _pc +=  (data[(*p)++] << 16 );
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
        _variant = var;
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
                _pc = data[(*p)++];
                _pc |=  (data[(*p)++] & 0x3F) << 8;
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
                _pc = data[(*p)++];
                _pc |=  (data[(*p)++] << 8 );
                _pc |=  (data[(*p)++] << 16 );
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
        _variant = var;
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
                _pc = data[(*p)++];
                _pc |=  (data[(*p)++] & 0x3F) << 8;
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
                _pc = data[(*p)++];
                _pc |=  (data[(*p)++] << 8 );
                _pc |=  (data[(*p)++] << 16 );
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
    if(_variant == UMMTP3Variant_ITU)
    {
        c = _pc & 0x07;
        b = (_pc >> 3) & 0xFF;
        a = (_pc >> 11) & 0x07;
        return [NSString stringWithFormat:@"%01d-%03d-%01d (%d)",a,b,c,_pc];
    }
    c = _pc & 0xFF;
    b = (_pc >> 8) & 0xFF;
    a = (_pc >> 16) & 0xFF;
    
    if(_variant == UMMTP3Variant_China)
    {
        return [NSString stringWithFormat:@"%03d:%03d:%03d (%d)",a,b,c,_pc];
    }
    if(_variant == UMMTP3Variant_ANSI)
    {
        return [NSString stringWithFormat:@"%03d.%03d.%03d (%d)",a,b,c,_pc];
    }
    if(_variant == UMMTP3Variant_Japan)
    {
        return [NSString stringWithFormat:@"%03d_%03d_%03d (%d)",a,b,c,_pc];
    }
    return [NSString stringWithFormat:@"%d", _pc];
}

- (NSString *)stringValue
{
    int a;
    int b;
    int c;
    if(_variant == UMMTP3Variant_ITU)
    {
        c = _pc & 0x07;
        b = (_pc >> 3) & 0xFF;
        a = (_pc >> 11) & 0x07;
        return [NSString stringWithFormat:@"%01d-%03d-%01d",a,b,c];
    }
    c = _pc & 0xFF;
    b = (_pc >> 8) & 0xFF;
    a = (_pc >> 16) & 0xFF;
    
    if(_variant == UMMTP3Variant_China)
    {
        return [NSString stringWithFormat:@"%03d:%03d:%03d",a,b,c];
    }
    if(_variant == UMMTP3Variant_ANSI)
    {
        return [NSString stringWithFormat:@"%03d.%03d.%03d",a,b,c];
    }
    if(_variant == UMMTP3Variant_Japan)
    {
        return [NSString stringWithFormat:@"%03d_%03d_%03d",a,b,c];
    }
    return [NSString stringWithFormat:@"%d", _pc];
}

- (int)integerValue
{
    return _pc;
}

- (NSString *)logDescription
{
    return [self stringValue];
}

-(BOOL)isEqualToPointCode:(UMMTP3PointCode *)otherPc
{
    if(_variant != otherPc.variant)
    {
        return NO;
    }
    if(_pc != otherPc.pc)
    {
        return NO;
    }
    return YES;
}


- (NSData *) asData
{
    switch(_variant)
    {
        case UMMTP3Variant_ANSI:
        {
            char buf[3];
            
            buf[0]= _pc & 0xFF;
            buf[1]= (_pc >> 8) & 0xFF;
            buf[2]= (_pc >> 16) & 0xFF;
            return [NSData dataWithBytes:buf length:3];
        }
            break;
        case UMMTP3Variant_China:
        {
            char buf[3];
            
            buf[0]= _pc & 0xFF;
            buf[1]= (_pc >> 8) & 0xFF;
            buf[2]= (_pc >> 16) & 0xFF;
            return [NSData dataWithBytes:buf length:3];
        }
            break;
        case UMMTP3Variant_ITU:
        {
            char buf[2];
            
            buf[0]= _pc & 0xFF;
            buf[1]= (_pc >> 8) & 0x3F;
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
    switch(_variant)
    {
        case UMMTP3Variant_ANSI:
        case UMMTP3Variant_China:
        case UMMTP3Variant_Japan:
        {
            char buf[4];
            buf[0]= status & 0x03;
            buf[1]= _pc & 0xFF;
            buf[2]= (_pc >> 8) & 0xFF;
            buf[3]= (_pc >> 16) & 0xFF;
            return [NSData dataWithBytes:buf length:4];
        }
            break;
        case UMMTP3Variant_ITU:
        {
            char buf[2];
            
            buf[0]= (_pc & 0x3F) | ((status & 0x03) << 6);
            buf[1]= (_pc >> 8) & 0x3F;
            return [NSData dataWithBytes:buf length:2];
        }
            break;
        default:
            UMAssert(0,@"Undefined variant");
    }
    return NULL;
}

- (UMMTP3PointCode *)maskedPointcode:(int)mask
{
    if(mask == 0)
    {
        return self;
    }
    UMMTP3PointCode *pc2 = [[UMMTP3PointCode alloc]init];
    pc2.variant = self.variant;
    int maskbits;
    if(UMMTP3Variant_ITU == self.variant)
    {
        maskbits = 0x3FFF;
    }
    else
    {
        maskbits = 0xFFFFFF;
    }
    maskbits = maskbits << mask;
    pc2.pc = self.pc & maskbits;
    return pc2;
}

- (int)maxmask
{
    if(_variant==UMMTP3Variant_ITU)
    {
        return 14;
    }
    return 24;
}

- (NSString *)maskedPointcodeString:(int)mask
{
    UMMTP3PointCode *pc2 = [self maskedPointcode:mask];
    return [NSString stringWithFormat:@"%@/%d",pc2.stringValue,([self maxmask]-mask)];
}


- (UMMTP3PointCode *)copyWithZone:(NSZone *)zone
{
    return [[UMMTP3PointCode allocWithZone:zone]initWithPc:_pc variant:_variant];
}


- (id)proxyForJson
{
    UMSynchronizedSortedDictionary *d = [[UMSynchronizedSortedDictionary alloc]init];
    d[@"pc-dec"] = @(_pc);
    d[@"pc-string"] = [self stringValue];
    switch(_variant)
    {
        case UMMTP3Variant_ITU:
            d[@"variant"] = @"itu";
            break;
        case UMMTP3Variant_ANSI:
            d[@"variant"] = @"ansi";
            break;
        case UMMTP3Variant_China:
            d[@"variant"] = @"China";
            break;
        case UMMTP3Variant_Japan:
            d[@"variant"] = @"Japan";
            break;
        default:
            d[@"variant"] = @"unknown";
            break;

    }
    return d;
}
@end
