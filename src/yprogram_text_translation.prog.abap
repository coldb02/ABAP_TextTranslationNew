*&---------------------------------------------------------------------*
*& Report YPROGRAM_TEXT_DOWNLOAD
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
*& https://github.com/coldb02/ABAP_TextTranslation ( Reference GITHUB
*& link of the latest version ( Abhinandan Dutt).
*&---------------------------------------------------------------------*
*& IF you do not know what id the word is all about then,
*& below is the Object Type reference in the final ALV
*& CA4  : GUI Title + Funcation Keys+ buttons
*& CAD4 : GUI Status
*& RPT4 : Selection screen + Text Element + Report Title
*& SRH4 : Screen Description
*& SRT4 : Screen text
*& TRAN : Transaction code description
*&
*& CA1  : GUI title +Funcation Keys+ buttons
*& CAD1 : GUI Status
*& FNC1 : Function module attributes + import export text
*& LBT1 : funcation group description
*& RPT1 : Text Element
*& SRH1 : Module pool scrren description
*& SRT4 : Screen text
*&---------------------------------------------------------------------*

REPORT yprogram_text_translation.

*--- download table data form table 'DD03M'

TABLES: rs38m, seoclass, tlibg, dd01l, dd03l, dd04l, t100.

TYPES: BEGIN OF ty_program,
         pname   TYPE programm,
         objtype TYPE lxeobjtype,
         objname TYPE lxeobjname,
         textkey TYPE lxetextkey,
         leng    TYPE sqllength,
         s_text  TYPE textpooltx,
         t_text  TYPE textpooltx,
       END OF ty_program,

       BEGIN OF ty_upload_data,
         pname       TYPE programm,
         objtype     TYPE lxeobjtype,
         objname     TYPE lxeobjname,
         textkey     TYPE lxetextkey,
         leng        TYPE sqllength,
         s_text_sys  TYPE textpooltx,
         s_text_prop TYPE textpooltx,
         t_text_sys  TYPE textpooltx,
         t_text_prop TYPE textpooltx,
       END OF ty_upload_data,

       BEGIN OF ty_upload_final,
         s_lang  TYPE lxeisolang,
         t_lang  TYPE lxeisolang,
         objtype TYPE lxeobjtype,
         objname TYPE lxeobjname,
         lxe_pcx TYPE lxe_tt_pcx_s1,
       END OF ty_upload_final.

DATA: gt_program      TYPE TABLE OF ty_program,
      gt_upload_data  TYPE TABLE OF ty_upload_data,
      gt_upload_final TYPE TABLE OF ty_upload_final,
      gs_program      TYPE ty_program,
      gs_upload_data  TYPE ty_upload_data,
      gs_upload_final TYPE ty_upload_final,
      gv_s_lang       TYPE lxeisolang,
      gv_t_lang       TYPE lxeisolang,
      gv_popaction    TYPE char1.

CLASS lcl_handler DEFINITION.

  PUBLIC SECTION.
    CLASS-METHODS: on_user_command FOR EVENT added_function OF cl_salv_events_table
      IMPORTING e_salv_function.

ENDCLASS.

SELECTION-SCREEN BEGIN OF BLOCK rad1 WITH FRAME TITLE TEXT-001.
  PARAMETERS: r1 RADIOBUTTON GROUP rad1 USER-COMMAND opt DEFAULT 'X',
              r2 RADIOBUTTON GROUP rad1,
              r3 RADIOBUTTON GROUP rad1,
              r4 RADIOBUTTON GROUP rad1,
              r5 RADIOBUTTON GROUP rad1,
              r6 RADIOBUTTON GROUP rad1,
              r7 RADIOBUTTON GROUP rad1.
SELECTION-SCREEN END OF BLOCK rad1.

SELECTION-SCREEN BEGIN OF BLOCK rad2 WITH FRAME TITLE TEXT-002.
  PARAMETERS:
    p_comp  AS CHECKBOX USER-COMMAND opt,
    p_genr  AS CHECKBOX USER-COMMAND opt MODIF ID a00,
    p_uplod AS CHECKBOX USER-COMMAND opt,
    p_file  TYPE localfile MODIF ID a01,
    p_slang TYPE spras DEFAULT sy-langu OBLIGATORY,
    p_tlang TYPE spras MODIF ID id0.

  SELECT-OPTIONS:
*-- Report and Module Pool progarm
    s_prgna  FOR rs38m-programm      MODIF ID id1 NO INTERVALS,

*-- Class
    s_class  FOR seoclass-clsname    MODIF ID id2 NO INTERVALS,

*-- Funcation Group
    s_fungp  FOR tlibg-area          MODIF ID id3 NO INTERVALS,

*-- DDIC table " Always look form data emelent with Z* because Y* can be standard
    s_tname1  FOR dd03l-tabname      MODIF ID id4 NO INTERVALS,
    s_datel1  FOR dd03l-rollname     MODIF ID id4 NO INTERVALS,
    s_domna1  FOR dd03l-domname      MODIF ID id4 NO INTERVALS,
*    s_datael  FOR dd03mm-rollname     MODIF ID id4 NO INTERVALS,

*-- DDIC data elements  " Always look for domain with Z* because Y* can be standard
    s_datael  FOR dd04l-rollname     MODIF ID id5 NO INTERVALS,

*-- DDIC Domain  " Always look for domain with Z* because Y* can be standard
    s_domnam  FOR dd01l-domname      MODIF ID id6 NO INTERVALS,

