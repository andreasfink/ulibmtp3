//
//  UMMTP3LinkSetPrometheusData.m
//  ulibmtp3
//
//  Created by Andreas Fink on 22.06.21.
//  Copyright © 2021 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMMTP3LinkSetPrometheusData.h"

@implementation UMMTP3LinkSetPrometheusData

- (UMMTP3LinkSetPrometheusData *)initWithPrometheus:(UMPrometheus *)p
                                        linksetName:(NSString *)name
                                             isM3UA:(BOOL)isM3UA
{
    self = [super init];
    if(self)
    {
        _linksetName = name;
        _prometheus = p;
        _isM3UA = isM3UA;
        
        /* general */
        _linkUpCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_up_count"
                                                            subname1:@"linkset"
                                                           subvalue1:_linksetName
                                                                type:UMPrometheusMetricType_counter];
        _linkUpCount.help = @"counter of linkset up events";
        
        _linkDownCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_down_count"
                                                              subname1:@"linkset"
                                                             subvalue1:_linksetName
                                                                  type:UMPrometheusMetricType_counter];
        _linkDownCount.help = @"counter of linkset down events";
        
        _linksAvailableGauge = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_links_available_count"
                                                                    subname1:@"linkset"
                                                                   subvalue1:_linksetName
                                                                        type:UMPrometheusMetricType_gauge];
        _linksAvailableGauge.help = @"count of available links in a  linkset";

        _msuRxThroughput = [[UMPrometheusThroughputMetric alloc]initWithResolutionInSeconds:0.1
                                                                         reportDuration:10.0
                                                                                   name:@"mtp3_linkset_msu_rx_throughput"
                                                                               subname1:@"linkset"
                                                                              subvalue1:_linksetName];
        _msuRxThroughput.help = @"throughput of received MSU";
        _msuTxThroughput = [[UMPrometheusThroughputMetric alloc]initWithResolutionInSeconds:0.1
                                                                             reportDuration:10.0
                                                                                       name:@"mtp3_linkset_msu_tx_throughput"
                                                                                   subname1:@"linkset"
                                                                                  subvalue1:_linksetName];
        _msuTxThroughput.help = @"throughput of sent MSU";

        _msuRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_msu_rx_count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _msuRxCount.help = @"count of received MSU packets";
        
        _msuTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_msu_tx_count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _msuTxCount.help = @"count of sent MSU";
        
        _sccpTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_sccp_tx_count"
                                                            subname1:@"linkset"
                                                           subvalue1:_linksetName
                                                                type:UMPrometheusMetricType_counter];
        _sccpTxCount.help = @"count of sent SCCP packets";
        
        _sccpRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_sccp_rx_count"
                                                            subname1:@"linkset"
                                                           subvalue1:_linksetName
                                                                type:UMPrometheusMetricType_counter];
        _sccpRxCount.help = @"count of received SCCP packets";
        
        _tupTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_tup_tx_count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _tupTxCount.help = @"count of sent TUP packets";
        
        _tupRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_tup_rx_count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _tupRxCount.help = @"count of received TUP packets";
        
        
        _isupTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_isup_tx_count"
                                                            subname1:@"linkset"
                                                           subvalue1:_linksetName
                                                                type:UMPrometheusMetricType_counter];
        _isupTxCount.help = @"count of sent ISUP packets";
        
        _isupRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_isup_rx_count"
                                                            subname1:@"linkset"
                                                           subvalue1:_linksetName
                                                                type:UMPrometheusMetricType_counter];
        _isupRxCount.help = @"count of received ISUP packets";
        
        
        _bisupTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_bisup_tx_count"
                                                             subname1:@"linkset"
                                                            subvalue1:_linksetName
                                                                 type:UMPrometheusMetricType_counter];
        _bisupTxCount.help = @"count of sent BROADBAND_ISUP packets";
        
        _bisupRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_bisup_rx_count"
                                                             subname1:@"linkset"
                                                            subvalue1:_linksetName
                                                                 type:UMPrometheusMetricType_counter];
        _bisupRxCount.help = @"count of received BROADBAND_ISUP packets";
        
        _sisupTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_sisup_tx_count"
                                                             subname1:@"linkset"
                                                            subvalue1:_linksetName
                                                                 type:UMPrometheusMetricType_counter];
        _sisupTxCount.help = @"count of received SAT_ISUP packets";
        
        _sisupRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_sisup_rx_count"
                                                             subname1:@"linkset"
                                                            subvalue1:_linksetName
                                                                 type:UMPrometheusMetricType_counter];
        _sisupRxCount.help = @"count of received SAT_ISUP packets";
        
        _dupcRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_dupc_rx_count"
                                                            subname1:@"linkset"
                                                           subvalue1:_linksetName
                                                                type:UMPrometheusMetricType_counter];
        _dupcRxCount.help = @"count of received DUP_C packets";
        
        _dupcTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_dupc_tx_count"
                                                            subname1:@"linkset"
                                                           subvalue1:_linksetName
                                                                type:UMPrometheusMetricType_counter];
        _dupcTxCount.help = @"count of sent DUP_C packets";
        
        _dupfRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_dupf_rx_count"
                                                            subname1:@"linkset"
                                                           subvalue1:_linksetName
                                                                type:UMPrometheusMetricType_counter];
        _dupfRxCount.help = @"count of received DUP_F packets";
        
        _dupfTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_dupf_tx_count"
                                                            subname1:@"linkset"
                                                           subvalue1:_linksetName
                                                                type:UMPrometheusMetricType_counter];
        _dupfTxCount.help = @"count of sent DUP_F packets";
        
        _resRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_res_rx_count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _resRxCount.help = @"count of received RES packets";
        
        _resTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_res_tx_count"
                                                           subname1:@"linkset"
                                                          subvalue1:_linksetName
                                                               type:UMPrometheusMetricType_counter];
        _resTxCount.help = @"count of sent RES packets";

        _sparecRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_sparec_rx_count"
                                                              subname1:@"linkset"
                                                             subvalue1:_linksetName
                                                                  type:UMPrometheusMetricType_counter];
        _sparecRxCount.help = @"count of received Spare_C MTP3 payload";

        _sparecTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_sparec_tx_count"
                                                              subname1:@"linkset"
                                                             subvalue1:_linksetName
                                                                  type:UMPrometheusMetricType_counter];
        _sparecTxCount.help = @"count of sent Spare_C MTP3 payload";

        _sparedRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_spared_rx_count"
                                                              subname1:@"linkset"
                                                             subvalue1:_linksetName
                                                                  type:UMPrometheusMetricType_counter];
        _sparedRxCount.help = @"count of received Spare_D MTP3 payload";

        _sparedTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_spared_tx_count"
                                                              subname1:@"linkset"
                                                             subvalue1:_linksetName
                                                                  type:UMPrometheusMetricType_counter];
        _sparedTxCount.help = @"count of sent Spare_D MTP3 payload";

        _spareeRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_sparee_rx_count"
                                                              subname1:@"linkset"
                                                             subvalue1:_linksetName
                                                                  type:UMPrometheusMetricType_counter];
        _spareeRxCount.help = @"count of received Spare_E MTP3 payload";

        _spareeTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_sparee_tx_count"
                                                              subname1:@"linkset"
                                                             subvalue1:_linksetName
                                                                  type:UMPrometheusMetricType_counter];
        _spareeTxCount.help = @"count of sent Spare_E MTP3 payload";

        _sparefRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_sparef_rx_count"
                                                              subname1:@"linkset"
                                                             subvalue1:_linksetName
                                                                  type:UMPrometheusMetricType_counter];
        _sparefRxCount.help = @"count of recveived Spare_F MTP3 payload";

        _sparefTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_sparef_tx_count"
                                                              subname1:@"linkset"
                                                             subvalue1:_linksetName
                                                                  type:UMPrometheusMetricType_counter];
        _sparefTxCount.help = @"count of sent Spare_F MTP3 payload";

        _localRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_local_rx"
                                                             subname1:@"linkset"
                                                            subvalue1:_linksetName
                                                                 type:UMPrometheusMetricType_counter];
        _localRxCount.help = @"count of received MTP3 packets which are processed locally";

        _forwardRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_forward_rx"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
        _forwardRxCount.help = @"count of received MTP3 packets which are forwarded (MTP3 Transit)";

        /* M2PA */
        if(!_isM3UA)
        {
            _sltmTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_sltm_tx_count"
                                                                subname1:@"linkset"
                                                               subvalue1:_linksetName
                                                                    type:UMPrometheusMetricType_counter];
            _sltmTxCount.help = @"count of sent SLTM packets";
            _sltaTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_slta_tx_count"
                                                                subname1:@"linkset"
                                                               subvalue1:_linksetName
                                                                    type:UMPrometheusMetricType_counter];
            _sltaTxCount.help = @"count of sent SLTA packets";

            _ssltmTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_ssltm_tx_count"
                                                                 subname1:@"linkset"
                                                                subvalue1:_linksetName
                                                                     type:UMPrometheusMetricType_counter];
            _ssltmTxCount.help = @"count of sent SSLTM packets";

            _ssltaTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_sslta_tx_count"
                                                                 subname1:@"linkset"
                                                                subvalue1:_linksetName
                                                                     type:UMPrometheusMetricType_counter];
            _ssltaTxCount.help = @"count of sent SSLTA packets";

            _cooTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_coo_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _cooTxCount.help = @"count of sent CCO packets";

            _coaTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_coa_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _coaTxCount.help = @"count of sent COA packets";

            _xcoTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_xco_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _xcoTxCount.help = @"count of sent XCO packets";

            _xcaTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_xca_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _xcaTxCount.help = @"count of sent XCA packets";

            _cbdTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_cbd_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _cbdTxCount.help = @"count of sent CBD packets";

            _cbaTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_cba_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _cbaTxCount.help = @"count of sent CBA packets";

            _ecoTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_eco_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _ecoTxCount.help = @"count of sent ECO packets";

            _ecaTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_eca_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _ecaTxCount.help = @"count of sent ECA packets";
            
            _rctTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_rct_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _rctTxCount.help = @"count of sent RCT packets";
            
            _tfcTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_tfc_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _tfcTxCount.help = @"count of sent TFC packets";
            
            _tfpTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_tfp_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _tfpTxCount.help = @"count of sent TFP packets";
            
            _tfrTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_tfr_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _tfrTxCount.help = @"count of sent TFR packets";
            
            _tfaTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_tfa_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _tfaTxCount.help = @"count of sent TFA packets";
            
            _rstTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_rst_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _rstTxCount.help = @"count of sent RST packets";
            
            _rsrTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_rsr_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _rsrTxCount.help = @"count of sent RSR packets";
            
            _linTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_lin_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _linTxCount.help = @"count of sent LIN packets";

            _lunTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_lun_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _lunTxCount.help = @"count of sent LUN packets";
            
            _liaTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_lia_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _liaTxCount.help = @"count of sent LIA packets";
            
            _luaTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_lua_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _luaTxCount.help = @"count of sent LUA packets";
            
            _lidTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_lid_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _lidTxCount.help = @"count of sent LID packets";
            
            _lfuTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_lfu_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _lfuTxCount.help = @"count of sent LFU packets";
            
            _lltTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_llt_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _lltTxCount.help = @"count of sent LLT packets";
            
            _lrtTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_lrt_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _lrtTxCount.help = @"count of sent LTR packets";
            
            _traTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_tra_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _traTxCount.help = @"count of sent TRA packets";
            
            _dlcTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_dlc_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _dlcTxCount.help = @"count of sent DLC packets";
            
            _cssTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_css_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _cssTxCount.help = @"count of sent CSS packets";
            
            _cnsTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_cns_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _cnsTxCount.help = @"count of sent CNS packets";
            
            _cnpTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_cnp_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _cnpTxCount.help = @"count of sent CNP packets";
            
            _upuTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_upu_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _upuTxCount.help = @"count of sent UPU packets";
            
            _tcpTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_tcp_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _tcpTxCount.help = @"count of sent TCP packets";
            
            _trwTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_trw_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _trwTxCount.help = @"count of sent TRW packets";
            
            _tcrTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_tcr_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _tcrTxCount.help = @"count of sent TCR packets";
            
            _tcaTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_tca_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _tcaTxCount.help = @"count of sent TCA packets";
            
            _rcpTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_rcp_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _rcpTxCount.help = @"count of sent RCP packets";

            _rcrTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_rcr_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _rcrTxCount.help = @"count of sent RCR packets";
            
            _upaTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_upa_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _upaTxCount.help = @"count of sent UPA packets";
            
            _uptTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_upt_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _uptTxCount.help = @"count of sent UPT packets";
            
            
            _sltmRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_sltm_rx_count"
                                                                subname1:@"linkset"
                                                               subvalue1:_linksetName
                                                                    type:UMPrometheusMetricType_counter];
            _sltmRxCount.help = @"count of received SLTM packets";
            
            _sltaRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_slta_rx_count"
                                                                subname1:@"linkset"
                                                               subvalue1:_linksetName
                                                                    type:UMPrometheusMetricType_counter];
            _sltaRxCount.help = @"count of received SLTM packets";
            
            _ssltmRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_ssltm_rx_count"
                                                                 subname1:@"linkset"
                                                                subvalue1:_linksetName
                                                                     type:UMPrometheusMetricType_counter];
            _ssltmRxCount.help = @"count of received SSLTM packets";
            
            _ssltaRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_sslta_rx_count"
                                                                 subname1:@"linkset"
                                                                subvalue1:_linksetName
                                                                     type:UMPrometheusMetricType_counter];
            _ssltaRxCount.help = @"count of received SSLTA packets";
            
            _cooRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_coo_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                    type:UMPrometheusMetricType_counter];
            _cooRxCount.help = @"count of received COO packets";
            
            _coaRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_coa_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _coaRxCount.help = @"count of received COA packets";
            
            _xcoRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_xco_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _xcoRxCount.help = @"count of received XCO packets";
            
            _xcaRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_xca_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _xcaRxCount.help = @"count of received XCA packets";
            
           _cbdRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_cbd_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _cbdRxCount.help = @"count of received CBD packets";
            
            _cbaRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_cba_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _cbaRxCount.help = @"count of received CBA packets";
            
            _ecoRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_eco_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _ecoRxCount.help = @"count of received ECO packets";
            
            _ecaRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_eca_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _ecaRxCount.help = @"count of received ECA packets";
            
            _rctRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_rct_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _rctRxCount.help = @"count of received RCT packets";
            
            _tfcRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_tfc_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _tfcRxCount.help = @"count of received TFC packets";
            
            _tfpRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_tfp_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _tfpRxCount.help = @"count of received TFP packets";
            
            _tfrRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_tfr_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _tfrRxCount.help = @"count of received TFR packets";
            
            _tfaRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_tfa_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _tfaRxCount.help = @"count of received TFA packets";
            
            _rstRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_rst_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _rstRxCount.help = @"count of received RST packets";
            
            _rsrRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_rsr_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _rsrRxCount.help = @"count of received RSR packets";
            
            _linRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_lin_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _linRxCount.help = @"count of received LIN packets";
            
            _lunRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_lun_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _lunRxCount.help = @"count of received LUN packets";
            
            _liaRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_lia_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _liaRxCount.help = @"count of received LIA packets";
            
            _luaRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_lua_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _luaRxCount.help = @"count of received LUA packets";
            
            
            _lidRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_lid_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _lidRxCount.help = @"count of received LID packets";
            
            _lfuRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_lfu_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _lfuRxCount.help = @"count of received LFU packets";
            
            _lltRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_llt_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _lltRxCount.help = @"count of received LLT packets";
            
            _lrtRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_lrt_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _lrtRxCount.help = @"count of received LTR packets";
            
            _traRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_tra_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _traRxCount.help = @"count of received TRA packets";
            
            _dlcRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_dlc_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _dlcRxCount.help = @"count of received DLC packets";
            
            _cssRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_css_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _cssRxCount.help = @"count of received CSS packets";
            
            _cnsRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_cns_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _cnsRxCount.help = @"count of received CNS packets";
            
            _cnpRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_cnp_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _cnpRxCount.help = @"count of received CNP packets";
            
            _upuRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_upu_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _upuRxCount.help = @"count of received UPU packets";
            
            _tcpRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_tcp__rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _tcpRxCount.help = @"count of received TCP packets";
            
            _trwRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_trw_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _trwRxCount.help = @"count of received TWR packets";
            
            _tcrRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_tcr_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _tcrRxCount.help = @"count of received TCR packets";
            
            _tcaRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_tca_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _tcaRxCount.help = @"count of received TCA packets";
            
            _rcpRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_rcp_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _rcpRxCount.help = @"count of received RCP packets";
            
            _rcrRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_rcr_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _rcrRxCount.help = @"count of received RCR packets";
            
            _upaRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_upa_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _upaRxCount.help = @"count of received UPA packets";
            
            _uptRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"mtp3_linkset_upt_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _uptRxCount.help = @"count of received UPT packets";
        }
        else
        {
            _m3ua_errTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"m3ua_err_tx_count"
                                                                    subname1:@"linkset"
                                                                   subvalue1:_linksetName
                                                                        type:UMPrometheusMetricType_counter];
            _m3ua_errTxCount.help = @"count of sent ERR packets";

            _m3ua_errRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"m3ua_err_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _m3ua_errRxCount.help = @"count of received ERR packets";

            _m3ua_ntfyRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"m3ua_ntfy_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _m3ua_ntfyRxCount.help = @"count of receive NTFY packets";

            _m3ua_ntfyTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"m3ua_ntfy_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _m3ua_ntfyTxCount.help = @"count of sent NTFY packets";

            _m3ua_dataTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"m3ua_data_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _m3ua_dataTxCount.help = @"count of sent DATA packets";

            _m3ua_dataRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"m3ua_data_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _m3ua_dataRxCount.help = @"count of received DATA packets";

            _m3ua_dunaTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"m3ua_duna_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _m3ua_dunaTxCount.help = @"count of sent DUNA packets";

            _m3ua_dunaRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"m3ua_duna_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _m3ua_dunaRxCount.help = @"count of received DUNA packets";

            _m3ua_davaTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"m3ua_dava_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _m3ua_davaTxCount.help = @"count of sent DAVA packets";

            _m3ua_davaRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"m3ua_dava_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _m3ua_davaRxCount.help = @"count of received DAVA packets";

            _m3ua_daudTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"m3ua_daud_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _m3ua_daudTxCount.help = @"count of sent DAUD packets";

            _m3ua_daudRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"m3ua_daud_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _m3ua_daudRxCount.help = @"count of received DAUD packets";

            _m3ua_sconTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"m3ua_scon_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _m3ua_sconTxCount.help = @"count of sent SCON packets";

            _m3ua_sconRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"m3ua_scon_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _m3ua_sconRxCount.help = @"count of received SCON packets";

            _m3ua_dupuTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"m3ua_dupu_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _m3ua_dupuTxCount.help = @"count of sent DUPU packets";

            _m3ua_dupuRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"m3ua_dupu_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _m3ua_dupuRxCount.help = @"count of received DUPU packets";

            _m3ua_drstTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"m3ua_drst_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _m3ua_drstTxCount.help = @"count of sent DRST packets";

            _m3ua_drstRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"m3ua_drst_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _m3ua_drstRxCount.help = @"count of received DRST packets";

            _m3ua_aspupTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"m3ua_aspup_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _m3ua_aspupTxCount.help = @"count of sent ASPUP packets";

            _m3ua_aspupRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"m3ua_aspup_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _m3ua_aspupRxCount.help = @"count of sent ASPUP packets";

            _m3ua_apsdnTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"m3ua_apsdn_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _m3ua_apsdnTxCount.help = @"count of sent ASPDN packets";

            _m3ua_apsdnRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"m3ua_apsdn_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _m3ua_apsdnRxCount.help = @"count of received ASPDN packets";

            _m3ua_beatTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"m3ua_beat_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _m3ua_beatTxCount.help = @"count of sent BEAT packets";

            _m3ua_beatRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"m3ua_beat_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _m3ua_beatRxCount.help = @"count of received BEAT packets";

            _m3ua_aspupackTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"m3ua_aspupack_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _m3ua_aspupackTxCount.help = @"count of sent ASPUP_ACK packets";

            _m3ua_aspupackRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"m3ua_aspupack_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _m3ua_aspupackRxCount.help = @"count of received ASPUP_ACK packets";

            _m3ua_aspdnackTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"m3ua_aspdnack_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _m3ua_aspdnackTxCount.help = @"count of sent ASPDN_ACK packets";

            _m3ua_aspdnackRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"m3ua_aspdnack_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _m3ua_aspdnackRxCount.help = @"count of received ASPDN_ACK packets";

            _m3ua_beatackTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"m3ua_beatack_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _m3ua_beatackTxCount.help = @"count of sent BEAT_ACK packets";

            _m3ua_beatackRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"m3ua_beatack_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _m3ua_beatackRxCount.help = @"count of received BEAT_ACK packets";

            _m3ua_aspacTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"m3ua_aspac_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _m3ua_aspacTxCount.help = @"count of sent ASPAC packets";

            _m3ua_aspacRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"m3ua_aspac_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _m3ua_aspacRxCount.help = @"count of received ASPAC packets";

            _m3ua_aspiaTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"m3ua_aspia_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _m3ua_aspiaTxCount.help = @"count of sent ASPIA packets";

            _m3ua_aspiaRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"m3ua_aspia_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _m3ua_aspiaRxCount.help = @"count of received ASPIA packets";

            _m3ua_aspacackTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"m3ua_aspacack_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _m3ua_aspacackTxCount.help = @"count of sent ASPAC_ACK packets";

            _m3ua_aspacackRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"m3ua_aspacack_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _m3ua_aspacackRxCount.help = @"count of received ASPAC_ACK packets";

            _m3ua_regreqTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"m3ua_regreq_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _m3ua_regreqTxCount.help = @"count of sent REGREQ packets";

            _m3ua_regreqRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"m3ua_regreq_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _m3ua_regreqRxCount.help = @"count of received REGREQ packets";

            _m3ua_regrspTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"m3ua_regrsp_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _m3ua_regrspTxCount.help = @"count of sent REGRSP packets";

            _m3ua_regrspRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"m3ua_regrsp_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _m3ua_regrspRxCount.help = @"count of received REGRSP packets";

            _m3ua_deregreqTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"m3ua_deregreq_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _m3ua_deregreqTxCount.help = @"count of sent DEREGREQ packets";

            _m3ua_deregreqRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"m3ua_deregreq_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _m3ua_deregreqRxCount.help = @"count of received DEREGREQ packets";

            _m3ua_deregrspTxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"m3ua_deregrsp_tx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _m3ua_deregrspTxCount.help = @"count of sent DEREGRSP packets";

            _m3ua_deregrspRxCount = [[UMPrometheusMetric alloc]initWithMetricName:@"m3ua_deregrsp_rx_count"
                                                               subname1:@"linkset"
                                                              subvalue1:_linksetName
                                                                   type:UMPrometheusMetricType_counter];
            _m3ua_deregrspRxCount.help = @"count of received DEREGRSP packets";

        }
        
    }
    return self;
}


