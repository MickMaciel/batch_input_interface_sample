*&---------------------------------------------------------------------*
*&  Include  z57mm_ped_comp_batch_input_top
*&---------------------------------------------------------------------*
TYPE-POOLS: truxs.

DATA it_excel    TYPE truxs_t_text_data.
DATA lt_file_tab TYPE filetable.
DATA i_rc        TYPE i.

TYPES:
  BEGIN OF ty_excel,
    pedido      TYPE ztb57mm_pedido-pedido,
    fornecedor  TYPE ztb57mm_pedido-fornecedor,
    tipo_pedido TYPE ztb57mm_pedido-tipo_pedido,
    data_pedido TYPE c LENGTH 10,
  END OF ty_excel.

DATA: it_tab_converted TYPE TABLE OF ty_excel,
      lt_bapiret       TYPE bapiret2_t,
      ls_bapi_ped      TYPE zs57mm_pedido.
DATA lo_alv TYPE REF TO cl_salv_table.