*-- Message class
    s_mess    FOR t100-arbgb         MODIF ID id7 NO INTERVALS.

SELECTION-SCREEN END OF BLOCK rad2.

AT SELECTION-SCREEN OUTPUT.
  PERFORM: screen_optput.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.
  PERFORM: f4_help_for_file.

AT SELECTION-SCREEN.
  PERFORM: baisc_validation.

START-OF-SELECTION.

  PERFORM:
    validate_screen_action,
    build_language_data,
    fetch_excel_data.

  CASE abap_true.
    WHEN r1.
      PERFORM: fetch_program_data.
    WHEN r2.
      PERFORM: fetch_class_data.
    WHEN r3.
      PERFORM: fetch_func_group_data.
    WHEN r4.
      PERFORM: fetch_ddic_table_data.
    WHEN r5.
      PERFORM: fetch_ddic_element_data.
    WHEN r6.
      PERFORM: fetch_ddic_domain_data.
    WHEN r7.
      PERFORM: fetch_message_data.
  ENDCASE.

END-OF-SELECTION.
  PERFORM: display_alv.

*&---------------------------------------------------------------------*
*& Form screen_optput
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM screen_optput .

*-- code for enabling Traget Language and Upload file.

  IF p_uplod = abap_true.
    LOOP AT SCREEN.
      CASE screen-group1.
        WHEN 'ID0' OR 'A01'.
          screen-active = 1.
          MODIFY SCREEN.
        WHEN 'A00'.
          screen-active = 0.
          MODIFY SCREEN.
      ENDCASE.
    ENDLOOP.

    p_comp = abap_true.
    p_genr = abap_false.

  ELSEIF p_comp = abap_true.
    LOOP AT SCREEN.
      CASE screen-group1.
        WHEN 'ID0' OR 'A00'.
          screen-active    = 1.
          MODIFY SCREEN.
        WHEN 'A01'.
          screen-active    = 0.
          MODIFY SCREEN.
      ENDCASE.
    ENDLOOP.

    p_uplod = abap_false.

  ELSE.
    LOOP AT SCREEN.
      CASE screen-group1.
        WHEN 'ID0' OR 'A00' OR 'A01'.
          screen-active    = 0.
          MODIFY SCREEN.
      ENDCASE.
    ENDLOOP.

    p_comp = p_uplod = p_genr = abap_false.

  ENDIF.

  LOOP AT SCREEN.
    CASE screen-group1.
      WHEN 'A00'.
        screen-active    = 0.
        MODIFY SCREEN.
    ENDCASE.
  ENDLOOP.

  CASE abap_true.
    WHEN r1.
      LOOP AT SCREEN.
        CASE screen-group1.
          WHEN 'ID2' OR 'ID3' OR 'ID4' OR 'ID5' OR 'ID6' OR 'ID7'.
            screen-active    = 0.
            MODIFY SCREEN.
        ENDCASE.
      ENDLOOP.

    WHEN r2.
      LOOP AT SCREEN.
        CASE screen-group1.
          WHEN 'ID1' OR 'ID3' OR 'ID4' OR 'ID5' OR 'ID6' OR 'ID7'.
            screen-active    = 0.
            MODIFY SCREEN.
        ENDCASE.
      ENDLOOP.

    WHEN r3.
      LOOP AT SCREEN.
        CASE screen-group1.
          WHEN 'ID1' OR 'ID2' OR 'ID4' OR 'ID5' OR 'ID6' OR 'ID7'.
            screen-active    = 0.
            MODIFY SCREEN.
        ENDCASE.
      ENDLOOP.

    WHEN r4.
      LOOP AT SCREEN.
        CASE screen-group1.
          WHEN 'ID1' OR 'ID2' OR 'ID3' OR 'ID5' OR 'ID6' OR 'ID7'.
            screen-active    = 0.
            MODIFY SCREEN.
        ENDCASE.
      ENDLOOP.

    WHEN r5.
      LOOP AT SCREEN.
        CASE screen-group1.
          WHEN 'ID1' OR 'ID2' OR 'ID3' OR 'ID4' OR 'ID6' OR 'ID7'.
            screen-active    = 0.
            MODIFY SCREEN.
        ENDCASE.
      ENDLOOP.

    WHEN r6.
      LOOP AT SCREEN.
        CASE screen-group1.
          WHEN 'ID1' OR 'ID2' OR 'ID3' OR 'ID4' OR 'ID5' OR 'ID7'.
            screen-active    = 0.
            MODIFY SCREEN.
        ENDCASE.
      ENDLOOP.

    WHEN r7.
      LOOP AT SCREEN.
        CASE screen-group1.
          WHEN 'ID1' OR 'ID2' OR 'ID3' OR 'ID4' OR 'ID5' OR 'ID6'.
            screen-active    = 0.
            MODIFY SCREEN.
        ENDCASE.
      ENDLOOP.

  ENDCASE.

  IF p_uplod IS INITIAL.
    CLEAR: p_file.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form f4_help_for_file
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f4_help_for_file .

  CALL FUNCTION 'F4_FILENAME'
    EXPORTING
      program_name  = syst-cprog
      dynpro_number = syst-dynnr
*     FIELD_NAME    = ' '
    IMPORTING
      file_name     = p_file.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form baisc_validation
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM baisc_validation .

  DATA: lv_extension(4) TYPE c.
  IF p_file IS NOT INITIAL.

    CALL FUNCTION 'TRINT_FILE_GET_EXTENSION'
      EXPORTING
        filename  = p_file
        uppercase = 'X'
      IMPORTING
        extension = lv_extension.
    IF lv_extension  = 'XLS'  OR lv_extension = 'XLSX' OR
       lv_extension  = 'XLSM'.
