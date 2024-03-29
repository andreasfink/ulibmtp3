//
//  UMMTP3LinkSetPrometheusData.h
//  ulibmtp3
//
//  Created by Andreas Fink on 22.06.21.
//  Copyright © 2021 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/ulib.h>

@interface UMMTP3LinkSetPrometheusData : UMObject
{
    NSString                      *_linksetName;
    UMPrometheus                  *_prometheus;
    BOOL                          _isM3UA;
    
    /* generic */
    UMPrometheusMetric            *_linkUpCount;
    UMPrometheusMetric            *_linkDownCount;
    UMPrometheusMetric            *_linksAvailableGauge;
    UMPrometheusThroughputMetric  *_msuRxThroughput;
    UMPrometheusThroughputMetric  *_msuTxThroughput;
    UMPrometheusMetric            *_msuRxCount;
    UMPrometheusMetric            *_msuTxCount;
    UMPrometheusMetric            *_sccpTxCount;
    UMPrometheusMetric            *_sccpRxCount;
    UMPrometheusMetric            *_tupTxCount;
    UMPrometheusMetric            *_tupRxCount;
    UMPrometheusMetric            *_isupTxCount;
    UMPrometheusMetric            *_isupRxCount;
    UMPrometheusMetric            *_bisupTxCount;
    UMPrometheusMetric            *_bisupRxCount;
    UMPrometheusMetric            *_sisupTxCount;
    UMPrometheusMetric            *_sisupRxCount;
    UMPrometheusMetric            *_dupcRxCount;
    UMPrometheusMetric            *_dupcTxCount;
    UMPrometheusMetric            *_dupfRxCount;
    UMPrometheusMetric            *_dupfTxCount;
    UMPrometheusMetric            *_resRxCount;
    UMPrometheusMetric            *_resTxCount;
    UMPrometheusMetric            *_sparecRxCount;
    UMPrometheusMetric            *_sparecTxCount;
    UMPrometheusMetric            *_sparedRxCount;
    UMPrometheusMetric            *_sparedTxCount;
    UMPrometheusMetric            *_spareeRxCount;
    UMPrometheusMetric            *_spareeTxCount;
    UMPrometheusMetric            *_sparefRxCount;
    UMPrometheusMetric            *_sparefTxCount;

