//
//  UMMTP3PointcodeFilter.h
//  ulibmtp3
//
//  Created by Andreas Fink on 21.04.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/ulib.h>
#import "UMMTP3PointCode.h"
#import "UMMTP3Filter_Result.h"

@interface UMMTP3PointcodeFilter : UMPlugin
{
    UMMTP3Variant _variant;
}

@property(readwrite,assign,atomic) UMMTP3Variant variant;

- (UMMTP3Filter_Result)filterPointcode:(UMMTP3PointCode *)pc;

@end