*       Do nothing.
    ELSE.
      MESSAGE: s006(/fti/ext_srv_maint) DISPLAY LIKE 'E'.
      STOP.
    ENDIF.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form validate_screen_action
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM validate_screen_action.

  IF ( p_comp IS NOT INITIAL AND p_tlang IS INITIAL ) OR  ( p_uplod IS NOT INITIAL AND p_tlang IS INITIAL ) .
    MESSAGE: TEXT-005 TYPE 'S' DISPLAY LIKE 'E'.  "Target Language can not be empty!
    LEAVE LIST-PROCESSING.
  ENDIF.

  IF p_uplod IS NOT INITIAL AND p_file IS INITIAL.
    MESSAGE: TEXT-006 TYPE 'S' DISPLAY LIKE 'E'.  "Upload File can not be empty
    LEAVE LIST-PROCESSING.
  ENDIF.

  IF p_uplod IS INITIAL.
    CLEAR: p_file.
  ENDIF.

  IF p_genr IS NOT INITIAL.

    DATA(lv_question) = TEXT-009   "Do you want to translation text from Google?
                        && | | &&
                        TEXT-010.  "Caution! Validate text before uploading.

    CLEAR: gv_popaction.

    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        titlebar       = TEXT-008  "Just out of Curiosity \(-_-)/
*       DIAGNOSE_OBJECT             = ' '
        text_question  = lv_question
        text_button_1  = TEXT-011
        icon_button_1  = '@4B@'
        text_button_2  = TEXT-012
        icon_button_2  = '@4C@'
      IMPORTING
        answer         = gv_popaction
      EXCEPTIONS
        text_not_found = 1
        OTHERS         = 2.

    CASE gv_popaction.
      WHEN '1'.  " All Texts
      WHEN '2'.  " Empty Texts
      WHEN 'A'.
        CLEAR: p_genr, gv_popaction.
    ENDCASE.

  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form build_language_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM build_language_data .

  DATA: lv_t_lang TYPE sy-langu.

  FREE: gt_program, gt_upload_data, gt_upload_final.
  CLEAR: gs_program, gs_upload_data, gs_upload_final, gv_s_lang, gv_t_lang.

  SELECT *
    FROM t002t
    INTO TABLE @DATA(lt_t002t)
   WHERE spras = @p_slang
     AND sprsl IN ( '1', 'C', 'D', 'E', 'F', 'H', 'P', 'Q', 'S', 'd'  ).
  IF sy-subrc = 0.
    LOOP AT lt_t002t INTO DATA(ls_t002t) WHERE sprsl <> p_slang.

      EXIT.
    ENDLOOP.
  ENDIF.

  PERFORM: fetch_source_traget_language USING    p_slang
                                        CHANGING gv_s_lang.

  IF p_tlang IS INITIAL.
    lv_t_lang = ls_t002t-sprsl.
    CLEAR: p_tlang.
  ELSE.
    lv_t_lang = p_tlang.
  ENDIF.

  PERFORM: fetch_source_traget_language USING    lv_t_lang
                                        CHANGING gv_t_lang.

  IF gv_s_lang = gv_t_lang.
    MESSAGE: TEXT-007 TYPE 'S' DISPLAY LIKE 'E'.   "Source and Target language can not be same
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form FETCH_SOURCE_TRAGET_LANGUAGE
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> P_SLANG
*&      <-- LV_S_LANG
*&      <-- LV_FLAG
*&---------------------------------------------------------------------*
FORM fetch_source_traget_language  USING    p_p_slang   TYPE syst-langu
                                   CHANGING p_lv_s_lang TYPE lxeisolang.

  CALL FUNCTION 'LXE_T002_CHECK_LANGUAGE'
    EXPORTING
      r3_lang            = p_p_slang
    IMPORTING
      o_language         = p_lv_s_lang
    EXCEPTIONS
      language_not_in_cp = 1
      unknown            = 2
      OTHERS             = 3.
  IF sy-subrc <> 0.
    MESSAGE TEXT-004 && ` ` && p_p_slang TYPE 'I'.  "Language not supported:
    LEAVE LIST-PROCESSING.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form fetch_excel_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM fetch_excel_data .

*-- Had to create the copy of the existing FM and the data type was modifed as well
*-- Structure       -->Field  -->Component Type
*-- YALSMEX_TABLINE -->VALUE  -->TEXTPOOLTX

  DATA: lv_upload TYPE rlgrap-filename,
        lt_excl   TYPE STANDARD TABLE OF yalsmex_tabline.

  FIELD-SYMBOLS: <lv_field> TYPE any.

  CHECK p_file IS NOT INITIAL.

  lv_upload = p_file.

