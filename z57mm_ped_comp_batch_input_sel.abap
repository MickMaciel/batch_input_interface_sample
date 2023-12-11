*&---------------------------------------------------------------------*
*&  Include  z57mm_ped_comp_batch_input_sel
*&---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b_main WITH FRAME TITLE TEXT-001.
PARAMETERS p_file TYPE string. "rlgrap-filename. <<< tive que converter depois. Declarei l_file antes de chamar FUNCTION 'TEXT_CONVERT_XLS_TO_SAP'
SELECTION-SCREEN END OF BLOCK b_main.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.
  cl_gui_frontend_services=>file_open_dialog(
    EXPORTING
     window_title            = 'Import Excel'    " Title Of File Open Dialog
     default_extension       =   'XLS*'  " Default Extension
*    default_filename        =     " Default File Name
*    file_filter             =     " File Extension Filter String
*    with_encoding           =     " File Encoding
*    initial_directory       =     " Initial Directory
*    multiselection          =     " Multiple selections poss.
    CHANGING
      file_table              = lt_file_tab    " Table Holding Selected Files
      rc                      = i_rc    " Return Code, Number of Files or -1 If Error Occurred
*    user_action             =     " User Action (See Class Constants ACTION_OK, ACTION_CANCEL)
*    file_encoding           =
    EXCEPTIONS
      file_open_dialog_failed = 1
      cntl_error              = 2
      error_no_gui            = 3
      not_supported_by_gui    = 4
      OTHERS                  = 5
  ).
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  TRY.

    p_file = lt_file_tab[ 1 ]-filename.

  CATCH cx_sy_itab_line_not_found.
  ENDTRY.

START-OF-SELECTION.

  CALL FUNCTION 'GUI_UPLOAD'
    EXPORTING
      filename                = p_file "lv_filename   " Name of file
      filetype                = 'DAT'    " File Type (ASC or BIN)
*     has_field_separator     = has_field_separator    " Columns Separated by Tabs in Case of ASCII Upload
*     header_length           = header_length    " Length of Header for Binary Data
*     read_by_line            = read_by_line    " The file will be written to the internal table line-by-line
*     dat_mode                = dat_mode    " Numeric and Date Fields Imported in ws_download 'DAT' Format
*     codepage                = codepage    " Character Representation for Output
*     ignore_cerr             = ignore_cerr    " Specifies whether to ignore errors converting character sets
*     replacement             = replacement    " Replacement Character for Non-Convertible Characters
*     check_bom               = check_bom    " The consistency of the codepage and byte order mark will be
*     virus_scan_profile      = virus_scan_profile    " Virus Scan Profile
*     no_auth_check           = no_auth_check    " Switch off Check for Access Rights
*    IMPORTING
*     filelength              = filelength    " File Length
*     header                  = header    " File Header in Case of Binary Upload
    TABLES
      data_tab                = it_excel    " Transfer table for file contents
*    CHANGING
*     isscanperformed         = isscanperformed    " File already scanned
    EXCEPTIONS
      file_open_error         = 1
      file_read_error         = 2
      no_batch                = 3
      gui_refuse_filetransfer = 4
      invalid_type            = 5
      no_authority            = 6
      unknown_error           = 7
      bad_data_format         = 8
      header_not_allowed      = 9
      separator_not_allowed   = 10
      header_too_long         = 11
      unknown_dp_error        = 12
      access_denied           = 13
      dp_out_of_memory        = 14
      disk_full               = 15
      dp_timeout              = 16
      OTHERS                  = 17.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  DATA(l_file) = CONV rlgrap-filename( p_file ).

  CALL FUNCTION 'TEXT_CONVERT_XLS_TO_SAP'
    EXPORTING
*     i_field_seperator    = i_field_seperator
      i_line_header        = abap_true
      i_tab_raw_data       = it_excel
      i_filename           = l_file
    TABLES
      i_tab_converted_data = it_tab_converted
    EXCEPTIONS
      conversion_failed    = 1
      OTHERS               = 2.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

END-OF-SELECTION.
  LOOP AT it_tab_converted INTO DATA(ls_ped_data).

    MOVE-CORRESPONDING ls_ped_data TO ls_bapi_ped.

    CALL TRANSACTION 'ZMM57_PEDIDOS' AND SKIP FIRST SCREEN.

    CALL FUNCTION 'ZF57_PED_COMP'
      EXPORTING  im_pedido = ls_bapi_ped  " Estrutura para registrar pedidos de compra.
                 im_modo   = 'U'          " C=Create;U=Update;D=Delete
      TABLES     bapiret   = lt_bapiret   " Return table
      EXCEPTIONS error     = 1
                 not_found = 2
                 OTHERS    = 3.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

  ENDLOOP.

  cl_salv_table=>factory( IMPORTING r_salv_table = lo_alv
                          CHANGING  t_table      = it_tab_converted ).
  lo_alv->get_functions( )->set_all( abap_true ).
  lo_alv->display( ).