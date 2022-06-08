//
//  mtp3routeTests.m
//  ulibmtp3Tests
//
//  Created by Andreas Fink on 18.12.2019.
//  Copyright © 2019 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <XCTest/XCTest.h>
#import <ulibmtp3/ulibmtp3.h>

@interface mtp3routeTests : XCTestCase
{
    UMLayerMTP3 *_mtp3;
    UMMTP3LinkSet *_linkset1;
    UMMTP3LinkSet *_linkset2;
    UMMTP3LinkSet *_linkset3;
    UMMTP3LinkSet *_linkset4;
    UMMTP3LinkSet *_linkset5;
    UMMTP3PointCode *_pc101;
    UMMTP3PointCode *_pc102;
    UMMTP3PointCode *_pc103;

}
@end

@implementation mtp3routeTests

- (void)setUp
{
    _mtp3 = [[UMLayerMTP3 alloc]init];
    _pc101 = [[UMMTP3PointCode alloc]initWithPc:101 variant:UMMTP3Variant_ITU];
    _pc102 = [[UMMTP3PointCode alloc]initWithPc:102 variant:UMMTP3Variant_ITU];
    _pc103 = [[UMMTP3PointCode alloc]initWithPc:103 variant:UMMTP3Variant_ITU];

    _linkset1 = [[UMMTP3LinkSet alloc]init];
    _linkset1.name = @"linkset101";
    _linkset1.mtp3 = _mtp3;
    _linkset1.linksByName = [[UMSynchronizedSortedDictionary alloc]init];
    _linkset1.linksBySlc = [[UMSynchronizedSortedDictionary alloc]init];
    _linkset1.adjacentPointCode = _pc101;
    
    _linkset2.name = @"linkset102";
    _linkset2.mtp3 = _mtp3;
    _linkset2.linksByName = [[UMSynchronizedSortedDictionary alloc]init];
    _linkset2.linksBySlc = [[UMSynchronizedSortedDictionary alloc]init];
    _linkset2.adjacentPointCode = _pc102;

    _linkset3.name = @"linkset103";
    _linkset3.mtp3 = _mtp3;
    _linkset3.linksByName = [[UMSynchronizedSortedDictionary alloc]init];
    _linkset3.linksBySlc = [[UMSynchronizedSortedDictionary alloc]init];
    _linkset3.adjacentPointCode = _pc103;

    [_mtp3 addLinkSet:_linkset1];
    [_mtp3 addLinkSet:_linkset2];
    [_mtp3 addLinkSet:_linkset3];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}
/*

- (void)testSingleRoute
{
    
    [_mtp3 updateRouteAvailable:_pc101 mask:14 linksetName:@"linkset101" priority:UMMTP3RoutePriority_5];

    UMMTP3RouteStatus s = [_mtp3.routingTable isRouteAvailable:_pc101 mask:14 linksetName:@"linkset101"];
    XCTAssert(UMMTP3_ROUTE_ALLOWED == s,@"route is not UMMTP3_ROUTE_ALLOWED but should be");
    
    [_mtp3 updateRouteUnavailable:_pc103 mask:14 linksetName:@"linkset101" priority:UMMTP3RoutePriority_5 reason:@"test"];
    s = [_mtp3.routingTable isRouteAvailable:_pc101 mask:14 linksetName:@"linkset101"];
    XCTAssert(UMMTP3_ROUTE_PROHIBITED == s,@"route is not UMMTP3_ROUTE_PROHIBITED but should be");

    [_mtp3 updateRouteAvailable:_pc101 mask:14 linksetName:@"linkset101" priority:UMMTP3RoutePriority_5];
    s = [_mtp3.routingTable isRouteAvailable:_pc101 mask:14 linksetName:@"linkset101"];
    XCTAssert(UMMTP3_ROUTE_ALLOWED == s,@"route is not UMMTP3_ROUTE_ALLOWED but should be");

    [_mtp3 updateRouteRestricted:_pc101 mask:14 linksetName:@"linkset101" priority:UMMTP3RoutePriority_5];
    s = [_mtp3.routingTable isRouteAvailable:_pc101 mask:14 linksetName:@"linkset101"];
    XCTAssert(UMMTP3_ROUTE_RESTRICTED == s,@"route is not UMMTP3_ROUTE_RESTRICTED but should be");

    [_mtp3 updateRouteAvailable:_pc101 mask:14 linksetName:@"linkset101" priority:UMMTP3RoutePriority_5];
    s = [_mtp3.routingTable isRouteAvailable:_pc101 mask:14 linksetName:@"linkset101"];
    XCTAssert(UMMTP3_ROUTE_ALLOWED == s,@"route is not UMMTP3_ROUTE_ALLOWED but should be");

}

- (void)testDirectAndIndirectRoute
{
    
    [_mtp3 updateRouteAvailable:_pc101 mask:14 linksetName:@"linkset101" priority:UMMTP3RoutePriority_5];
    [_mtp3 updateRouteAvailable:_pc102 mask:14 linksetName:@"linkset102" priority:UMMTP3RoutePriority_5];
    [_mtp3 updateRouteAvailable:_pc101 mask:14 linksetName:@"linkset102" priority:UMMTP3RoutePriority_7];

    UMMTP3RouteStatus s = [_mtp3.routingTable isRouteAvailable:_pc101 mask:14 linksetName:@"linkset102"];
    XCTAssert(UMMTP3_ROUTE_ALLOWED == s,@"route is not UMMTP3_ROUTE_ALLOWED but should be");
    
    [_mtp3 updateRouteUnavailable:_pc103 mask:14 linksetName:@"linkset101" priority:UMMTP3RoutePriority_5 reason:@"test"];
    s = [_mtp3.routingTable isRouteAvailable:_pc101 mask:14 linksetName:@"linkset101"];
    XCTAssert(UMMTP3_ROUTE_PROHIBITED == s,@"route is not UMMTP3_ROUTE_PROHIBITED but should be");

    [_mtp3 updateRouteAvailable:_pc101 mask:14 linksetName:@"linkset101" priority:UMMTP3RoutePriority_5];
    s = [_mtp3.routingTable isRouteAvailable:_pc101 mask:14 linksetName:@"linkset101"];
    XCTAssert(UMMTP3_ROUTE_ALLOWED == s,@"route is not UMMTP3_ROUTE_ALLOWED but should be");

    [_mtp3 updateRouteRestricted:_pc101 mask:14 linksetName:@"linkset101" priority:UMMTP3RoutePriority_5];
    s = [_mtp3.routingTable isRouteAvailable:_pc101 mask:14 linksetName:@"linkset101"];
    XCTAssert(UMMTP3_ROUTE_RESTRICTED == s,@"route is not UMMTP3_ROUTE_RESTRICTED but should be");

    [_mtp3 updateRouteAvailable:_pc101 mask:14 linksetName:@"linkset101" priority:UMMTP3RoutePriority_5];
    s = [_mtp3.routingTable isRouteAvailable:_pc101 mask:14 linksetName:@"linkset101"];
    XCTAssert(UMMTP3_ROUTE_ALLOWED == s,@"route is not UMMTP3_ROUTE_ALLOWED but should be");

}*/
@end
