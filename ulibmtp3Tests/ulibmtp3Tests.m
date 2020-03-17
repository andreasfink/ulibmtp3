//
//  ulibmtp3Tests.m
//  ulibmtp3Tests
//
//  Created by Andreas Fink on 05/09/14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import <XCTest/XCTest.h>
#import "UMMTP3InstanceRoute.h"

@interface ulibmtp3Tests : XCTestCase

@end

@implementation ulibmtp3Tests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testRoutingPreference
{
    UMMTP3InstanceRoute *a = [[UMMTP3InstanceRoute alloc]init];
    UMMTP3InstanceRoute *b = [[UMMTP3InstanceRoute alloc]init];
    a.status = UMMTP3_ROUTE_PROHIBITED;
    b.status = UMMTP3_ROUTE_ALLOWED;

    NSArray *arr = @[a,b];
    NSArray *arr2 = [arr sortedArrayUsingSelector:@selector(routingPreference:)];
    UMMTP3InstanceRoute *choosenRoute = arr2[arr2.count-1];
    XCTAssert(choosenRoute==b,@"coosen route must be b");
}

- (void)testRoutingPreference2
{
    UMMTP3InstanceRoute *a = [[UMMTP3InstanceRoute alloc]init];
    UMMTP3InstanceRoute *b = [[UMMTP3InstanceRoute alloc]init];
    a.status = UMMTP3_ROUTE_ALLOWED;
    b.status = UMMTP3_ROUTE_PROHIBITED;

    NSArray *arr = @[a,b];
    NSArray *arr2 = [arr sortedArrayUsingSelector:@selector(routingPreference:)];
    UMMTP3InstanceRoute *choosenRoute = arr2[arr2.count-1];
    XCTAssert(choosenRoute==a,@"coosen route must be a");
}


- (void)testRoutingPreference3
{
    UMMTP3InstanceRoute *a = [[UMMTP3InstanceRoute alloc]init];
    UMMTP3InstanceRoute *b = [[UMMTP3InstanceRoute alloc]init];
    a.status = UMMTP3_ROUTE_ALLOWED;
    a.priority = 5;
    b.status = UMMTP3_ROUTE_ALLOWED;
    b.priority = 1;


    NSArray *arr = @[a,b];
    NSArray *arr2 = [arr sortedArrayUsingSelector:@selector(routingPreference:)];
    UMMTP3InstanceRoute *choosenRoute = arr2[arr2.count-1];
    XCTAssert(choosenRoute==b,@"coosen route must be b");
}

- (void)testRoutingPreference4
{
    UMMTP3InstanceRoute *a = [[UMMTP3InstanceRoute alloc]init];
    UMMTP3InstanceRoute *b = [[UMMTP3InstanceRoute alloc]init];
    a.status = UMMTP3_ROUTE_ALLOWED;
    a.priority = 1;
    b.status = UMMTP3_ROUTE_ALLOWED;
    b.priority = 5;


    NSArray *arr = @[a,b];
    NSArray *arr2 = [arr sortedArrayUsingSelector:@selector(routingPreference:)];
    UMMTP3InstanceRoute *choosenRoute = arr2[arr2.count-1];
    XCTAssert(choosenRoute==a,@"coosen route must be a");
}

@end