*-- Copy of the original FM ALSM_EXCEL_TO_INTERNAL_TABLE
  CALL FUNCTION 'YALSM_EXCEL_TO_INTERNAL_TABLE'
    EXPORTING
      filename                = lv_upload
      i_begin_col             = 1
      i_begin_row             = 2
      i_end_col               = 8
      i_end_row               = 99999
    TABLES
      intern                  = lt_excl
    EXCEPTIONS
      inconsistent_parameters = 1
      upload_ole              = 2
      OTHERS                  = 3.
  IF sy-subrc <> 0.
    MESSAGE 'Error Uploading Excel' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ELSE.
    IF lt_excl[] IS INITIAL.
      MESSAGE 'Execl have no data' TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.
  ENDIF.
  REFRESH: gt_upload_data.
  CLEAR: gs_upload_data.
  LOOP AT lt_excl ASSIGNING FIELD-SYMBOL(<ls_data>).
    ASSIGN <ls_data>-value TO <lv_field>.
    CASE <ls_data>-col.
      WHEN 1 .
        gs_upload_data-pname       = <lv_field>.
      WHEN 2 .
        gs_upload_data-objtype     = <lv_field>.
      WHEN 3 .
        gs_upload_data-objname     = <lv_field>.
      WHEN 4 .
        gs_upload_data-textkey     = <lv_field>.
      WHEN 5 .
        gs_upload_data-leng        = <lv_field>.
      WHEN 6.
        gs_upload_data-s_text_prop = <lv_field>.
      WHEN 7.
        gs_upload_data-t_text_prop = <lv_field>.
    ENDCASE .
    AT END OF row.
      APPEND gs_upload_data TO gt_upload_data.
      CLEAR gs_upload_data.
    ENDAT.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form fetch_program_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM fetch_program_data .

  DATA: lv_trobj_name TYPE trobj_name.

*-- Validate if the Program name is valid or not

  CHECK s_prgna IS NOT INITIAL.

  SELECT *
    FROM progdir
    INTO TABLE @DATA(lt_progdir)
   WHERE name  IN @s_prgna
     AND state EQ 'A'.
  IF sy-subrc = 0.

*-- Fetch T-code name for the program
    SELECT DISTINCT
           a~*
      FROM tstc AS a INNER JOIN @lt_progdir AS b
        ON a~pgmna = b~name
      INTO TABLE @DATA(lt_tstc).
    IF sy-subrc <> 0.
      FREE: lt_tstc.
    ENDIF.

*-- Retrive data
    LOOP AT lt_progdir INTO DATA(ls_progdir).

      CLEAR: lv_trobj_name.
      lv_trobj_name = ls_progdir-name.
      PERFORM: fetch_build_txt_data USING 'R3TR' 'PROG' lv_trobj_name.

      LOOP AT lt_tstc INTO DATA(ls_tstc) WHERE pgmna = ls_progdir-name.
        CLEAR: lv_trobj_name.
        lv_trobj_name = ls_tstc-tcode.
        PERFORM: fetch_build_txt_data USING 'R3TR' 'TRAN' lv_trobj_name.
      ENDLOOP.

    ENDLOOP.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form fetch_class_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM fetch_class_data.

  DATA: lv_trobj_name TYPE trobj_name.

*-- Validate if the Class name is valid or not

  CHECK s_class IS NOT INITIAL.

  SELECT *
    FROM seoclass
    INTO TABLE @DATA(lt_seoclass)
   WHERE clsname IN @s_class.
  IF sy-subrc = 0.

*-- Retrive data
    LOOP AT lt_seoclass INTO DATA(ls_seoclass).

      CLEAR: lv_trobj_name.
      lv_trobj_name = ls_seoclass-clsname.
      PERFORM: fetch_build_txt_data USING 'R3TR' 'CLAS' lv_trobj_name.

    ENDLOOP.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form fetch_func_group_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM fetch_func_group_data .

  DATA: lv_trobj_name TYPE trobj_name,
        lv_funcname	  TYPE rs38l_fnam,
        lv_group      TYPE rs38l_area,
        lv_include    TYPE progname,
        lv_pname      TYPE pname,
        lv_namespace  TYPE namespace,
        lv_area       TYPE rs38l_area.

*-- Validate if the Funcation group is valid or not

  CHECK s_fungp IS NOT INITIAL.

  SELECT *
    FROM tlibg
    INTO TABLE @DATA(lt_tlibg)
   WHERE area IN @s_fungp.
  IF sy-subrc = 0.

*-- Retrive data
    LOOP AT lt_tlibg INTO DATA(ls_tlibg).

*-- Fetch Function group's program form Funcation group.
      CLEAR: lv_pname, lv_funcname, lv_group, lv_include,
             lv_namespace, lv_area.

      lv_group = ls_tlibg-area.
      CALL FUNCTION 'FUNCTION_INCLUDE_INFO'
        IMPORTING
*         FUNCTAB             =
*         NAMESPACE           =
          pname               = lv_pname
        CHANGING
          funcname            = lv_funcname
          group               = lv_group
          include             = lv_include
        EXCEPTIONS
          function_not_exists = 1
          include_not_exists  = 2
          group_not_exists    = 3
          no_selections       = 4
          no_function_include = 5
          OTHERS              = 6.
      IF sy-subrc <> 0.
        CALL FUNCTION 'FUNCTION_INCLUDE_SPLIT'
          EXPORTING
            complete_area = lv_group
          IMPORTING
            namespace     = lv_namespace
            group         = lv_area
          EXCEPTIONS ##FM_SUBRC_OK
            OTHERS        = 6.
        CONCATENATE lv_namespace 'SAPL' lv_area INTO lv_pname.
      ENDIF.

      SELECT *
        FROM tstc
        INTO TABLE @DATA(lt_tstc)
       WHERE pgmna EQ @lv_pname.
      IF sy-subrc = 0.
        LOOP AT lt_tstc INTO DATA(ls_tstc).
          CLEAR: lv_trobj_name.
          lv_trobj_name = ls_tstc-tcode.
          PERFORM: fetch_build_txt_data USING 'R3TR' 'TRAN' lv_trobj_name.
        ENDLOOP.
        FREE: lt_tstc.
      ENDIF.


      CLEAR: lv_trobj_name.
      lv_trobj_name = ls_tlibg-area.
      PERFORM: fetch_build_txt_data USING 'R3TR' 'FUGR' lv_trobj_name.

    ENDLOOP.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form fetch_ddic_table_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM fetch_ddic_table_data .

  DATA: lv_trobj_name TYPE trobj_name.