    /* M2PA only */
    UMPrometheusMetric            *_sltmTxCount;
    UMPrometheusMetric            *_sltaTxCount;
    UMPrometheusMetric            *_ssltmTxCount;
    UMPrometheusMetric            *_ssltaTxCount;
    UMPrometheusMetric            *_cooTxCount;
    UMPrometheusMetric            *_coaTxCount;
    UMPrometheusMetric            *_xcoTxCount;
    UMPrometheusMetric            *_xcaTxCount;
    UMPrometheusMetric            *_cbdTxCount;
    UMPrometheusMetric            *_cbaTxCount;
    UMPrometheusMetric            *_ecoTxCount;
    UMPrometheusMetric            *_ecaTxCount;
    UMPrometheusMetric            *_rctTxCount;
    UMPrometheusMetric            *_tfcTxCount;
    UMPrometheusMetric            *_tfpTxCount;
    UMPrometheusMetric            *_tfrTxCount;
    UMPrometheusMetric            *_tfaTxCount;
    UMPrometheusMetric            *_rstTxCount;
    UMPrometheusMetric            *_rsrTxCount;
    UMPrometheusMetric            *_linTxCount;
    UMPrometheusMetric            *_lunTxCount;
    UMPrometheusMetric            *_liaTxCount;
    UMPrometheusMetric            *_luaTxCount;
    UMPrometheusMetric            *_lidTxCount;
    UMPrometheusMetric            *_lfuTxCount;
    UMPrometheusMetric            *_lltTxCount;
    UMPrometheusMetric            *_lrtTxCount;
    UMPrometheusMetric            *_traTxCount;
    UMPrometheusMetric            *_dlcTxCount;
    UMPrometheusMetric            *_cssTxCount;
    UMPrometheusMetric            *_cnsTxCount;
    UMPrometheusMetric            *_cnpTxCount;
    UMPrometheusMetric            *_upuTxCount;
    UMPrometheusMetric            *_tcpTxCount;
    UMPrometheusMetric            *_trwTxCount;
    UMPrometheusMetric            *_tcrTxCount;
    UMPrometheusMetric            *_tcaTxCount;
    UMPrometheusMetric            *_rcpTxCount;
    UMPrometheusMetric            *_rcrTxCount;
    UMPrometheusMetric            *_upaTxCount;
    UMPrometheusMetric            *_uptTxCount;
    UMPrometheusMetric            *_sltmRxCount;
    UMPrometheusMetric            *_sltaRxCount;
    UMPrometheusMetric            *_ssltmRxCount;
    UMPrometheusMetric            *_ssltaRxCount;
    UMPrometheusMetric            *_cooRxCount;
    UMPrometheusMetric            *_coaRxCount;
    UMPrometheusMetric            *_xcoRxCount;
    UMPrometheusMetric            *_xcaRxCount;
    UMPrometheusMetric            *_cbdRxCount;
    UMPrometheusMetric            *_cbaRxCount;
    UMPrometheusMetric            *_ecoRxCount;
    UMPrometheusMetric            *_ecaRxCount;
    UMPrometheusMetric            *_rctRxCount;
    UMPrometheusMetric            *_tfcRxCount;
    UMPrometheusMetric            *_tfpRxCount;
    UMPrometheusMetric            *_tfrRxCount;
    UMPrometheusMetric            *_tfaRxCount;
    UMPrometheusMetric            *_rstRxCount;
    UMPrometheusMetric            *_rsrRxCount;
    UMPrometheusMetric            *_linRxCount;
    UMPrometheusMetric            *_lunRxCount;
    UMPrometheusMetric            *_liaRxCount;
    UMPrometheusMetric            *_luaRxCount;
    UMPrometheusMetric            *_lidRxCount;
    UMPrometheusMetric            *_lfuRxCount;
    UMPrometheusMetric            *_lltRxCount;
    UMPrometheusMetric            *_lrtRxCount;
    UMPrometheusMetric            *_traRxCount;
    UMPrometheusMetric            *_dlcRxCount;
    UMPrometheusMetric            *_cssRxCount;
    UMPrometheusMetric            *_cnsRxCount;
    UMPrometheusMetric            *_cnpRxCount;
    UMPrometheusMetric            *_upuRxCount;
    UMPrometheusMetric            *_tcpRxCount;
    UMPrometheusMetric            *_trwRxCount;
    UMPrometheusMetric            *_tcrRxCount;
    UMPrometheusMetric            *_tcaRxCount;
    UMPrometheusMetric            *_rcpRxCount;
    UMPrometheusMetric            *_rcrRxCount;
    UMPrometheusMetric            *_upaRxCount;
    UMPrometheusMetric            *_uptRxCount;

