//
//  UMSyntaxToken_Pointcode.m
//  ulibcommand
//
//  Created by Andreas Fink on 26.02.17.
//  Copyright © 2017 Andreas Fink. All rights reserved.
//

#import "UMSyntaxToken_Pointcode.h"

@implementation UMSyntaxToken_Pointcode


- (BOOL) matchesValue:(NSString *)value withPriority:(int)prio
{
    if(prio == UMSYNTAX_PRIORITY_NAME)
    {
        return YES;
    }
    return NO;
}

@end