*-- Validate if the Funcation group is valid or not
  CHECK s_tname1 IS NOT INITIAL.

  SELECT *
    FROM dd03l
    INTO TABLE @DATA(lt_dd03l)
   WHERE tabname  IN @s_tname1
     AND as4local EQ 'A'
     AND rollname IN @s_datel1
     AND domname  IN @s_domna1.
  IF sy-subrc = 0.

*-- Retrive data
    LOOP AT lt_dd03l INTO DATA(ls_dd03l).

      AT NEW tabname.
*--   For every new table name.
        CLEAR: lv_trobj_name.
        lv_trobj_name = ls_dd03l-tabname.
        PERFORM: fetch_build_txt_data USING 'LIMU' 'TABD' lv_trobj_name.
      ENDAT.

*-- For Each Data Element
      CLEAR: lv_trobj_name.
      lv_trobj_name = ls_dd03l-rollname.
      PERFORM: fetch_build_txt_data USING 'LIMU' 'DTED' lv_trobj_name.

*-- for each Domain
      IF ls_dd03l-domname IS NOT INITIAL.
        CLEAR: lv_trobj_name.
        lv_trobj_name = ls_dd03l-domname.
        PERFORM: fetch_build_txt_data USING 'LIMU' 'DOMD' lv_trobj_name.
      ENDIF.

    ENDLOOP.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form fetch_ddic_element_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM fetch_ddic_element_data .

  DATA: lv_trobj_name TYPE trobj_name.

  CHECK s_datael IS NOT INITIAL.

  SELECT *
    FROM dd04l
    INTO TABLE @DATA(lt_dd04l)
   WHERE rollname IN @s_datael
     AND as4local EQ 'A'.
  IF sy-subrc = 0.
*-- Retrive data
    LOOP AT lt_dd04l INTO DATA(ls_dd04l).

      CLEAR: lv_trobj_name.
      lv_trobj_name = ls_dd04l-rollname.
      PERFORM: fetch_build_txt_data USING 'LIMU' 'DTED' lv_trobj_name.

    ENDLOOP.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form fetch_ddic_domain_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM fetch_ddic_domain_data .

  DATA: lv_trobj_name TYPE trobj_name.

  CHECK s_domnam IS NOT INITIAL.

  SELECT *
    FROM dd01l
    INTO TABLE @DATA(lt_dd01l)
   WHERE domname  IN @s_domnam
     AND as4local EQ 'A'.
  IF sy-subrc = 0.
*-- Retrive data
    LOOP AT lt_dd01l INTO DATA(ls_dd01l).

      CLEAR: lv_trobj_name.
      lv_trobj_name = ls_dd01l-domname.
      PERFORM: fetch_build_txt_data USING 'LIMU' 'DOMD' lv_trobj_name.

    ENDLOOP.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form fetch_message_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM fetch_message_data .

  DATA: lv_trobj_name TYPE trobj_name.

*-- Validate if the Class name is valid or not

  CHECK s_mess IS NOT INITIAL.

  SELECT DISTINCT
         sprsl,
         arbgb
    FROM t100
    INTO TABLE @DATA(lt_t100)
   WHERE sprsl EQ @p_slang
     AND arbgb IN @s_mess.
  IF sy-subrc = 0.

*-- Retrive data
    LOOP AT lt_t100 INTO DATA(ls_t100).

      CLEAR: lv_trobj_name.
      lv_trobj_name = ls_t100-arbgb.
      PERFORM: fetch_build_txt_data USING 'R3TR' 'MSAG' lv_trobj_name.

    ENDLOOP.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form fetch_build_txt_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> P_
*&      --> P_
*&      --> LV_TROBJ_NAME
*&---------------------------------------------------------------------*
FORM fetch_build_txt_data  USING p_pgmid    TYPE pgmid
                                 p_object   TYPE trobjtype
                                 p_trobj_name TYPE trobj_name.

  DATA:
    lt_colob    TYPE TABLE  OF lxe_colob,
    lv_err_msg  TYPE lxestring,
    lv_objtype  TYPE lxeobjtype,
    lv_objname  TYPE lxeobjname,
    lt_pcx_s1   TYPE TABLE OF lxe_pcx_s1,
    lt_pcx_s1_c TYPE TABLE OF lxe_pcx_s1.

  FREE: lt_colob.

  CALL FUNCTION 'LXE_OBJ_EXPAND_TRANSPORT_OBJ'
    EXPORTING
      pgmid           = p_pgmid
      object          = p_object
      obj_name        = p_trobj_name
    TABLES
*     in_e071k        =
      ex_colob        = lt_colob
    EXCEPTIONS
      unknown_object  = 1
      unknown_ta_type = 2
      OTHERS          = 3.
  IF sy-subrc = 0.
    IF lt_colob IS NOT INITIAL.

