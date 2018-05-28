//
//  UMLayerMTP3ApplicationContextProtocol.h
//  ulibmtp3
//
//  Created by Andreas Fink on 24.01.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <Foundation/Foundation.h>

@class UMLayerMTP3;
@class UMLayerM2PA;
@class UMMTP3Link;
@class UMMTP3LinkSet;
@class UMM3UAApplicationServerProcess;
@class UMM3UAApplicationServer;
@class UMLayerSctp;

@protocol UMLayerMTP3ApplicationContextProtocol<NSObject>

- (UMLayerSctp *)getSCTP:(NSString *)name;
- (UMLayerMTP3 *)getMTP3:(NSString *)name;
- (UMLayerM2PA *)getM2PA:(NSString *)name;
- (UMMTP3Link *)getMTP3_Link:(NSString *)name;
- (UMMTP3LinkSet *)getMTP3_LinkSet:(NSString *)name;
- (UMM3UAApplicationServerProcess *)getM3UA_ASP:(NSString *)name;
- (UMM3UAApplicationServer *)getM3UA_AS:(NSString *)name;

@end