    /* m3ua only */
    UMPrometheusMetric  *_m3ua_errTxCount;
    UMPrometheusMetric  *_m3ua_errRxCount;
    UMPrometheusMetric  *_m3ua_ntfyRxCount;
    UMPrometheusMetric  *_m3ua_ntfyTxCount;
    UMPrometheusMetric  *_m3ua_dataTxCount;
    UMPrometheusMetric  *_m3ua_dataRxCount;
    UMPrometheusMetric  *_m3ua_dunaTxCount;
    UMPrometheusMetric  *_m3ua_dunaRxCount;
    UMPrometheusMetric  *_m3ua_davaTxCount;
    UMPrometheusMetric  *_m3ua_davaRxCount;
    UMPrometheusMetric  *_m3ua_daudTxCount;
    UMPrometheusMetric  *_m3ua_daudRxCount;
    UMPrometheusMetric  *_m3ua_sconTxCount;
    UMPrometheusMetric  *_m3ua_sconRxCount;
    UMPrometheusMetric  *_m3ua_dupuTxCount;
    UMPrometheusMetric  *_m3ua_dupuRxCount;
    UMPrometheusMetric  *_m3ua_drstTxCount;
    UMPrometheusMetric  *_m3ua_drstRxCount;
    UMPrometheusMetric  *_m3ua_aspupTxCount;
    UMPrometheusMetric  *_m3ua_aspupRxCount;
    UMPrometheusMetric  *_m3ua_apsdnTxCount;
    UMPrometheusMetric  *_m3ua_apsdnRxCount;
    UMPrometheusMetric  *_m3ua_beatTxCount;
    UMPrometheusMetric  *_m3ua_beatRxCount;
    UMPrometheusMetric  *_m3ua_aspupackTxCount;
    UMPrometheusMetric  *_m3ua_aspupackRxCount;
    UMPrometheusMetric  *_m3ua_aspdnackTxCount;
    UMPrometheusMetric  *_m3ua_aspdnackRxCount;
    UMPrometheusMetric  *_m3ua_beatackTxCount;
    UMPrometheusMetric  *_m3ua_beatackRxCount;
    UMPrometheusMetric  *_m3ua_aspacTxCount;
    UMPrometheusMetric  *_m3ua_aspacRxCount;
    UMPrometheusMetric  *_m3ua_aspiaTxCount;
    UMPrometheusMetric  *_m3ua_aspiaRxCount;
    UMPrometheusMetric  *_m3ua_aspacackTxCount;
    UMPrometheusMetric  *_m3ua_aspacackRxCount;
    UMPrometheusMetric  *_m3ua_aspiaackTxCount;
    UMPrometheusMetric  *_m3ua_aspiaackRxCount;
    UMPrometheusMetric  *_m3ua_regreqTxCount;
    UMPrometheusMetric  *_m3ua_regreqRxCount;
    UMPrometheusMetric  *_m3ua_regrspTxCount;
    UMPrometheusMetric  *_m3ua_regrspRxCount;
    UMPrometheusMetric  *_m3ua_deregreqTxCount;
    UMPrometheusMetric  *_m3ua_deregreqRxCount;
    UMPrometheusMetric  *_m3ua_deregrspTxCount;
    UMPrometheusMetric  *_m3ua_deregrspRxCount;
    UMPrometheusMetric  *_localRxCount;
    UMPrometheusMetric  *_forwardRxCount;


}