- (void)setSubname1:(NSString *)a value:(NSString *)b
{
    [_linkUpCount setSubname1:a value:b];
    [_linkDownCount setSubname1:a value:b];
    [_linksAvailableGauge setSubname1:a value:b];
    [_sltmTxCount setSubname1:a value:b];
    [_sltaTxCount setSubname1:a value:b];
    [_ssltmTxCount setSubname1:a value:b];
    [_ssltaTxCount setSubname1:a value:b];
    [_cooTxCount setSubname1:a value:b];
    [_coaTxCount setSubname1:a value:b];
    [_xcoTxCount setSubname1:a value:b];
    [_xcaTxCount setSubname1:a value:b];
    [_cbdTxCount setSubname1:a value:b];
    [_cbaTxCount setSubname1:a value:b];
    [_ecoTxCount setSubname1:a value:b];
    [_ecaTxCount setSubname1:a value:b];
    [_rctTxCount setSubname1:a value:b];
    [_tfcTxCount setSubname1:a value:b];
    [_tfpTxCount setSubname1:a value:b];
    [_tfrTxCount setSubname1:a value:b];
    [_tfaTxCount setSubname1:a value:b];
    [_rstTxCount setSubname1:a value:b];
    [_rsrTxCount setSubname1:a value:b];
    [_linTxCount setSubname1:a value:b];
    [_lunTxCount setSubname1:a value:b];
    [_liaTxCount setSubname1:a value:b];
    [_luaTxCount setSubname1:a value:b];
    [_lidTxCount setSubname1:a value:b];
    [_lfuTxCount setSubname1:a value:b];
    [_lltTxCount setSubname1:a value:b];
    [_lrtTxCount setSubname1:a value:b];
    [_traTxCount setSubname1:a value:b];
    [_dlcTxCount setSubname1:a value:b];
    [_cssTxCount setSubname1:a value:b];
    [_cnsTxCount setSubname1:a value:b];
    [_cnpTxCount setSubname1:a value:b];
    [_upuTxCount setSubname1:a value:b];
    [_tcpTxCount setSubname1:a value:b];
    [_trwTxCount setSubname1:a value:b];
    [_tcrTxCount setSubname1:a value:b];
    [_tcaTxCount setSubname1:a value:b];
    [_rcpTxCount setSubname1:a value:b];
    [_rcrTxCount setSubname1:a value:b];
    [_upaTxCount setSubname1:a value:b];
    [_uptTxCount setSubname1:a value:b];
    [_sltmRxCount setSubname1:a value:b];
    [_sltaRxCount setSubname1:a value:b];
    [_ssltmRxCount setSubname1:a value:b];
    [_ssltaRxCount setSubname1:a value:b];
    [_cooRxCount setSubname1:a value:b];
    [_coaRxCount setSubname1:a value:b];
    [_xcoRxCount setSubname1:a value:b];
    [_xcaRxCount setSubname1:a value:b];
    [_cbdRxCount setSubname1:a value:b];
    [_cbaRxCount setSubname1:a value:b];
    [_ecoRxCount setSubname1:a value:b];
    [_ecaRxCount setSubname1:a value:b];
    [_rctRxCount setSubname1:a value:b];
    [_tfcRxCount setSubname1:a value:b];
    [_tfpRxCount setSubname1:a value:b];
    [_tfrRxCount setSubname1:a value:b];
    [_tfaRxCount setSubname1:a value:b];
    [_rstRxCount setSubname1:a value:b];
    [_rsrRxCount setSubname1:a value:b];
    [_linRxCount setSubname1:a value:b];
    [_lunRxCount setSubname1:a value:b];
    [_liaRxCount setSubname1:a value:b];
    [_luaRxCount setSubname1:a value:b];
    [_lidRxCount setSubname1:a value:b];
    [_lfuRxCount setSubname1:a value:b];
    [_lltRxCount setSubname1:a value:b];
    [_lrtRxCount setSubname1:a value:b];
    [_traRxCount setSubname1:a value:b];
    [_dlcRxCount setSubname1:a value:b];
    [_cssRxCount setSubname1:a value:b];
    [_cnsRxCount setSubname1:a value:b];
    [_cnpRxCount setSubname1:a value:b];
    [_upuRxCount setSubname1:a value:b];
    [_tcpRxCount setSubname1:a value:b];
    [_trwRxCount setSubname1:a value:b];
    [_tcrRxCount setSubname1:a value:b];
    [_tcaRxCount setSubname1:a value:b];
    [_rcpRxCount setSubname1:a value:b];
    [_rcrRxCount setSubname1:a value:b];
    [_upaRxCount setSubname1:a value:b];
    [_uptRxCount setSubname1:a value:b];
    [_msuRxCount setSubname1:a value:b];
    [_msuTxCount setSubname1:a value:b];
    [_sccpTxCount setSubname1:a value:b];
    [_sccpRxCount setSubname1:a value:b];
    [_tupTxCount setSubname1:a value:b];
    [_tupRxCount setSubname1:a value:b];
    [_isupTxCount setSubname1:a value:b];
    [_isupRxCount setSubname1:a value:b];
    [_bisupTxCount setSubname1:a value:b];
    [_bisupRxCount setSubname1:a value:b];
    [_sisupTxCount setSubname1:a value:b];
    [_sisupRxCount setSubname1:a value:b];
    [_dupcRxCount setSubname1:a value:b];
    [_dupcTxCount setSubname1:a value:b];
    [_dupfRxCount setSubname1:a value:b];
    [_dupfTxCount setSubname1:a value:b];
    [_resRxCount setSubname1:a value:b];
    [_resTxCount setSubname1:a value:b];
    [_sparecRxCount setSubname1:a value:b];
    [_sparecTxCount setSubname1:a value:b];
    [_sparedRxCount setSubname1:a value:b];
    [_sparedTxCount setSubname1:a value:b];
    [_spareeRxCount setSubname1:a value:b];
    [_spareeTxCount setSubname1:a value:b];
    [_sparefRxCount setSubname1:a value:b];
    [_sparefTxCount setSubname1:a value:b];
    [_msuRxThroughput setSubname1:a value:b];
    [_msuTxThroughput setSubname1:a value:b];
    
    [_m3ua_errTxCount setSubname1:a value:b];
    [_m3ua_errRxCount setSubname1:a value:b];
    [_m3ua_ntfyRxCount setSubname1:a value:b];
    [_m3ua_ntfyTxCount setSubname1:a value:b];
    [_m3ua_dataTxCount setSubname1:a value:b];
    [_m3ua_dataRxCount setSubname1:a value:b];
    [_m3ua_dunaTxCount setSubname1:a value:b];
    [_m3ua_dunaRxCount setSubname1:a value:b];
    [_m3ua_davaTxCount setSubname1:a value:b];
    [_m3ua_davaRxCount setSubname1:a value:b];
    [_m3ua_daudTxCount setSubname1:a value:b];
    [_m3ua_daudRxCount setSubname1:a value:b];
    [_m3ua_sconTxCount setSubname1:a value:b];
    [_m3ua_sconRxCount setSubname1:a value:b];
    [_m3ua_dupuTxCount setSubname1:a value:b];
    [_m3ua_dupuRxCount setSubname1:a value:b];
    [_m3ua_drstTxCount setSubname1:a value:b];
    [_m3ua_drstRxCount setSubname1:a value:b];
    [_m3ua_aspupTxCount setSubname1:a value:b];
    [_m3ua_aspupRxCount setSubname1:a value:b];
    [_m3ua_apsdnTxCount setSubname1:a value:b];
    [_m3ua_apsdnRxCount setSubname1:a value:b];
    [_m3ua_beatTxCount setSubname1:a value:b];
    [_m3ua_beatRxCount setSubname1:a value:b];
    [_m3ua_aspupackTxCount setSubname1:a value:b];
    [_m3ua_aspupackRxCount setSubname1:a value:b];
    [_m3ua_aspdnackTxCount setSubname1:a value:b];
    [_m3ua_aspdnackRxCount setSubname1:a value:b];
    [_m3ua_beatackTxCount setSubname1:a value:b];
    [_m3ua_beatackRxCount setSubname1:a value:b];
    [_m3ua_aspacTxCount setSubname1:a value:b];
    [_m3ua_aspacRxCount setSubname1:a value:b];
    [_m3ua_aspiaTxCount setSubname1:a value:b];
    [_m3ua_aspiaRxCount setSubname1:a value:b];
    [_m3ua_aspacackTxCount setSubname1:a value:b];
    [_m3ua_aspacackRxCount setSubname1:a value:b];
    [_m3ua_aspiaackTxCount setSubname1:a value:b];
    [_m3ua_aspiaackRxCount setSubname1:a value:b];
    [_m3ua_regreqTxCount setSubname1:a value:b];
    [_m3ua_regreqRxCount setSubname1:a value:b];
    [_m3ua_regrspTxCount setSubname1:a value:b];
    [_m3ua_regrspRxCount setSubname1:a value:b];
    [_m3ua_deregreqTxCount setSubname1:a value:b];
    [_m3ua_deregreqRxCount setSubname1:a value:b];
    [_m3ua_deregrspTxCount setSubname1:a value:b];
    [_m3ua_deregrspRxCount setSubname1:a value:b];

    [_localRxCount setSubname1:a value:b];
    [_forwardRxCount setSubname1:a value:b];

}

