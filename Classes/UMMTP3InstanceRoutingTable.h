//
//  UMMTP3InstanceRoutingTable.h
//  ulibmtp3
//
//  Created by Andreas Fink on 26.01.17.
//  Copyright © 2017 Andreas Fink. All rights reserved.
//

#import <ulib/ulib.h>
#import "UMMTP3RoutingTable.h"


/* in comparison to the link routing table, the instance routing table
 can have more than one entry per pointcode. Hence its a 
 UMSychronizedSortedDictionary of
 UMSychronizedSortedDictionary of 
 UMMTP3Route objects
 The first key is the linkset name, the second one is the pointcode.
 So its basically an UMSychronizedSortedDictionary of UMMTP3LinkRoutingTable objects
 */

@interface UMMTP3InstanceRoutingTable : UMMTP3RoutingTable
{
    UMSynchronizedSortedDictionary *routingTablesByLinkset;
}

- (UMMTP3InstanceRoutingTable *)initWithLinkSetSortedDict:(UMSynchronizedSortedDictionary *)arr;

@end