@property(readwrite,strong) UMPrometheus                  *prometheus;
@property(readwrite,assign) BOOL                          isM3UA;
@property(readwrite,strong) UMPrometheusMetric            *linksAvailableGauge;
@property(readwrite,strong) UMPrometheusMetric            *linkUpCount;
@property(readwrite,strong) UMPrometheusMetric            *linkDownCount;
@property(readwrite,strong) UMPrometheusMetric            *sltmTxCount;
@property(readwrite,strong) UMPrometheusMetric            *sltaTxCount;
@property(readwrite,strong) UMPrometheusMetric            *ssltmTxCount;
@property(readwrite,strong) UMPrometheusMetric            *ssltaTxCount;
@property(readwrite,strong) UMPrometheusMetric            *cooTxCount;
@property(readwrite,strong) UMPrometheusMetric            *coaTxCount;
@property(readwrite,strong) UMPrometheusMetric            *xcoTxCount;
@property(readwrite,strong) UMPrometheusMetric            *xcaTxCount;
@property(readwrite,strong) UMPrometheusMetric            *cbdTxCount;
@property(readwrite,strong) UMPrometheusMetric            *cbaTxCount;
@property(readwrite,strong) UMPrometheusMetric            *ecoTxCount;
@property(readwrite,strong) UMPrometheusMetric            *ecaTxCount;
@property(readwrite,strong) UMPrometheusMetric            *rctTxCount;
@property(readwrite,strong) UMPrometheusMetric            *tfcTxCount;
@property(readwrite,strong) UMPrometheusMetric            *tfpTxCount;
@property(readwrite,strong) UMPrometheusMetric            *tfrTxCount;
@property(readwrite,strong) UMPrometheusMetric            *tfaTxCount;
@property(readwrite,strong) UMPrometheusMetric            *rstTxCount;
@property(readwrite,strong) UMPrometheusMetric            *rsrTxCount;
@property(readwrite,strong) UMPrometheusMetric            *linTxCount;
@property(readwrite,strong) UMPrometheusMetric            *lunTxCount;
@property(readwrite,strong) UMPrometheusMetric            *liaTxCount;
@property(readwrite,strong) UMPrometheusMetric            *luaTxCount;
@property(readwrite,strong) UMPrometheusMetric            *lidTxCount;
@property(readwrite,strong) UMPrometheusMetric            *lfuTxCount;
@property(readwrite,strong) UMPrometheusMetric            *lltTxCount;
@property(readwrite,strong) UMPrometheusMetric            *lrtTxCount;
@property(readwrite,strong) UMPrometheusMetric            *traTxCount;
@property(readwrite,strong) UMPrometheusMetric            *dlcTxCount;
@property(readwrite,strong) UMPrometheusMetric            *cssTxCount;
@property(readwrite,strong) UMPrometheusMetric            *cnsTxCount;
@property(readwrite,strong) UMPrometheusMetric            *cnpTxCount;
@property(readwrite,strong) UMPrometheusMetric            *upuTxCount;
@property(readwrite,strong) UMPrometheusMetric            *tcpTxCount;
@property(readwrite,strong) UMPrometheusMetric            *trwTxCount;
@property(readwrite,strong) UMPrometheusMetric            *tcrTxCount;
@property(readwrite,strong) UMPrometheusMetric            *tcaTxCount;
@property(readwrite,strong) UMPrometheusMetric            *rcpTxCount;
@property(readwrite,strong) UMPrometheusMetric            *rcrTxCount;
@property(readwrite,strong) UMPrometheusMetric            *upaTxCount;
@property(readwrite,strong) UMPrometheusMetric            *uptTxCount;
@property(readwrite,strong) UMPrometheusMetric            *sltmRxCount;
@property(readwrite,strong) UMPrometheusMetric            *sltaRxCount;
@property(readwrite,strong) UMPrometheusMetric            *ssltmRxCount;
@property(readwrite,strong) UMPrometheusMetric            *ssltaRxCount;
@property(readwrite,strong) UMPrometheusMetric            *cooRxCount;
@property(readwrite,strong) UMPrometheusMetric            *coaRxCount;
@property(readwrite,strong) UMPrometheusMetric            *xcoRxCount;
@property(readwrite,strong) UMPrometheusMetric            *xcaRxCount;
@property(readwrite,strong) UMPrometheusMetric            *cbdRxCount;
@property(readwrite,strong) UMPrometheusMetric            *cbaRxCount;
@property(readwrite,strong) UMPrometheusMetric            *ecoRxCount;
@property(readwrite,strong) UMPrometheusMetric            *ecaRxCount;
@property(readwrite,strong) UMPrometheusMetric            *rctRxCount;
@property(readwrite,strong) UMPrometheusMetric            *tfcRxCount;
@property(readwrite,strong) UMPrometheusMetric            *tfpRxCount;
@property(readwrite,strong) UMPrometheusMetric            *tfrRxCount;
@property(readwrite,strong) UMPrometheusMetric            *tfaRxCount;
@property(readwrite,strong) UMPrometheusMetric            *rstRxCount;
@property(readwrite,strong) UMPrometheusMetric            *rsrRxCount;
@property(readwrite,strong) UMPrometheusMetric            *linRxCount;
@property(readwrite,strong) UMPrometheusMetric            *lunRxCount;
@property(readwrite,strong) UMPrometheusMetric            *liaRxCount;
@property(readwrite,strong) UMPrometheusMetric            *luaRxCount;
@property(readwrite,strong) UMPrometheusMetric            *lidRxCount;
@property(readwrite,strong) UMPrometheusMetric            *lfuRxCount;
@property(readwrite,strong) UMPrometheusMetric            *lltRxCount;
@property(readwrite,strong) UMPrometheusMetric            *lrtRxCount;
@property(readwrite,strong) UMPrometheusMetric            *traRxCount;
@property(readwrite,strong) UMPrometheusMetric            *dlcRxCount;
@property(readwrite,strong) UMPrometheusMetric            *cssRxCount;
@property(readwrite,strong) UMPrometheusMetric            *cnsRxCount;
@property(readwrite,strong) UMPrometheusMetric            *cnpRxCount;
@property(readwrite,strong) UMPrometheusMetric            *upuRxCount;
@property(readwrite,strong) UMPrometheusMetric            *tcpRxCount;
@property(readwrite,strong) UMPrometheusMetric            *trwRxCount;
@property(readwrite,strong) UMPrometheusMetric            *tcrRxCount;
@property(readwrite,strong) UMPrometheusMetric            *tcaRxCount;
@property(readwrite,strong) UMPrometheusMetric            *rcpRxCount;
@property(readwrite,strong) UMPrometheusMetric            *rcrRxCount;
@property(readwrite,strong) UMPrometheusMetric            *upaRxCount;
@property(readwrite,strong) UMPrometheusMetric            *uptRxCount;
@property(readwrite,strong) UMPrometheusMetric            *msuRxCount;
@property(readwrite,strong) UMPrometheusMetric            *msuTxCount;
@property(readwrite,strong) UMPrometheusThroughputMetric  *msuRxThroughput;
@property(readwrite,strong) UMPrometheusThroughputMetric  *msuTxThroughput;
@property(readwrite,strong) UMPrometheusMetric            *sccpTxCount;
@property(readwrite,strong) UMPrometheusMetric            *sccpRxCount;
@property(readwrite,strong) UMPrometheusMetric            *tupTxCount;
@property(readwrite,strong) UMPrometheusMetric            *tupRxCount;
@property(readwrite,strong) UMPrometheusMetric            *isupTxCount;
@property(readwrite,strong) UMPrometheusMetric            *isupRxCount;
@property(readwrite,strong) UMPrometheusMetric            *bisupTxCount;
@property(readwrite,strong) UMPrometheusMetric            *bisupRxCount;
@property(readwrite,strong) UMPrometheusMetric            *sisupTxCount;
@property(readwrite,strong) UMPrometheusMetric            *sisupRxCount;
@property(readwrite,strong) UMPrometheusMetric            *dupcRxCount;
@property(readwrite,strong) UMPrometheusMetric            *dupcTxCount;
@property(readwrite,strong) UMPrometheusMetric            *dupfRxCount;
@property(readwrite,strong) UMPrometheusMetric            *dupfTxCount;
@property(readwrite,strong) UMPrometheusMetric            *resRxCount;
@property(readwrite,strong) UMPrometheusMetric            *resTxCount;
@property(readwrite,strong) UMPrometheusMetric            *sparebRxCount;
@property(readwrite,strong) UMPrometheusMetric            *sparebTxCount;
@property(readwrite,strong) UMPrometheusMetric            *sparecRxCount;
@property(readwrite,strong) UMPrometheusMetric            *sparecTxCount;
@property(readwrite,strong) UMPrometheusMetric            *sparedRxCount;
@property(readwrite,strong) UMPrometheusMetric            *sparedTxCount;
@property(readwrite,strong) UMPrometheusMetric            *spareeRxCount;
@property(readwrite,strong) UMPrometheusMetric            *spareeTxCount;
@property(readwrite,strong) UMPrometheusMetric            *sparefRxCount;
@property(readwrite,strong) UMPrometheusMetric            *sparefTxCount;