*-- Text from source to target Langauge "Happy case
      LOOP AT lt_colob INTO DATA(ls_colob).

        CLEAR: lv_objtype, lv_objname, lv_err_msg, gs_program.
        FREE: lt_pcx_s1_c, lt_pcx_s1.

        lv_objtype = ls_colob-objtype.
        lv_objname = ls_colob-objname.

        PERFORM: lxe_obj_text_pair_read TABLES lt_pcx_s1 USING gv_s_lang gv_t_lang lv_objtype lv_objname abap_true.

        IF lt_pcx_s1 IS NOT INITIAL.
          LOOP AT lt_pcx_s1 INTO DATA(ls_pcx_s1).
            gs_program-pname   = p_trobj_name.
            gs_program-objtype = lv_objtype.
            gs_program-objname = lv_objname.
            gs_program-textkey = ls_pcx_s1-textkey.
            gs_program-leng    = ls_pcx_s1-unitmlt.
            gs_program-s_text  = ls_pcx_s1-s_text.
            gs_program-t_text  = ls_pcx_s1-t_text.

            APPEND gs_program TO gt_program.
*-- case when Upload file is provided move data to UPLOAD_DATA and UPLOAD_final toble for further use.
            IF p_uplod IS NOT INITIAL.
*-- Read through the internal table and add the reords to the UPLOAD table
*--           Level 1: Check with all primary keys
              READ TABLE gt_upload_data ASSIGNING FIELD-SYMBOL(<lfs_upload_data>) WITH KEY pname    = p_trobj_name
                                                                                           objtype  = lv_objtype
                                                                                           objname  = lv_objname
                                                                                           textkey  = ls_pcx_s1-textkey.
              IF sy-subrc = 0.
                <lfs_upload_data>-s_text_sys = ls_pcx_s1-s_text.
                <lfs_upload_data>-t_text_sys = ls_pcx_s1-t_text.
              ELSE.
*--             Level 2: check with primary keys and the Source text
                READ TABLE gt_upload_data ASSIGNING <lfs_upload_data> WITH KEY pname       = p_trobj_name
                                                                               objtype     = lv_objtype
                                                                               objname     = lv_objname
                                                                               s_text_prop = ls_pcx_s1-s_text.
                IF sy-subrc = 0.
                  <lfs_upload_data>-s_text_sys = ls_pcx_s1-s_text.
                  <lfs_upload_data>-t_text_sys = ls_pcx_s1-t_text.
                ELSE.
*--               Level 3: check with Program and Source text
                  READ TABLE gt_upload_data ASSIGNING <lfs_upload_data> WITH KEY pname       = p_trobj_name
                                                                                 s_text_prop = ls_pcx_s1-s_text.
                  IF sy-subrc = 0.
                    <lfs_upload_data>-s_text_sys = ls_pcx_s1-s_text.
                    <lfs_upload_data>-t_text_sys = ls_pcx_s1-t_text.
                  ENDIF.

                ENDIF.

              ENDIF.
              IF <lfs_upload_data> IS ASSIGNED.

                DATA(lv_len) = strlen( <lfs_upload_data>-t_text_prop ).
                IF lv_len GE ls_pcx_s1-unitmlt.
                  <lfs_upload_data>-t_text_prop = <lfs_upload_data>-t_text_prop+0(ls_pcx_s1-unitmlt).
                ENDIF.

                lt_pcx_s1_c = VALUE #( BASE lt_pcx_s1_c ( textkey  = ls_pcx_s1-textkey
                                                          s_text   = ls_pcx_s1-s_text
                                                          t_text   = <lfs_upload_data>-t_text_prop
                                                          unitmlt  = ls_pcx_s1-unitmlt
                                                          uppcase  = ls_pcx_s1-uppcase
                                                          texttype = ls_pcx_s1-texttype ) ).

              ENDIF.

            ENDIF.

            CLEAR: gs_program, ls_pcx_s1.
          ENDLOOP.

          IF lt_pcx_s1_c IS NOT INITIAL.
            gt_upload_final = VALUE #( BASE gt_upload_final ( s_lang  = gv_s_lang
                                                              t_lang  = gv_t_lang
                                                              objtype = lv_objtype
                                                              objname = lv_objname
                                                              lxe_pcx = lt_pcx_s1_c ) ).
          ENDIF.

        ENDIF.

