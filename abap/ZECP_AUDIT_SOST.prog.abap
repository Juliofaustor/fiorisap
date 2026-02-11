REPORT zecp_audit_sost.

" ---------------------------------------------------------------------
" Reporte Z de auditoría de correos enviados en SAP ECP (fuente SOST)
" Enfoque práctico: lectura directa de SOOS + SOOD, salida ALV y filtros
" de auditoría para rango de fechas, estado, emisor y destinatario.
" ---------------------------------------------------------------------

TYPE-POOLS: icon.

TYPES: BEGIN OF ty_result,
         created_on     TYPE soos-crdat,
         created_at     TYPE soos-crtim,
         status         TYPE soos-state,
         sender_user    TYPE soos-owner,
         recipient      TYPE soos-recnam,
         recipient_type TYPE soos-rectyp,
         objtp          TYPE soos-objtp,
         objyr          TYPE soos-objyr,
         objno          TYPE soos-objno,
         subject        TYPE sood-objdes,
         priority       TYPE sood-prio,
       END OF ty_result.

DATA: gt_result TYPE STANDARD TABLE OF ty_result.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-t01.
  SELECT-OPTIONS:
    s_crdat FOR soos-crdat OBLIGATORY,
    s_state FOR soos-state,
    s_owner FOR soos-owner,
    s_recnm FOR soos-recnam,
    s_subj  FOR sood-objdes.
SELECTION-SCREEN END OF BLOCK b1.

INITIALIZATION.
  TEXT-t01 = 'Auditoría SOST (SAP ECP)'.

START-OF-SELECTION.
  PERFORM get_data.

END-OF-SELECTION.
  PERFORM display_alv.

FORM get_data.
  SELECT
    s~crdat       AS created_on,
    s~crtim       AS created_at,
    s~state       AS status,
    s~owner       AS sender_user,
    s~recnam      AS recipient,
    s~rectyp      AS recipient_type,
    s~objtp       AS objtp,
    s~objyr       AS objyr,
    s~objno       AS objno,
    o~objdes      AS subject,
    o~prio        AS priority
    FROM soos AS s
    INNER JOIN sood AS o
      ON o~objtp = s~objtp
     AND o~objyr = s~objyr
     AND o~objno = s~objno
    INTO TABLE @gt_result
    WHERE s~crdat IN @s_crdat
      AND s~state IN @s_state
      AND s~owner IN @s_owner
      AND s~recnam IN @s_recnm
      AND o~objdes IN @s_subj.

  IF sy-subrc <> 0.
    MESSAGE 'No se encontraron correos para los filtros seleccionados.' TYPE 'S'.
  ENDIF.
ENDFORM.

FORM display_alv.
  DATA: lo_alv  TYPE REF TO cl_salv_table,
        lo_cols TYPE REF TO cl_salv_columns_table,
        lo_col  TYPE REF TO cl_salv_column_table.

  TRY.
      cl_salv_table=>factory(
        IMPORTING r_salv_table = lo_alv
        CHANGING  t_table      = gt_result ).

      lo_cols = lo_alv->get_columns( ).
      lo_cols->set_optimize( abap_true ).

      lo_col ?= lo_cols->get_column( 'STATUS' ).
      lo_col->set_short_text( 'Est.' ).
      lo_col->set_medium_text( 'Estado' ).
      lo_col->set_long_text( 'Estado de envío SAPconnect' ).

      lo_col ?= lo_cols->get_column( 'SENDER_USER' ).
      lo_col->set_medium_text( 'Usuario emisor' ).

      lo_col ?= lo_cols->get_column( 'RECIPIENT' ).
      lo_col->set_medium_text( 'Destinatario' ).

      lo_col ?= lo_cols->get_column( 'SUBJECT' ).
      lo_col->set_medium_text( 'Asunto' ).

      lo_alv->get_functions( )->set_all( abap_true ).
      lo_alv->get_display_settings( )->set_list_header(
        'Reporte Z de auditoría de correos enviados (SOST)' ).
      lo_alv->display( ).

    CATCH cx_salv_msg INTO DATA(lx_salv).
      MESSAGE lx_salv->get_text( ) TYPE 'E'.
  ENDTRY.
ENDFORM.