@property(readwrite,strong)     UMPrometheusMetric  *m3uaerrTxCount;
@property(readwrite,strong)     UMPrometheusMetric  *m3uaerrRxCount;
@property(readwrite,strong)     UMPrometheusMetric  *m3uantfyRxCount;
@property(readwrite,strong)     UMPrometheusMetric  *m3uantfyTxCount;
@property(readwrite,strong)     UMPrometheusMetric  *m3uadataTxCount;
@property(readwrite,strong)     UMPrometheusMetric  *m3uadataRxCount;
@property(readwrite,strong)     UMPrometheusMetric  *m3uadunaTxCount;
@property(readwrite,strong)     UMPrometheusMetric  *m3uadunaRxCount;
@property(readwrite,strong)     UMPrometheusMetric  *m3uadavaTxCount;
@property(readwrite,strong)     UMPrometheusMetric  *m3uadavaRxCount;
@property(readwrite,strong)     UMPrometheusMetric  *m3uadaudTxCount;
@property(readwrite,strong)     UMPrometheusMetric  *m3uadaudRxCount;
@property(readwrite,strong)     UMPrometheusMetric  *m3uasconTxCount;
@property(readwrite,strong)     UMPrometheusMetric  *m3uasconRxCount;
@property(readwrite,strong)     UMPrometheusMetric  *m3uadupuTxCount;
@property(readwrite,strong)     UMPrometheusMetric  *m3uadupuRxCount;
@property(readwrite,strong)     UMPrometheusMetric  *m3uadrstTxCount;
@property(readwrite,strong)     UMPrometheusMetric  *m3uadrstRxCount;
@property(readwrite,strong)     UMPrometheusMetric  *m3uaaspupTxCount;
@property(readwrite,strong)     UMPrometheusMetric  *m3uaaspupRxCount;
@property(readwrite,strong)     UMPrometheusMetric  *m3uaaspdnTxCount;
@property(readwrite,strong)     UMPrometheusMetric  *m3uaaspdnRxCount;
@property(readwrite,strong)     UMPrometheusMetric  *m3uabeatTxCount;
@property(readwrite,strong)     UMPrometheusMetric  *m3uabeatRxCount;
@property(readwrite,strong)     UMPrometheusMetric  *m3uaaspupackTxCount;
@property(readwrite,strong)     UMPrometheusMetric  *m3uaaspupackRxCount;
@property(readwrite,strong)     UMPrometheusMetric  *m3uaaspdnackTxCount;
@property(readwrite,strong)     UMPrometheusMetric  *m3uaaspdnackRxCount;
@property(readwrite,strong)     UMPrometheusMetric  *m3uabeatackTxCount;
@property(readwrite,strong)     UMPrometheusMetric  *m3uabeatackRxCount;
@property(readwrite,strong)     UMPrometheusMetric  *m3uaaspacTxCount;
@property(readwrite,strong)     UMPrometheusMetric  *m3uaaspacRxCount;
@property(readwrite,strong)     UMPrometheusMetric  *m3uaaspiaTxCount;
@property(readwrite,strong)     UMPrometheusMetric  *m3uaaspiaRxCount;
@property(readwrite,strong)     UMPrometheusMetric  *m3uaaspacackTxCount;
@property(readwrite,strong)     UMPrometheusMetric  *m3uaaspacackRxCount;
@property(readwrite,strong)     UMPrometheusMetric  *m3uaaspiaackTxCount;
@property(readwrite,strong)     UMPrometheusMetric  *m3uaaspiaackRxCount;
@property(readwrite,strong)     UMPrometheusMetric  *m3uaregreqTxCount;
@property(readwrite,strong)     UMPrometheusMetric  *m3uaregreqRxCount;
@property(readwrite,strong)     UMPrometheusMetric  *m3uaregrspTxCount;
@property(readwrite,strong)     UMPrometheusMetric  *m3uaregrspRxCount;
@property(readwrite,strong)     UMPrometheusMetric  *m3uaderegreqTxCount;
@property(readwrite,strong)     UMPrometheusMetric  *m3uaderegreqRxCount;
@property(readwrite,strong)     UMPrometheusMetric  *m3uaderegrspTxCount;
@property(readwrite,strong)     UMPrometheusMetric  *m3uaderegrspRxCount;
@property(readwrite,strong)     UMPrometheusMetric  *localRxCount;
@property(readwrite,strong)     UMPrometheusMetric  *forwardRxCount;


- (UMMTP3LinkSetPrometheusData *)initWithPrometheus:(UMPrometheus *)p linksetName:(NSString *)name isM3UA:(BOOL)isM3UA;
- (void)setSubname1:(NSString *)a value:(NSString *)b;
- (void)registerMetrics;
- (void)unregisterMetrics;

@end

