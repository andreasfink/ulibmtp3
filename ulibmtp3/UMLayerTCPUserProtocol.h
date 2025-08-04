//
//  UMLayerTCPUserProtocol.h
//  ulibmtp3
//
//  Created by Andreas Fink on 21.07.2025.
//  Copyright © 2025 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/ulib.h>

@protocol UMLayerTCPUserProtocol_h<UMLayerUserProtocol>

- (NSString *)layerName;
- (NSString *)layerType;

- (void) tcpStatusIndication:(UMLayer *)caller
                       userId:(id)uid
                       status:(UMSocketStatus)s
                       reason:(NSString *)reason
                       socket:(NSNumber *)socket;

- (void) tcpDataIndication:(UMLayer *)caller
                     userId:(id)uid
                   streamId:(uint16_t)sid
                 protocolId:(uint32_t)pid
                       data:(NSData *)d
                     socket:(NSNumber *)socket;

- (void) tcpMonitorIndication:(UMLayer *)caller
                        userId:(id)uid
                      streamId:(uint16_t)sid
                    protocolId:(uint32_t)pid
                          data:(NSData *)d
                      incoming:(BOOL)in
                        socket:(NSNumber *)socket;

- (void) adminAttachConfirm:(UMLayer *)attachedLayer
                     userId:(id)uid;

- (void) adminAttachFail:(UMLayer *)attachedLayer
                  userId:(id)uid
                  reason:(NSString *)reason;

- (void) adminDetachConfirm:(UMLayer *)attachedLayer
                     userId:(id)uid;

- (void) adminDetachFail:(UMLayer *)attachedLayer
                  userId:(id)uid
                  reason:(NSString *)reason;

- (void)sentAckConfirmFrom:(UMLayer *)sender
                  userInfo:(NSDictionary *)userInfo;

- (void)sentAckFailureFrom:(UMLayer *)sender
                  userInfo:(NSDictionary *)userInfo
                     error:(NSString *)err
                    reason:(NSString *)reason
                 errorInfo:(NSDictionary *)ei;


@end
