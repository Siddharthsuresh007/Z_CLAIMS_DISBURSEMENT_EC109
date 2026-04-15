@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Claims Automation Root View'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define root view entity ZI_ClaimsAuto
  as select from zclaims_auto
{
    key claim_uuid  as ClaimUuid,
    claim_id        as ClaimId,
    policy_id       as PolicyId,
    partner         as Partner,
    
    @Semantics.amount.currencyCode: 'Currency'
    amount          as Amount,  
    
    currency        as Currency,
    fscd_doc_no     as FSCDDocNo,
    status          as Status
}