*-- Text from Target to Source Langauge "Sad case
*-- Will only happen when Source langauge of the Report/Program/Funcation Group/Message class
        IF p_comp IS NOT INITIAL AND p_uplod IS INITIAL AND 1 = 2.

          PERFORM: lxe_obj_text_pair_read TABLES lt_pcx_s1 USING gv_t_lang gv_s_lang lv_objtype lv_objname abap_true.

          IF lt_pcx_s1 IS NOT INITIAL.
            LOOP AT lt_pcx_s1 INTO ls_pcx_s1.
              IF NOT line_exists( gt_program[ pname   = p_trobj_name
                                              objtype = lv_objtype
                                              objname = lv_objname
                                              textkey = ls_pcx_s1-textkey ] ).
                gs_program-pname   = p_trobj_name.
                gs_program-objtype = lv_objtype.
                gs_program-objname = lv_objname.
                gs_program-textkey = ls_pcx_s1-textkey.
                gs_program-leng    = ls_pcx_s1-unitmlt.
                gs_program-s_text  = ls_pcx_s1-s_text.
                gs_program-t_text  = ls_pcx_s1-t_text.

                APPEND gs_program TO gt_program.
              ENDIF.
              CLEAR: gs_program, ls_pcx_s1.
            ENDLOOP.
          ENDIF.
        ENDIF.
        CLEAR: ls_colob.
      ENDLOOP.
    ENDIF.
  ELSE.
    DATA(lv_message) = TEXT-015 && p_trobj_name.
    MESSAGE: lv_message TYPE 'S' DISPLAY LIKE 'E'.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form lxe_obj_text_pair_read
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LT_PCX_S1
*&      --> GV_S_LANG
*&      --> GV_T_LANG
*&      --> LV_OBJTYPE
*&      --> LV_OBJNAME
*&---------------------------------------------------------------------*
FORM lxe_obj_text_pair_read  TABLES p_lt_pcx_s1  TYPE STANDARD TABLE
                             USING  p_lv_s_lang  TYPE lxeisolang
                                    p_lv_t_lang  TYPE lxeisolang
                                    p_lv_objtype TYPE lxeobjtype
                                    p_lv_objname TYPE lxeobjname
                                    p_read_only  TYPE char1.

  DATA: lv_err_msg TYPE lxestring,
        lv_pstatus TYPE lxestatprc.

  FREE: p_lt_pcx_s1.

  CALL FUNCTION 'LXE_OBJ_TEXT_PAIR_READ'
    EXPORTING
      t_lang    = p_lv_t_lang
      s_lang    = p_lv_s_lang
      custmnr   = '999999'
      objtype   = p_lv_objtype
      objname   = p_lv_objname
      read_only = p_read_only
*     BYPASS_ATTR_BUFFER = 'X'
*     KEEP_ATTR_BUFFER   = ''
    IMPORTING
*     COLLTYP   =
*     COLLNAM   =
*     DOMATYP   =
*     DOMANAM   =
      pstatus   = lv_pstatus
*     O_LANG    =
      err_msg   = lv_err_msg
    TABLES
      lt_pcx_s1 = p_lt_pcx_s1.

  IF lv_pstatus = cl_lxe_constants=>c_process_status_failure..
    IF lv_err_msg IS NOT INITIAL.
*      MESSAGE: lv_err_msg TYPE 'i'.
*      LEAVE LIST-PROCESSING.

    ELSE.
*      MESSAGE: TEXT-018 TYPE 'I'.
*      LEAVE LIST-PROCESSING.
    ENDIF.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form display_alv
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM display_alv .

  DATA: ls_layout_settings TYPE REF TO cl_salv_layout,
        ls_layout_key      TYPE salv_s_layout_key,
        lr_column          TYPE REF TO cl_salv_column.

  IF gt_program IS NOT INITIAL.

    SORT gt_program BY pname   ASCENDING objtype ASCENDING
                       objname ASCENDING textkey ASCENDING
                       s_text  ASCENDING s_text  ASCENDING .

    IF p_file IS INITIAL.
      DELETE ADJACENT DUPLICATES FROM gt_program COMPARING pname objtype objname textkey s_text.

      DATA(lv_lines) = lines( gt_program ).
      DATA(lv_message) = |{ TEXT-003 }| & | - | & |{ lv_lines }|.

    ELSE.
      LOOP AT gt_upload_final INTO DATA(ls_upload_final).
        lv_lines = lv_lines + lines( ls_upload_final-lxe_pcx ).
      ENDLOOP.

      lv_message = |{ TEXT-013 }| & | - | & |{ lv_lines }|.

    ENDIF.

    IF line_exists( gt_upload_data[ s_text_sys = ' ' ] ) AND p_file IS NOT INITIAL.
      MESSAGE: TEXT-014 TYPE 'I'.
    ENDIF.

    MESSAGE: lv_message TYPE 'S'.

    SELECT DISTINCT
           a~spras,
           b~sptxt
      FROM t002 AS a INNER JOIN t002t AS b
        ON a~spras = b~sprsl
     WHERE a~spras IN ( @p_slang, @p_tlang )
       AND b~spras EQ @sy-langu
      INTO TABLE @DATA(lt_t002).


    TRY.

        IF p_file IS INITIAL.
          CALL METHOD cl_salv_table=>factory
            EXPORTING
              list_display = if_salv_c_bool_sap=>false
*             r_container  =
*             container_name =
            IMPORTING
              r_salv_table = DATA(lr_alv)
            CHANGING
              t_table      = gt_program.


          lr_alv->set_screen_status(
            pfstatus      = 'STANDARD'
            report        = sy-repid
            set_functions = lr_alv->c_functions_all ).

        ELSE.
          CALL METHOD cl_salv_table=>factory
            EXPORTING
              list_display = if_salv_c_bool_sap=>false
*             r_container  = COND
*             container_name =
            IMPORTING
              r_salv_table = lr_alv
            CHANGING
              t_table      = gt_upload_data.

          lr_alv->set_screen_status(
            pfstatus      = 'STANDARD_FILE'
            report        = sy-repid
            set_functions = lr_alv->c_functions_all ).

        ENDIF.

        DATA(lr_event) = lr_alv->get_event( ).
        SET HANDLER lcl_handler=>on_user_command FOR lr_event.

