//
//  UMMTP3LinkRoutingTable.h
//  ulibmtp3
//
//  Created by Andreas Fink on 26.01.17.
//  Copyright © 2017 Andreas Fink. All rights reserved.
//

#import <ulib/ulib.h>
#import "UMMTP3RoutingTable.h"

/* in comparison to the instance routing table, the link routing table
 can have only one entry per pointcode. Hence its a
 UMSychronizedSortedDictionary of
 UMMTP3Route objects
 The  key is the pointcode's stringValue
 */

@interface UMMTP3LinkRoutingTable : UMMTP3RoutingTable
{
    UMSynchronizedDictionary *routesByPointCode;
}


@end
