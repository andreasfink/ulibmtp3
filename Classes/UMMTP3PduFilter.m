//
//  UMMTP3Filter.m
//  ulibmtp3
//
//  Created by Andreas Fink on 20.04.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMMTP3PduFilter.h"

@implementation UMMTP3PduFilter

- (UMMTP3PduFilter *) init
{
    self = [super init];
    if(self)
    {

    }
    return self;
}

- (UMMTP3Filter_Result)filterPDU:(NSData *)data
                             opc:(UMMTP3PointCode *)opc
                             dpc:(UMMTP3PointCode *)dpc
                             sls:(int)sls
                      userpartId:(int)upid
                              ni:(int)ni
                              mp:(int)mp
                     linksetName:(NSString *)linksetName
{
    return UMMTP3Filter_Result_undefined;
}

@end

UMPlugin *plugin_create(void)
{
    return [[UMMTP3PduFilter alloc]init];
}

int plugin_init(void)
{
    return 0;
}

int plugin_exit(void)
{
    return 0;
}

