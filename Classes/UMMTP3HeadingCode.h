//
//  UMMTP3HeadingCode.h
//  ulibmtp3
//
//  Created by Andreas Fink on 05/12/14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#define	MTP3_SERVICE_INDICATOR_MGMT				0x00
#define	MTP3_SERVICE_INDICATOR_TEST				0x01
#define	MTP3_SERVICE_INDICATOR_MAINTENANCE_SPECIAL_MESSAGE  0x02 /* ANSI only */
#define	MTP3_SERVICE_INDICATOR_SCCP				0x03
#define	MTP3_SERVICE_INDICATOR_TUP				0x04
#define	MTP3_SERVICE_INDICATOR_ISUP				0x05
#define	MTP3_SERVICE_INDICATOR_DUP_C			0x06
#define	MTP3_SERVICE_INDICATOR_DUP_F			0x07
#define	MTP3_SERVICE_INDICATOR_RES_TESTING		0x08
#define	MTP3_SERVICE_INDICATOR_BROADBAND_ISUP   0x09
#define	MTP3_SERVICE_INDICATOR_SAT_ISUP         0x0A
#define	MTP3_SERVICE_INDICATOR_SPARE_B			0x0B
#define	MTP3_SERVICE_INDICATOR_SPARE_C			0x0C
#define	MTP3_SERVICE_INDICATOR_SPARE_D			0x0D
#define	MTP3_SERVICE_INDICATOR_SPARE_E			0x0E
#define	MTP3_SERVICE_INDICATOR_SPARE_F			0x0F

#define MTP3_ANSI_SERVICE_INDICATOR_TEST        0x02

/*
#define	MTP3_TESTING_REQUEST				0x00
#define	MTP3_TESTING_ACCEPTANCE				0x01
#define	MTP3_TESTING_REFUSAL				0x02
#define	MTP3_TESTING_TERMINATION_REQUEST	0x03
#define	MTP3_TESTING_TERMINATION_ACK		0x04
*/
#define	MTP3_TESTING_SLTM                   0x11	/* signalling link test message */
#define	MTP3_TESTING_SLTA                   0x21	/* signalling link test message */

#define	MTP3_ANSI_TESTING_SSLTM                   0x11	/* signalling link test message */
#define	MTP3_ANSI_TESTING_SSLTA                   0x21	/* signalling link test message */

#define MTP3_MGMT_COO   0x11    /* signalling link test message */
#define MTP3_MGMT_COA   0x21    /* signalling link test message */
#define MTP3_MGMT_CBD   0x51    /* Changeback Declaration */
#define MTP3_MGMT_CBA   0x61    /* Changeback acknowledgement */
#define MTP3_MGMT_ECO   0x12    /* Emergency Changeover Order */
#define MTP3_MGMT_ECA   0x22    /* Emergency Changeover Acknowledgement */
#define MTP3_MGMT_RCT   0x13    /* Signalling route set congesting test signal */
#define MTP3_MGMT_TFC   0x23    /* Transfer Controlled Signal */
#define MTP3_MGMT_TFP   0x14    /* Transfer Prohibited Signal */
#define MTP3_MGMT_TFR   0x34    /* Transfer Restricted (national option) */
#define MTP3_MGMT_TFA   0x54    /* Transfer Allowed */
#define MTP3_MGMT_RST   0x15    /* Signalling-route-set-test signal for prohibited destination */
#define MTP3_MGMT_RSR   0x25    /* Signalling-route-set-test signal for restricted destination (national option) */
#define MTP3_MGMT_LIN   0x16    /* Link inhibit signal */
#define MTP3_MGMT_LUN   0x26    /* Link uninhibit signal */
#define MTP3_MGMT_LIA   0x36    /* Link inhibit acknowledgement signal */
#define MTP3_MGMT_LUA   0x46    /* Link uninhibit acknowledgement signal */
#define MTP3_MGMT_LID   0x56    /* Link inhibit denied signal */
#define MTP3_MGMT_LFU   0x66    /* Link forced uninhibit signal */
#define MTP3_MGMT_LLT   0x76    /* Link local inhibit test signal */
#define MTP3_MGMT_LRT   0x86    /* Link remote inhibit test signal */
#define MTP3_MGMT_TRA   0x17    /* Traffic-restart-allowed signal */
#define MTP3_MGMT_DLC   0x18    /* Signalling-data-link-connection-order signal */
#define MTP3_MGMT_CSS   0x28    /* Connection-successful signal */
#define MTP3_MGMT_CNS   0x38    /* Connection-not-successful signal */
#define MTP3_MGMT_CNP   0x48    /* Connection-not-possible signal */
#define MTP3_MGMT_UPU   0x1A    /* User Part Unavailable */

#define MTP3_MGMT_TCP 	0x24    /* ANSI */
#define MTP3_MGMT_TRW 	0x27    /* ANSI */
#define MTP3_MGMT_TCR 	0x44    /* ANSI */
#define MTP3_MGMT_TCA 	0x64    /* ANSI */
#define MTP3_MGMT_RCP 	0x35    /* ANSI */
#define MTP3_MGMT_RCR 	0x45    /* ANSI */

#define MTP3_MGMT_UPA	0x2A    /* ANSI 91 only */
#define MTP3_MGMT_UPT	0x3A    /* ANSI 91 only */