- (void)registerMetrics
{
    [_prometheus addObject:_linkUpCount forKey:_linkUpCount.key];
    [_prometheus addObject:_linkDownCount forKey:_linkDownCount.key];
    [_prometheus addObject:_linksAvailableGauge forKey:_linksAvailableGauge.key];
    [_prometheus addObject:_sltmTxCount forKey:_sltmTxCount.key];
    [_prometheus addObject:_sltaTxCount forKey:_sltaTxCount.key];
    [_prometheus addObject:_ssltmTxCount forKey:_ssltmTxCount.key];
    [_prometheus addObject:_ssltaTxCount forKey:_ssltaTxCount.key];
    [_prometheus addObject:_cooTxCount forKey:_cooTxCount.key];
    [_prometheus addObject:_coaTxCount forKey:_coaTxCount.key];
    [_prometheus addObject:_xcoTxCount forKey:_xcoTxCount.key];
    [_prometheus addObject:_xcaTxCount forKey:_xcaTxCount.key];
    [_prometheus addObject:_cbdTxCount forKey:_cbdTxCount.key];
    [_prometheus addObject:_cbaTxCount forKey:_cbaTxCount.key];
    [_prometheus addObject:_ecoTxCount forKey:_ecoTxCount.key];
    [_prometheus addObject:_ecaTxCount forKey:_ecaTxCount.key];
    [_prometheus addObject:_rctTxCount forKey:_rctTxCount.key];
    [_prometheus addObject:_tfcTxCount forKey:_tfcTxCount.key];
    [_prometheus addObject:_tfpTxCount forKey:_tfpTxCount.key];
    [_prometheus addObject:_tfrTxCount forKey:_tfrTxCount.key];
    [_prometheus addObject:_tfaTxCount forKey:_tfaTxCount.key];
    [_prometheus addObject:_rstTxCount forKey:_rstTxCount.key];
    [_prometheus addObject:_rsrTxCount forKey:_rsrTxCount.key];
    [_prometheus addObject:_linTxCount forKey:_linTxCount.key];
    [_prometheus addObject:_lunTxCount forKey:_lunTxCount.key];
    [_prometheus addObject:_liaTxCount forKey:_liaTxCount.key];
    [_prometheus addObject:_luaTxCount forKey:_luaTxCount.key];
    [_prometheus addObject:_lidTxCount forKey:_lidTxCount.key];
    [_prometheus addObject:_lfuTxCount forKey:_lfuTxCount.key];
    [_prometheus addObject:_lltTxCount forKey:_lltTxCount.key];
    [_prometheus addObject:_lrtTxCount forKey:_lrtTxCount.key];
    [_prometheus addObject:_traTxCount forKey:_traTxCount.key];
    [_prometheus addObject:_dlcTxCount forKey:_dlcTxCount.key];
    [_prometheus addObject:_cssTxCount forKey:_cssTxCount.key];
    [_prometheus addObject:_cnsTxCount forKey:_cnsTxCount.key];
    [_prometheus addObject:_cnpTxCount forKey:_cnpTxCount.key];
    [_prometheus addObject:_upuTxCount forKey:_upuTxCount.key];
    [_prometheus addObject:_tcpTxCount forKey:_tcpTxCount.key];
    [_prometheus addObject:_trwTxCount forKey:_trwTxCount.key];
    [_prometheus addObject:_tcrTxCount forKey:_tcrTxCount.key];
    [_prometheus addObject:_tcaTxCount forKey:_tcaTxCount.key];
    [_prometheus addObject:_rcpTxCount forKey:_rcpTxCount.key];
    [_prometheus addObject:_rcrTxCount forKey:_rcrTxCount.key];
    [_prometheus addObject:_upaTxCount forKey:_upaTxCount.key];
    [_prometheus addObject:_uptTxCount forKey:_uptTxCount.key];
    [_prometheus addObject:_sltmRxCount forKey:_sltmRxCount.key];
    [_prometheus addObject:_sltaRxCount forKey:_sltaRxCount.key];
    [_prometheus addObject:_ssltmRxCount forKey:_ssltmRxCount.key];
    [_prometheus addObject:_ssltaRxCount forKey:_ssltaRxCount.key];
    [_prometheus addObject:_cooRxCount forKey:_cooRxCount.key];
    [_prometheus addObject:_coaRxCount forKey:_coaRxCount.key];
    [_prometheus addObject:_xcoRxCount forKey:_xcoRxCount.key];
    [_prometheus addObject:_xcaRxCount forKey:_xcaRxCount.key];
    [_prometheus addObject:_cbdRxCount forKey:_cbdRxCount.key];
    [_prometheus addObject:_cbaRxCount forKey:_cbaRxCount.key];
    [_prometheus addObject:_ecoRxCount forKey:_ecoRxCount.key];
    [_prometheus addObject:_ecaRxCount forKey:_ecaRxCount.key];
    [_prometheus addObject:_rctRxCount forKey:_rctRxCount.key];
    [_prometheus addObject:_tfcRxCount forKey:_tfcRxCount.key];
    [_prometheus addObject:_tfpRxCount forKey:_tfpRxCount.key];
    [_prometheus addObject:_tfrRxCount forKey:_tfrRxCount.key];
    [_prometheus addObject:_tfaRxCount forKey:_tfaRxCount.key];
    [_prometheus addObject:_rstRxCount forKey:_rstRxCount.key];
    [_prometheus addObject:_rsrRxCount forKey:_rsrRxCount.key];
    [_prometheus addObject:_linRxCount forKey:_linRxCount.key];
    [_prometheus addObject:_lunRxCount forKey:_lunRxCount.key];
    [_prometheus addObject:_liaRxCount forKey:_liaRxCount.key];
    [_prometheus addObject:_luaRxCount forKey:_luaRxCount.key];
    [_prometheus addObject:_lidRxCount forKey:_lidRxCount.key];
    [_prometheus addObject:_lfuRxCount forKey:_lfuRxCount.key];
    [_prometheus addObject:_lltRxCount forKey:_lltRxCount.key];
    [_prometheus addObject:_lrtRxCount forKey:_lrtRxCount.key];
    [_prometheus addObject:_traRxCount forKey:_traRxCount.key];
    [_prometheus addObject:_dlcRxCount forKey:_dlcRxCount.key];
    [_prometheus addObject:_cssRxCount forKey:_cssRxCount.key];
    [_prometheus addObject:_cnsRxCount forKey:_cnsRxCount.key];
    [_prometheus addObject:_cnpRxCount forKey:_cnpRxCount.key];
    [_prometheus addObject:_upuRxCount forKey:_upuRxCount.key];
    [_prometheus addObject:_tcpRxCount forKey:_tcpRxCount.key];
    [_prometheus addObject:_trwRxCount forKey:_trwRxCount.key];
    [_prometheus addObject:_tcrRxCount forKey:_tcrRxCount.key];
    [_prometheus addObject:_tcaRxCount forKey:_tcaRxCount.key];
    [_prometheus addObject:_rcpRxCount forKey:_rcpRxCount.key];
    [_prometheus addObject:_rcrRxCount forKey:_rcrRxCount.key];
    [_prometheus addObject:_upaRxCount forKey:_upaRxCount.key];
    [_prometheus addObject:_uptRxCount forKey:_uptRxCount.key];
    [_prometheus addObject:_msuRxCount forKey:_msuRxCount.key];
    [_prometheus addObject:_msuTxCount forKey:_msuTxCount.key];
    [_prometheus addObject:_sccpTxCount forKey:_sccpTxCount.key];
    [_prometheus addObject:_sccpRxCount forKey:_sccpRxCount.key];
    [_prometheus addObject:_tupTxCount forKey:_tupTxCount.key];
    [_prometheus addObject:_tupRxCount forKey:_tupRxCount.key];
    [_prometheus addObject:_isupTxCount forKey:_isupTxCount.key];
    [_prometheus addObject:_isupRxCount forKey:_isupRxCount.key];
    [_prometheus addObject:_bisupTxCount forKey:_bisupTxCount.key];
    [_prometheus addObject:_bisupRxCount forKey:_bisupRxCount.key];
    [_prometheus addObject:_sisupTxCount forKey:_sisupTxCount.key];
    [_prometheus addObject:_sisupRxCount forKey:_sisupRxCount.key];
    [_prometheus addObject:_dupcRxCount forKey:_dupcRxCount.key];
    [_prometheus addObject:_dupcTxCount forKey:_dupcTxCount.key];
    [_prometheus addObject:_dupfRxCount forKey:_dupfRxCount.key];
    [_prometheus addObject:_dupfTxCount forKey:_dupfTxCount.key];
    [_prometheus addObject:_resRxCount forKey:_resRxCount.key];
    [_prometheus addObject:_resTxCount forKey:_resTxCount.key];
    [_prometheus addObject:_sparecRxCount forKey:_sparecRxCount.key];
    [_prometheus addObject:_sparecTxCount forKey:_sparecTxCount.key];
    [_prometheus addObject:_sparedRxCount forKey:_sparedRxCount.key];
    [_prometheus addObject:_sparedTxCount forKey:_sparedTxCount.key];
    [_prometheus addObject:_spareeRxCount forKey:_spareeRxCount.key];
    [_prometheus addObject:_spareeTxCount forKey:_spareeTxCount.key];
    [_prometheus addObject:_sparefRxCount forKey:_sparefRxCount.key];
    [_prometheus addObject:_sparefTxCount forKey:_sparefTxCount.key];
    [_prometheus addObject:_msuRxThroughput forKey:_msuRxThroughput.key];
    [_prometheus addObject:_msuTxThroughput forKey:_msuTxThroughput.key];
    
    [_prometheus addObject:_m3ua_errTxCount forKey:_m3ua_errTxCount.key];
    [_prometheus addObject:_m3ua_errRxCount forKey:_m3ua_errRxCount.key];
    [_prometheus addObject:_m3ua_ntfyRxCount forKey:_m3ua_ntfyRxCount.key];
    [_prometheus addObject:_m3ua_ntfyTxCount forKey:_m3ua_ntfyTxCount.key];
    [_prometheus addObject:_m3ua_dataTxCount forKey:_m3ua_dataTxCount.key];
    [_prometheus addObject:_m3ua_dataRxCount forKey:_m3ua_dataRxCount.key];
    [_prometheus addObject:_m3ua_dunaTxCount forKey:_m3ua_dunaTxCount.key];
    [_prometheus addObject:_m3ua_dunaRxCount forKey:_m3ua_dunaRxCount.key];
    [_prometheus addObject:_m3ua_davaTxCount forKey:_m3ua_davaTxCount.key];
    [_prometheus addObject:_m3ua_davaRxCount forKey:_m3ua_davaRxCount.key];
    [_prometheus addObject:_m3ua_daudTxCount forKey:_m3ua_daudTxCount.key];
    [_prometheus addObject:_m3ua_daudRxCount forKey:_m3ua_daudRxCount.key];
    [_prometheus addObject:_m3ua_sconTxCount forKey:_m3ua_sconTxCount.key];
    [_prometheus addObject:_m3ua_sconRxCount forKey:_m3ua_sconRxCount.key];
    [_prometheus addObject:_m3ua_dupuTxCount forKey:_m3ua_dupuTxCount.key];
    [_prometheus addObject:_m3ua_dupuRxCount forKey:_m3ua_dupuRxCount.key];
    [_prometheus addObject:_m3ua_drstTxCount forKey:_m3ua_drstTxCount.key];
    [_prometheus addObject:_m3ua_drstRxCount forKey:_m3ua_drstRxCount.key];
    [_prometheus addObject:_m3ua_aspupTxCount forKey:_m3ua_aspupTxCount.key];
    [_prometheus addObject:_m3ua_aspupRxCount forKey:_m3ua_aspupRxCount.key];
    [_prometheus addObject:_m3ua_apsdnTxCount forKey:_m3ua_apsdnTxCount.key];
    [_prometheus addObject:_m3ua_apsdnRxCount forKey:_m3ua_apsdnRxCount.key];
    [_prometheus addObject:_m3ua_beatTxCount forKey:_m3ua_beatTxCount.key];
    [_prometheus addObject:_m3ua_beatRxCount forKey:_m3ua_beatRxCount.key];
    [_prometheus addObject:_m3ua_aspupackTxCount forKey:_m3ua_aspupackTxCount.key];
    [_prometheus addObject:_m3ua_aspupackRxCount forKey:_m3ua_aspupackRxCount.key];
    [_prometheus addObject:_m3ua_aspdnackTxCount forKey:_m3ua_aspdnackTxCount.key];
    [_prometheus addObject:_m3ua_aspdnackRxCount forKey:_m3ua_aspdnackRxCount.key];
    [_prometheus addObject:_m3ua_beatackTxCount forKey:_m3ua_beatackTxCount.key];
    [_prometheus addObject:_m3ua_beatackRxCount forKey:_m3ua_beatackRxCount.key];
    [_prometheus addObject:_m3ua_aspacTxCount forKey:_m3ua_aspacTxCount.key];
    [_prometheus addObject:_m3ua_aspacRxCount forKey:_m3ua_aspacRxCount.key];
    [_prometheus addObject:_m3ua_aspiaTxCount forKey:_m3ua_aspiaTxCount.key];
    [_prometheus addObject:_m3ua_aspiaRxCount forKey:_m3ua_aspiaRxCount.key];
    [_prometheus addObject:_m3ua_aspacackTxCount forKey:_m3ua_aspacackTxCount.key];
    [_prometheus addObject:_m3ua_aspacackRxCount forKey:_m3ua_aspacackRxCount.key];
    [_prometheus addObject:_m3ua_aspacackTxCount forKey:_m3ua_aspiaackTxCount.key];
    [_prometheus addObject:_m3ua_aspacackRxCount forKey:_m3ua_aspiaackRxCount.key];
    [_prometheus addObject:_m3ua_aspiaackTxCount forKey:_m3ua_aspiaackTxCount.key];
    [_prometheus addObject:_m3ua_aspiaackRxCount forKey:_m3ua_aspiaackRxCount.key];
    [_prometheus addObject:_m3ua_regreqTxCount forKey:_m3ua_regreqTxCount.key];
    [_prometheus addObject:_m3ua_regreqRxCount forKey:_m3ua_regreqRxCount.key];
    [_prometheus addObject:_m3ua_regrspTxCount forKey:_m3ua_regrspTxCount.key];
    [_prometheus addObject:_m3ua_regrspRxCount forKey:_m3ua_regrspRxCount.key];
    [_prometheus addObject:_m3ua_deregreqTxCount forKey:_m3ua_deregreqTxCount.key];
    [_prometheus addObject:_m3ua_deregreqRxCount forKey:_m3ua_deregreqRxCount.key];
    [_prometheus addObject:_m3ua_deregrspTxCount forKey:_m3ua_deregrspTxCount.key];
    [_prometheus addObject:_m3ua_deregrspRxCount forKey:_m3ua_deregrspRxCount.key];

    [_prometheus addObject:_localRxCount forKey:_localRxCount.key];
    [_prometheus addObject:_forwardRxCount forKey:_forwardRxCount.key];

}

