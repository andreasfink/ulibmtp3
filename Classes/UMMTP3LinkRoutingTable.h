//
//  UMMTP3LinkRoutingTable.h
//  ulibmtp3
//
//  Created by Andreas Fink on 26.01.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
#if 0
#import <ulib/ulib.h>
#import "UMMTP3RoutingTable.h"

/* in comparison to the instance routing table, the link routing table
 can have only one entry per pointcode. Hence its a
 UMSychronizedSortedDictionary of
 UMMTP3InstanceRoute objects
 The  key is the pointcode's stringValue
 */

@interface UMMTP3LinkRoutingTable : UMMTP3RoutingTable
{
}

- (NSString *)jsonString;
@end
#endif