*        DATA(lr_functions) = lr_alv->get_functions( ).
*        lr_functions->set_all( abap_true ).

        ls_layout_settings = lr_alv->get_layout( ).

        ls_layout_key-report = sy-repid.
        ls_layout_settings->set_key( ls_layout_key ).
        ls_layout_settings->set_default( value = 'X' ).

        ls_layout_settings->set_save_restriction( if_salv_c_layout=>restrict_none ).

        DATA(lr_columns) = lr_alv->get_columns( ).
        lr_columns->set_optimize( ).

        TRY.
            IF p_file IS INITIAL.
              lr_column ?= lr_columns->get_column( 'S_TEXT' ) ##NO_TEXT.
              lr_column->set_short_text( ' ' ) ##NO_TEXT.
              lr_column->set_medium_text( ' ' ) ##NO_TEXT.
              lr_column->set_long_text( CONV #( |Source Text-| & |{ VALUE #( lt_t002[ spras = p_slang ]-sptxt OPTIONAL ) }| ) ) ##NO_TEXT.

              lr_column ?= lr_columns->get_column( 'T_TEXT' ) ##NO_TEXT.
              lr_column->set_short_text( ' ' ) ##NO_TEXT.
              lr_column->set_medium_text( ' ' ) ##NO_TEXT.
              lr_column->set_long_text( CONV #( |Target Text-| & |{ VALUE #( lt_t002[ spras = p_tlang ]-sptxt OPTIONAL ) }| ) ) ##NO_TEXT.

              IF p_comp = abap_false.
                lr_column->set_visible( if_salv_c_bool_sap=>false ).
              ELSE.
                lr_column->set_visible( if_salv_c_bool_sap=>true ).
              ENDIF.

            ELSE.

              lr_column ?= lr_columns->get_column( 'S_TEXT_SYS' ) ##NO_TEXT.
              lr_column->set_short_text( ' ' ) ##NO_TEXT.
              lr_column->set_medium_text( ' ' ) ##NO_TEXT.
              lr_column->set_long_text( CONV #( |Source System Text-| & |{ VALUE #( lt_t002[ spras = p_slang ]-sptxt OPTIONAL ) }| ) ) ##NO_TEXT.

              lr_column ?= lr_columns->get_column( 'S_TEXT_PROP' ) ##NO_TEXT.
              lr_column->set_short_text( ' ' ) ##NO_TEXT.
              lr_column->set_medium_text( ' ' ) ##NO_TEXT.
              lr_column->set_long_text( CONV #( |Source Porposed Text-| & |{ VALUE #( lt_t002[ spras = p_slang ]-sptxt OPTIONAL ) }| ) ) ##NO_TEXT.

              lr_column ?= lr_columns->get_column( 'T_TEXT_SYS' ) ##NO_TEXT.
              lr_column->set_short_text( ' ' ) ##NO_TEXT.
              lr_column->set_medium_text( ' ' ) ##NO_TEXT.
              lr_column->set_long_text( CONV #( |Target System Text-| & |{ VALUE #( lt_t002[ spras = p_tlang ]-sptxt OPTIONAL ) }| ) ) ##NO_TEXT.

              lr_column ?= lr_columns->get_column( 'T_TEXT_PROP' ) ##NO_TEXT.
              lr_column->set_short_text( ' ' ) ##NO_TEXT.
              lr_column->set_medium_text( ' ' ) ##NO_TEXT.
              lr_column->set_long_text( CONV #( |Target Porposed Text-| & |{ VALUE #( lt_t002[ spras = p_tlang ]-sptxt OPTIONAL ) }| ) ) ##NO_TEXT.

            ENDIF.

          CATCH cx_salv_not_found INTO DATA(lv_not_found).
            " error handling
        ENDTRY.

      CATCH cx_salv_msg .
    ENDTRY.

    lr_alv->display( ). "display grid

  ELSE.
    MESSAGE: s001(/accgo/acm_uis_corrc) DISPLAY LIKE 'E'.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Class (Implementation) lcl_handler
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
CLASS lcl_handler IMPLEMENTATION.

  METHOD: on_user_command.

    DATA: lv_lxestatprc TYPE lxestatprc,
          lv_lxestring  TYPE lxestring,
          lt_pcx_s1     TYPE TABLE OF lxe_pcx_s1.

    CASE e_salv_function.
      WHEN '&SAVE'.
        LOOP AT gt_upload_final INTO DATA(ls_upload_final).

          CLEAR: lv_lxestatprc, lv_lxestring.

*--       Trigger 'LXE_OBJ_TEXT_PAIR_READ' FM to build possible Global data

          PERFORM: lxe_obj_text_pair_read TABLES lt_pcx_s1 USING ls_upload_final-s_lang
                                                                 ls_upload_final-t_lang
                                                                 ls_upload_final-objtype
                                                                 ls_upload_final-objname
                                                                 abap_false.
          CHECK lt_pcx_s1 IS NOT INITIAL.

          CALL FUNCTION 'LXE_OBJ_TEXT_PAIR_WRITE'
            EXPORTING
              t_lang    = ls_upload_final-t_lang
              s_lang    = ls_upload_final-s_lang
              custmnr   = '999999'
              objtype   = ls_upload_final-objtype
              objname   = ls_upload_final-objname
*             AUTODIST  =
*             RFC_COPY  =
            IMPORTING
              pstatus   = lv_lxestatprc
              err_msg   = lv_lxestring
            TABLES
              lt_pcx_s1 = ls_upload_final-lxe_pcx.
          IF lv_lxestatprc <> 'S'.
            IF lv_lxestring IS NOT INITIAL.
              MESSAGE lv_lxestring TYPE 'I'.
              EXIT.
            ELSE.
              MESSAGE: TEXT-017 TYPE 'I'.
            ENDIF.
          ELSE.
            MESSAGE: TEXT-016 TYPE 'S'.
          ENDIF.

        ENDLOOP.

    ENDCASE.
  ENDMETHOD.

ENDCLASS.
