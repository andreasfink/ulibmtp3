//
//  UMMTP3Filter_Result.h
//  ulibmtp3
//
//  Created by Andreas Fink on 21.04.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

typedef enum UMMTP3Filter_Result
{
    UMMTP3Filter_Result_undefined   = 0, /* filter did not find any match */
    UMMTP3Filter_Result_allow       = 1, /* filter has a "ALLOW" match    */
    UMMTP3Filter_Result_deny        = -1, /* filter has a "DENY" match    */
} UMMTP3Filter_Result;

