//
//  UMMTP3Filter.h
//  ulibmtp3
//
//  Created by Andreas Fink on 20.04.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//


/* this is an objec to subclass when you want to build a mtp3 plugin to filter */

#import <ulib/ulib.h>
#import <ulibmtp3/UMMTP3PointCode.h>
#import <ulibmtp3/UMMTP3Filter_Result.h>

@interface UMMTP3PduFilter : UMPlugin
{
}

- (UMMTP3Filter_Result)filterPDU:(NSData *)data
                             opc:(UMMTP3PointCode *)opc
                             dpc:(UMMTP3PointCode *)dpc
                             sls:(int)sls
                      userpartId:(int)upid
                              ni:(int)ni
                              mp:(int)mp
                     linksetName:(NSString *)linksetName;


@end

/*
** an actual implementation of this plugin would have to implement these too:

int         plugin_init(NSDictionary *dict);
int         plugin_exit(void);
UMPlugin *  plugin_create(void);
NSString *  plugin_name(void);

*/
