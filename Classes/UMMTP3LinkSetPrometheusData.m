//
//  UMMTP3LinkSetPrometheusData.m
//  ulibmtp3
//
//  Created by Andreas Fink on 22.06.21.
//  Copyright © 2021 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMMTP3LinkSetPrometheusData.h"

@implementation UMMTP3LinkSetPrometheusData

- (UMMTP3LinkSetPrometheusData *)initWithPrometheus:(UMPrometheus *)p linksetName:(NSString *)name
{
    self = [super init];
    if(self)
{
    _linksetName = name;
    _prometheus = p;
    _linkUpCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-up-count"
                                                        subname1:@"linkset"
                                                       subvalue1:_linksetName
                                                            type:UMPrometheusMetricType_counter];
    _linkDownCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-down-count"
                                                          subname1:@"linkset"
                                                         subvalue1:_linksetName
                                                              type:UMPrometheusMetricType_counter];
    _linksAvailableGauge = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-links-available-count"
                                                                subname1:@"linkset"
                                                               subvalue1:_linksetName
                                                                    type:UMPrometheusMetricType_gauge];
    
    _sltmTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-sltm-tx-count"
                                                        subname1:@"linkset"
                                                       subvalue1:_linksetName
                                                            type:UMPrometheusMetricType_counter];
        _sltaTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-slta-tx-count"
                                                            subname1:@"linkset"
                                                           subvalue1:_linksetName
                                                                type:UMPrometheusMetricType_counter];
        _ssltmTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-ssltm-tx-count"
                                                             subname1:@"linkset"
                                                            subvalue1:_linksetName
                                                                 type:UMPrometheusMetricType_counter];
        _ssltaTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-sslta-tx-count"
                                                             subname1:@"linkset"
                                                            subvalue1:_linksetName
                                                                 type:UMPrometheusMetricType_counter];
        _cooTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-coo-tx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _coaTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-coa-tx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _xcoTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-xco-tx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _xcaTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-xca-tx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _cbdTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-cbd-tx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _cbaTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-cba-tx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _ecoTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-eco-tx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _ecaTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-eca-tx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _rctTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-rct-tx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _tfcTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-tfc-tx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _tfpTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-tfp-tx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _tfrTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-tfr-tx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _tfaTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-tfa-tx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _rstTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-rst-tx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _rsrTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-rsr-tx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _linTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-lin-tx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _lunTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-lun-tx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _liaTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-lia-tx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _luaTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-lua-tx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _lidTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-lid-tx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _lfuTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-lfu-tx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _lltTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-llt-tx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _lrtTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-lrt-tx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _traTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-tra-tx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _dlcTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-dlc-tx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _cssTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-css-tx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _cnsTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-cns-tx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _cnpTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-cnp-tx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _upuTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-upu-tx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _tcpTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-tcp-tx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _trwTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-trw-tx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _tcrTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-tcr-tx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _tcaTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-tca-tx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _rcpTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-rcp-tx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _rcrTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-rcr-tx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _upaTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-upa-tx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _uptTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-upt-tx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _sltmRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-sltm-rx-count"
                                                            subname1:@"linkset"
                                                           subvalue1:_linksetName
                                                                type:UMPrometheusMetricType_counter];
        _sltaRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-slta-rx-count"
                                                            subname1:@"linkset"
                                                           subvalue1:_linksetName
                                                                type:UMPrometheusMetricType_counter];
        _ssltmRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-ssltm-rx-count"
                                                             subname1:@"linkset"
                                                            subvalue1:_linksetName
                                                                 type:UMPrometheusMetricType_counter];
        _ssltaRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-sslta-rx-count"
                                                             subname1:@"linkset"
                                                            subvalue1:_linksetName
                                                                 type:UMPrometheusMetricType_counter];
        _cooRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-coo-rx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                                type:UMPrometheusMetricType_counter];
        _coaRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-coa-rx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _xcoRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-xco-rx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _xcaRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-xca-rx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _cbdRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-cbd-rx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _cbaRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-cba-rx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _ecoRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-eco-rx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _ecaRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-eca-rx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _rctRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-rct-rx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _tfcRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-tfc-rx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _tfpRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-tfp-rx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _tfrRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-tfr-rx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _tfaRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-tfa_rx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _rstRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-rst-rx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _rsrRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-rsr-rx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _linRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-lin-rx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _lunRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-lun-rx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _liaRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-lia-rx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _luaRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-lua-rx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _lidRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-lid-rx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _lfuRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-lfu-rx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _lltRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-llt-rx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _lrtRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-lrt-rx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _traRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-tra-rx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _dlcRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-dlc-rx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _cssRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-css-rx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _cnsRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-cns-rx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _cnpRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-cnp-rx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _upuRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-upu-rx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _tcpRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-tcp-rxcount"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _trwRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-trw-rx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _tcrRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-tcr-rx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _tcaRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-tca-rx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _rcpRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-rcp-rx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _rcrRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-rcr-rx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _upaRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-upa-rx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _uptRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-upt-rx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _msuRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-msu-rx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _msuTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-msu-tx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _sccpTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-sccp-tx-count"
                                                            subname1:@"linkset"
                                                           subvalue1:_linksetName
                                                                type:UMPrometheusMetricType_counter];
        _sccpRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-sccp-rx-count"
                                                            subname1:@"linkset"
                                                           subvalue1:_linksetName
                                                                type:UMPrometheusMetricType_counter];
        _tupTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-tup-tx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _tupRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-tup-rx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _isupTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-isup-tx-count"
                                                            subname1:@"linkset"
                                                           subvalue1:_linksetName
                                                                type:UMPrometheusMetricType_counter];
        _isupRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-isup-rx-count"
                                                            subname1:@"linkset"
                                                           subvalue1:_linksetName
                                                                type:UMPrometheusMetricType_counter];
        _bisupTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-bisup-tx-count"
                                                             subname1:@"linkset"
                                                            subvalue1:_linksetName
                                                                 type:UMPrometheusMetricType_counter];
        _bisupRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-bisup-rx-count"
                                                             subname1:@"linkset"
                                                            subvalue1:_linksetName
                                                                 type:UMPrometheusMetricType_counter];
        _sisupTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-sisup-tx-count"
                                                             subname1:@"linkset"
                                                            subvalue1:_linksetName
                                                                 type:UMPrometheusMetricType_counter];
        _sisupRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-sisup-rx-count"
                                                             subname1:@"linkset"
                                                            subvalue1:_linksetName
                                                                 type:UMPrometheusMetricType_counter];
        _dupcRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-dupc-rx-count"
                                                            subname1:@"linkset"
                                                           subvalue1:_linksetName
                                                                type:UMPrometheusMetricType_counter];
        _dupcTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-dupc-tx-count"
                                                            subname1:@"linkset"
                                                           subvalue1:_linksetName
                                                                type:UMPrometheusMetricType_counter];
        _dupfRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-dupf-rx-count"
                                                            subname1:@"linkset"
                                                           subvalue1:_linksetName
                                                                type:UMPrometheusMetricType_counter];
        _dupfTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-dupf-tx-count"
                                                            subname1:@"linkset"
                                                           subvalue1:_linksetName
                                                                type:UMPrometheusMetricType_counter];
        _resRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-res-rx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _resTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-res-tx-count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _sparecRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-sparec-rx-count"
                                                              subname1:@"linkset"
                                                             subvalue1:_linksetName
                                                                  type:UMPrometheusMetricType_counter];
        _sparecTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-sparec-tx-count"
                                                              subname1:@"linkset"
                                                             subvalue1:_linksetName
                                                                  type:UMPrometheusMetricType_counter];
        _sparedRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-spared-rx-count"
                                                              subname1:@"linkset"
                                                             subvalue1:_linksetName
                                                                  type:UMPrometheusMetricType_counter];
        _sparedTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-spared-tx-count"
                                                              subname1:@"linkset"
                                                             subvalue1:_linksetName
                                                                  type:UMPrometheusMetricType_counter];
        _spareeRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-sparee-rx-count"
                                                              subname1:@"linkset"
                                                             subvalue1:_linksetName
                                                                  type:UMPrometheusMetricType_counter];
        _spareeTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-sparee-tx-count"
                                                              subname1:@"linkset"
                                                             subvalue1:_linksetName
                                                                  type:UMPrometheusMetricType_counter];
        _sparefRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-sparef-rx-count"
                                                              subname1:@"linkset"
                                                             subvalue1:_linksetName
                                                                  type:UMPrometheusMetricType_counter];
        _sparefTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3-linkset-sparef-tx-count"
                                                              subname1:@"linkset"
                                                             subvalue1:_linksetName
                                                                  type:UMPrometheusMetricType_counter];
        _msuRxThroughput = [[UMPrometheusThroughputMetric alloc]initWithResolutionInSeconds:10.0
                                                                         reportDuration:10.0
                                                                                   name:@"mtp3-linkset-msu-Rx-throughput"
                                                                               subname1:@"linkset"
                                                                              subvalue1:_linksetName];
        _msuTxThroughput = [[UMPrometheusThroughputMetric alloc]initWithResolutionInSeconds:10.0
                                                                             reportDuration:10.0
                                                                                       name:@"mtp3-linkset-msu-tx-throughput"
                                                                                   subname1:@"linkset"
                                                                                  subvalue1:_linksetName];
    }
    return self;
}
@end
