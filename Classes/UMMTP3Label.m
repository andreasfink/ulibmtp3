//
//  UMMTP3Label.m
//  ulibmtp3
//
//  Created by Andreas Fink on 05/12/14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import "UMMTP3Label.h"
#import "UMMTP3PointCode.h"

@implementation UMMTP3Label

@synthesize opc;
@synthesize dpc;
@synthesize sls;

- (UMMTP3Label *)initWithBytes:(const unsigned char *)data pos:(int *)p variant:(UMMTP3Variant) variant
{
    self = [super init];
    int xopc;
    int xdpc;
    
    if(self)
    {
        switch(variant)
        {
            case UMMTP3Variant_ANSI:
            case UMMTP3Variant_China:
            case UMMTP3Variant_Japan:
                xdpc = data[(*p)++];
                xdpc |= data[(*p)++] << 8;
                xdpc |= data[(*p)++] << 16;
                xopc = data[(*p)++];
                xopc |= data[(*p)++] << 8;
                xopc |= data[(*p)++] << 16;
                if(variant==UMMTP3Variant_ANSI)
                {
                    sls = data[(*p)++];
                }
                else
                {
                    sls = data[(*p)++] & 0x1F;
                }
                break;
                
            default:
            {
                unsigned int label;
                label  = (data[(*p)+3] << 24) + (data[(*p)+2] << 16) + (data [(*p)+1] << 8) + data[(*p)];
                (*p) +=4;
                xdpc = label & 0x3FFF;
                xopc = (label >> 14) & 0x3FFF;
                sls = (label >> 28) & 0x0F;
            }
                break;
        }
        opc = [[UMMTP3PointCode alloc]initWithPc:xopc variant:variant];
        dpc = [[UMMTP3PointCode alloc]initWithPc:xdpc variant:variant];
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"[OPC=%@/DPC=%@/SLS=%d]",opc.description,dpc.description,sls];
}

- (NSString *)logDescription
{
    return [NSString stringWithFormat:@"%@->%@",opc.logDescription,dpc.logDescription];
}

- (void) appendToMutableData:(NSMutableData *)d
{
    switch(dpc.variant)
    {
        case UMMTP3Variant_ANSI:
        case UMMTP3Variant_China:
        case UMMTP3Variant_Japan:
        {
            char buf[7];
            
            buf[0]= dpc.pc & 0xFF;
            buf[1]= (dpc.pc >> 8) & 0xFF;
            buf[2]= (dpc.pc >> 16) & 0xFF;
            buf[3]= opc.pc & 0xFF;
            buf[4]= (opc.pc >> 8) & 0xFF;
            buf[5]= (opc.pc >> 16) & 0xFF;
            if(dpc.variant==UMMTP3Variant_ANSI)
            {
                buf[6]= sls;
            }
            else
            {
                buf[6]= sls & 0x1F;
            }
            [d appendBytes:buf length:7];
            
        }
            break;
        case UMMTP3Variant_ITU:
        {
            char buf[4];
            
            unsigned long label;
            label = dpc.pc & 0x3FFFF;
            label = label | ((opc.pc & 0x3FFF) << 14);
            label = label | ((sls & 0x0F) << 28);
            buf[0]= label & 0xFF;
            buf[1]= (label>>8) & 0xFF;
            buf[2]= (label>>16) & 0xFF;
            buf[3]= (label>>24) & 0xFF;
            [d appendBytes:buf length:4];
        }
            break;
        default:
            UMAssert(0,@"Undefined variant");
    }
}
- (NSString *)opc_dpc
{
    return [NSString stringWithFormat:@"%d>%d",opc.pc,dpc.pc];
}

- (UMMTP3Label *)reverseLabel
{
    UMMTP3Label *rlabel = [[UMMTP3Label alloc]init];
    rlabel.opc = self.dpc;
    rlabel.dpc = self.opc;
    rlabel.sls = self.sls;
    return rlabel;
}

@end