- (void)unregisterMetrics
{
    [_prometheus removeObjectForKey:_linkUpCount.key];
    [_prometheus removeObjectForKey:_linkDownCount.key];
    [_prometheus removeObjectForKey:_linksAvailableGauge.key];
    [_prometheus removeObjectForKey:_sltmTxCount.key];
    [_prometheus removeObjectForKey:_sltaTxCount.key];
    [_prometheus removeObjectForKey:_ssltmTxCount.key];
    [_prometheus removeObjectForKey:_ssltaTxCount.key];
    [_prometheus removeObjectForKey:_cooTxCount.key];
    [_prometheus removeObjectForKey:_coaTxCount.key];
    [_prometheus removeObjectForKey:_xcoTxCount.key];
    [_prometheus removeObjectForKey:_xcaTxCount.key];
    [_prometheus removeObjectForKey:_cbdTxCount.key];
    [_prometheus removeObjectForKey:_cbaTxCount.key];
    [_prometheus removeObjectForKey:_ecoTxCount.key];
    [_prometheus removeObjectForKey:_ecaTxCount.key];
    [_prometheus removeObjectForKey:_rctTxCount.key];
    [_prometheus removeObjectForKey:_tfcTxCount.key];
    [_prometheus removeObjectForKey:_tfpTxCount.key];
    [_prometheus removeObjectForKey:_tfrTxCount.key];
    [_prometheus removeObjectForKey:_tfaTxCount.key];
    [_prometheus removeObjectForKey:_rstTxCount.key];
    [_prometheus removeObjectForKey:_rsrTxCount.key];
    [_prometheus removeObjectForKey:_linTxCount.key];
    [_prometheus removeObjectForKey:_lunTxCount.key];
    [_prometheus removeObjectForKey:_liaTxCount.key];
    [_prometheus removeObjectForKey:_luaTxCount.key];
    [_prometheus removeObjectForKey:_lidTxCount.key];
    [_prometheus removeObjectForKey:_lfuTxCount.key];
    [_prometheus removeObjectForKey:_lltTxCount.key];
    [_prometheus removeObjectForKey:_lrtTxCount.key];
    [_prometheus removeObjectForKey:_traTxCount.key];
    [_prometheus removeObjectForKey:_dlcTxCount.key];
    [_prometheus removeObjectForKey:_cssTxCount.key];
    [_prometheus removeObjectForKey:_cnsTxCount.key];
    [_prometheus removeObjectForKey:_cnpTxCount.key];
    [_prometheus removeObjectForKey:_upuTxCount.key];
    [_prometheus removeObjectForKey:_tcpTxCount.key];
    [_prometheus removeObjectForKey:_trwTxCount.key];
    [_prometheus removeObjectForKey:_tcrTxCount.key];
    [_prometheus removeObjectForKey:_tcaTxCount.key];
    [_prometheus removeObjectForKey:_rcpTxCount.key];
    [_prometheus removeObjectForKey:_rcrTxCount.key];
    [_prometheus removeObjectForKey:_upaTxCount.key];
    [_prometheus removeObjectForKey:_uptTxCount.key];
    [_prometheus removeObjectForKey:_sltmRxCount.key];
    [_prometheus removeObjectForKey:_sltaRxCount.key];
    [_prometheus removeObjectForKey:_ssltmRxCount.key];
    [_prometheus removeObjectForKey:_ssltaRxCount.key];
    [_prometheus removeObjectForKey:_cooRxCount.key];
    [_prometheus removeObjectForKey:_coaRxCount.key];
    [_prometheus removeObjectForKey:_xcoRxCount.key];
    [_prometheus removeObjectForKey:_xcaRxCount.key];
    [_prometheus removeObjectForKey:_cbdRxCount.key];
    [_prometheus removeObjectForKey:_cbaRxCount.key];
    [_prometheus removeObjectForKey:_ecoRxCount.key];
    [_prometheus removeObjectForKey:_ecaRxCount.key];
    [_prometheus removeObjectForKey:_rctRxCount.key];
    [_prometheus removeObjectForKey:_tfcRxCount.key];
    [_prometheus removeObjectForKey:_tfpRxCount.key];
    [_prometheus removeObjectForKey:_tfrRxCount.key];
    [_prometheus removeObjectForKey:_tfaRxCount.key];
    [_prometheus removeObjectForKey:_rstRxCount.key];
    [_prometheus removeObjectForKey:_rsrRxCount.key];
    [_prometheus removeObjectForKey:_linRxCount.key];
    [_prometheus removeObjectForKey:_lunRxCount.key];
    [_prometheus removeObjectForKey:_liaRxCount.key];
    [_prometheus removeObjectForKey:_luaRxCount.key];
    [_prometheus removeObjectForKey:_lidRxCount.key];
    [_prometheus removeObjectForKey:_lfuRxCount.key];
    [_prometheus removeObjectForKey:_lltRxCount.key];
    [_prometheus removeObjectForKey:_lrtRxCount.key];
    [_prometheus removeObjectForKey:_traRxCount.key];
    [_prometheus removeObjectForKey:_dlcRxCount.key];
    [_prometheus removeObjectForKey:_cssRxCount.key];
    [_prometheus removeObjectForKey:_cnsRxCount.key];
    [_prometheus removeObjectForKey:_cnpRxCount.key];
    [_prometheus removeObjectForKey:_upuRxCount.key];
    [_prometheus removeObjectForKey:_tcpRxCount.key];
    [_prometheus removeObjectForKey:_trwRxCount.key];
    [_prometheus removeObjectForKey:_tcrRxCount.key];
    [_prometheus removeObjectForKey:_tcaRxCount.key];
    [_prometheus removeObjectForKey:_rcpRxCount.key];
    [_prometheus removeObjectForKey:_rcrRxCount.key];
    [_prometheus removeObjectForKey:_upaRxCount.key];
    [_prometheus removeObjectForKey:_uptRxCount.key];
    [_prometheus removeObjectForKey:_msuRxCount.key];
    [_prometheus removeObjectForKey:_msuTxCount.key];
    [_prometheus removeObjectForKey:_sccpTxCount.key];
    [_prometheus removeObjectForKey:_sccpRxCount.key];
    [_prometheus removeObjectForKey:_tupTxCount.key];
    [_prometheus removeObjectForKey:_tupRxCount.key];
    [_prometheus removeObjectForKey:_isupTxCount.key];
    [_prometheus removeObjectForKey:_isupRxCount.key];
    [_prometheus removeObjectForKey:_bisupTxCount.key];
    [_prometheus removeObjectForKey:_bisupRxCount.key];
    [_prometheus removeObjectForKey:_sisupTxCount.key];
    [_prometheus removeObjectForKey:_sisupRxCount.key];
    [_prometheus removeObjectForKey:_dupcRxCount.key];
    [_prometheus removeObjectForKey:_dupcTxCount.key];
    [_prometheus removeObjectForKey:_dupfRxCount.key];
    [_prometheus removeObjectForKey:_dupfTxCount.key];
    [_prometheus removeObjectForKey:_resRxCount.key];
    [_prometheus removeObjectForKey:_resTxCount.key];
    [_prometheus removeObjectForKey:_sparecRxCount.key];
    [_prometheus removeObjectForKey:_sparecTxCount.key];
    [_prometheus removeObjectForKey:_sparedRxCount.key];
    [_prometheus removeObjectForKey:_sparedTxCount.key];
    [_prometheus removeObjectForKey:_spareeRxCount.key];
    [_prometheus removeObjectForKey:_spareeTxCount.key];
    [_prometheus removeObjectForKey:_sparefRxCount.key];
    [_prometheus removeObjectForKey:_sparefTxCount.key];
    [_prometheus removeObjectForKey:_msuRxThroughput.key];
    [_prometheus removeObjectForKey:_msuTxThroughput.key];

    [_prometheus removeObjectForKey:_m3ua_errTxCount.key];
    [_prometheus removeObjectForKey:_m3ua_errRxCount.key];
    [_prometheus removeObjectForKey:_m3ua_ntfyRxCount.key];
    [_prometheus removeObjectForKey:_m3ua_ntfyTxCount.key];
    [_prometheus removeObjectForKey:_m3ua_dataTxCount.key];
    [_prometheus removeObjectForKey:_m3ua_dataRxCount.key];
    [_prometheus removeObjectForKey:_m3ua_dunaTxCount.key];
    [_prometheus removeObjectForKey:_m3ua_dunaRxCount.key];
    [_prometheus removeObjectForKey:_m3ua_davaTxCount.key];
    [_prometheus removeObjectForKey:_m3ua_davaRxCount.key];
    [_prometheus removeObjectForKey:_m3ua_daudTxCount.key];
    [_prometheus removeObjectForKey:_m3ua_daudRxCount.key];
    [_prometheus removeObjectForKey:_m3ua_sconTxCount.key];
    [_prometheus removeObjectForKey:_m3ua_sconRxCount.key];
    [_prometheus removeObjectForKey:_m3ua_dupuTxCount.key];
    [_prometheus removeObjectForKey:_m3ua_dupuRxCount.key];
    [_prometheus removeObjectForKey:_m3ua_drstTxCount.key];
    [_prometheus removeObjectForKey:_m3ua_drstRxCount.key];
    [_prometheus removeObjectForKey:_m3ua_aspupTxCount.key];
    [_prometheus removeObjectForKey:_m3ua_aspupRxCount.key];
    [_prometheus removeObjectForKey:_m3ua_apsdnTxCount.key];
    [_prometheus removeObjectForKey:_m3ua_apsdnRxCount.key];
    [_prometheus removeObjectForKey:_m3ua_beatTxCount.key];
    [_prometheus removeObjectForKey:_m3ua_beatRxCount.key];
    [_prometheus removeObjectForKey:_m3ua_aspupackTxCount.key];
    [_prometheus removeObjectForKey:_m3ua_aspupackRxCount.key];
    [_prometheus removeObjectForKey:_m3ua_aspdnackTxCount.key];
    [_prometheus removeObjectForKey:_m3ua_aspdnackRxCount.key];
    [_prometheus removeObjectForKey:_m3ua_beatackTxCount.key];
    [_prometheus removeObjectForKey:_m3ua_beatackRxCount.key];
    [_prometheus removeObjectForKey:_m3ua_aspacTxCount.key];
    [_prometheus removeObjectForKey:_m3ua_aspacRxCount.key];
    [_prometheus removeObjectForKey:_m3ua_aspiaTxCount.key];
    [_prometheus removeObjectForKey:_m3ua_aspiaRxCount.key];
    [_prometheus removeObjectForKey:_m3ua_aspacackTxCount.key];
    [_prometheus removeObjectForKey:_m3ua_aspacackRxCount.key];
    [_prometheus removeObjectForKey:_m3ua_aspiaackTxCount.key];
    [_prometheus removeObjectForKey:_m3ua_aspiaackRxCount.key];
    [_prometheus removeObjectForKey:_m3ua_regreqTxCount.key];
    [_prometheus removeObjectForKey:_m3ua_regreqRxCount.key];
    [_prometheus removeObjectForKey:_m3ua_regrspTxCount.key];
    [_prometheus removeObjectForKey:_m3ua_regrspRxCount.key];
    [_prometheus removeObjectForKey:_m3ua_deregreqTxCount.key];
    [_prometheus removeObjectForKey:_m3ua_deregreqRxCount.key];
    [_prometheus removeObjectForKey:_m3ua_deregrspTxCount.key];
    [_prometheus removeObjectForKey:_m3ua_deregrspRxCount.key];

    [_prometheus removeObjectForKey:_localRxCount.key];
    [_prometheus removeObjectForKey:_forwardRxCount.key];
}
@end
