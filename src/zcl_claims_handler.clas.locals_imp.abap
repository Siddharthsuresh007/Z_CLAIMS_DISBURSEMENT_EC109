**********************************************************************
* LOCAL TYPES: Handler and Saver Classes
**********************************************************************
CLASS lhc_claim DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PUBLIC SECTION.
    " Data buffer must be public for the Saver class to access it
    TYPES: tt_claims_buffer TYPE TABLE OF zclaims_auto.
    CLASS-DATA: mt_buffer TYPE tt_claims_buffer.

  PRIVATE SECTION.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Claim RESULT result.

    METHODS create FOR MODIFY
      IMPORTING entities FOR CREATE Claim.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE Claim.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE Claim.

    METHODS read FOR READ
      IMPORTING keys FOR READ Claim RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK Claim.

    METHODS posttofscd FOR MODIFY
      IMPORTING keys FOR ACTION Claim~posttofscd RESULT result.

ENDCLASS.

CLASS lhc_claim IMPLEMENTATION.

  METHOD get_instance_authorizations.
    " Authorize all operations for this demo
    APPEND VALUE #( %tky = keys[ 1 ]-%tky
                    %update = if_abap_behv=>auth-allowed
                    %delete = if_abap_behv=>auth-allowed ) TO result.
  ENDMETHOD.

  METHOD create.
    LOOP AT entities INTO DATA(ls_entity).
      DATA(ls_new_claim) = CORRESPONDING zclaims_auto( ls_entity MAPPING FROM ENTITY ).

      IF ls_new_claim-claim_uuid IS INITIAL.
        TRY.
            ls_new_claim-claim_uuid = cl_system_uuid=>create_uuid_x16_static( ).
          CATCH cx_uuid_error.
        ENDTRY.
      ENDIF.

      ls_new_claim-status = 'N'.
      INSERT ls_new_claim INTO TABLE mt_buffer.
    ENDLOOP.
  ENDMETHOD.

  METHOD update.
    LOOP AT entities INTO DATA(ls_entity).
      READ TABLE mt_buffer WITH KEY claim_uuid = ls_entity-ClaimUuid ASSIGNING FIELD-SYMBOL(<fs_claim>).
      IF sy-subrc = 0.
        <fs_claim> = CORRESPONDING #( ls_entity MAPPING FROM ENTITY USING CONTROL ).
      ELSE.
        SELECT SINGLE * FROM zclaims_auto WHERE claim_uuid = @ls_entity-ClaimUuid INTO @DATA(ls_db).
        IF sy-subrc = 0.
            ls_db = CORRESPONDING #( ls_entity MAPPING FROM ENTITY USING CONTROL ).
            INSERT ls_db INTO TABLE mt_buffer.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD delete.
    LOOP AT keys INTO DATA(ls_key).
      DELETE mt_buffer WHERE claim_uuid = ls_key-ClaimUuid.
    ENDLOOP.
  ENDMETHOD.

  METHOD read.
    " Explicitly typed row to satisfy 'Right Type' error
    DATA: ls_result_row LIKE LINE OF result.

    LOOP AT keys INTO DATA(ls_key).
      READ TABLE mt_buffer WITH KEY claim_uuid = ls_key-ClaimUuid INTO DATA(ls_claim).
      IF sy-subrc <> 0.
        SELECT SINGLE * FROM zclaims_auto WHERE claim_uuid = @ls_key-ClaimUuid INTO @ls_claim.
      ENDIF.

      IF ls_claim IS NOT INITIAL.
        CLEAR ls_result_row.
        ls_result_row = CORRESPONDING #( ls_claim MAPPING TO ENTITY ).
        ls_result_row-%tky = ls_key-%tky.
        INSERT ls_result_row INTO TABLE result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD lock.
    " Locking logic (Optional for demo)
  ENDMETHOD.

  METHOD posttofscd.
    " 1. Read the data into a local variable
    READ ENTITIES OF zi_claimsauto IN LOCAL MODE
      ENTITY Claim ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_claims).

    LOOP AT lt_claims ASSIGNING FIELD-SYMBOL(<fs_claim>).
      " 2. Simulate the FS-CD Posting Document
      DATA(lv_sim_doc) = 'DOC-' && cl_abap_context_info=>get_system_date( ) && '-' && <fs_claim>-ClaimId.

      READ TABLE mt_buffer WITH KEY claim_uuid = <fs_claim>-ClaimUuid ASSIGNING FIELD-SYMBOL(<fs_buff>).
      IF sy-subrc = 0.
        <fs_buff>-fscd_doc_no = lv_sim_doc.
        <fs_buff>-status      = 'P'.
      ELSE.
        DATA(ls_temp) = CORRESPONDING zclaims_auto( <fs_claim> MAPPING FROM ENTITY ).
        ls_temp-fscd_doc_no = lv_sim_doc.
        ls_temp-status = 'P'.
        INSERT ls_temp INTO TABLE mt_buffer.
      ENDIF.
    ENDLOOP.

    " 3. Return result using correct mapping for actions
    READ ENTITIES OF zi_claimsauto IN LOCAL MODE
      ENTITY Claim ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_refreshed).

    LOOP AT lt_refreshed ASSIGNING FIELD-SYMBOL(<fs_res>).
        APPEND VALUE #( %tky = <fs_res>-%tky %param = <fs_res> ) TO result.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

**********************************************************************
* SAVER CLASS
**********************************************************************
CLASS lsc_zi_claimsauto DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS finalize REDEFINITION.
    METHODS check_before_save REDEFINITION.
    METHODS save REDEFINITION.
    METHODS cleanup REDEFINITION.
    METHODS cleanup_finalize REDEFINITION.
ENDCLASS.

CLASS lsc_zi_claimsauto IMPLEMENTATION.

  METHOD finalize.
  ENDMETHOD.

  METHOD check_before_save.
  ENDMETHOD.

  METHOD save.
    " Final persistence to the DB table
    IF lhc_claim=>mt_buffer IS NOT INITIAL.
        MODIFY zclaims_auto FROM TABLE @lhc_claim=>mt_buffer.
    ENDIF.
  ENDMETHOD.

  METHOD cleanup.
    CLEAR lhc_claim=>mt_buffer.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
