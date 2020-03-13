//
//  UMLayerMTP3UserProtocol.h
//  ulibmtp3
//
//  Created by Andreas Fink on 04/12/14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import <ulib/ulib.h>
#import <ulib/ulib.h>
#import <ulibm2pa/ulibm2pa.h>

@class UMMTP3TranslationTableMap;

/* defines the methods a layer must implement if it uses MTP3. The callbacks MTP3 sends to it */
@protocol UMLayerMTP3UserProtocol<UMLayerUserProtocol>

- (void)mtpTransfer:(NSData *)data
       callingLayer:(id)mtp3Layer
                opc:(UMMTP3PointCode *)opc
                dpc:(UMMTP3PointCode *)dpc
                 si:(int)si
                 ni:(int)ni
        linksetName:(NSString *)linksetName
            options:(NSDictionary *)options
              ttmap:(UMMTP3TranslationTableMap *)map;

- (void)mtpPause:(NSData *)data
    callingLayer:(id)mtp3Layer
      affectedPc:(UMMTP3PointCode *)opc
              si:(int)si
              ni:(int)ni
         options:(NSDictionary *)options;

- (void)mtpResume:(NSData *)data
     callingLayer:(id)mtp3Layer
       affectedPc:(UMMTP3PointCode *)opc
               si:(int)si
               ni:(int)ni
          options:(NSDictionary *)options;


- (void)mtpStatus:(NSData *)data
     callingLayer:(id)mtp3Layer
       affectedPc:(UMMTP3PointCode *)affPC
               si:(int)si
               ni:(int)ni
           status:(int)status
          options:(NSDictionary *)options;

@end
