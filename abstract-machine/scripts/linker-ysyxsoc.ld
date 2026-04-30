ENTRY(_start)
PHDRS { fsbl PT_LOAD; ssbl PT_LOAD; text PT_LOAD; dataex PT_LOAD; data PT_LOAD;}
MEMORY {
  MROM : ORIGIN = 0x20000000, LENGTH = 0x1000
  flash : ORIGIN = 0x30000000, LENGTH = 0x10000000
  SRAM : ORIGIN = 0x0f000000, LENGTH = 0x2000
  PSRAM : ORIGIN = 0x80000000, LENGTH = 0x400000
  SDRAM : ORIGIN = 0xa0000000, LENGTH = 0x4000000
}
SECTIONS {
  /* _pmem_start and _entry_offset are defined in LDFLAGS */
  . = _pmem_start + _entry_offset;
  .fsbootloader : {
    *(entry)
  } > flash : fsbl

  .ssbl : {
    _ssbl_start = .;
    *(ssbl)
    _ssbl_end = .;
  } > SRAM AT> flash : ssbl
  _ssbl_load = LOADADDR(.ssbl);

  .text : {
    _text_start = .;
    *(.text*)
    *(.rodata*)
    *(.srodata*) /* for small read-only data */
    _text_end = .;
  } > PSRAM AT> flash : text
  _text_load = LOADADDR(.text);
  etext = .;
  _etext = .;

  /* . = LOADADDR(.text) + LENGTH(.text); */
  .data.extra : {
    _data_ex_start = .;
    /* section information for finsh shell */
    __fsymtab_start = .;
    KEEP(*(FSymTab))
    __fsymtab_end = .;
    . = ALIGN(8);
    __vsymtab_start = .;
    KEEP(*(VSymTab))
    __vsymtab_end = .;
    . = ALIGN(8);

    /* section information for initial. */
    . = ALIGN(8);
    __rt_init_start = .;
    KEEP(*(SORT(.rti_fn*)))
    __rt_init_end = .;
    . = ALIGN(8);

    __rt_utest_tc_tab_start = .;
    KEEP(*(UtestTcTab))
    __rt_utest_tc_tab_end = .;

    . = ALIGN(8);
    __am_apps_data_start = .;
    *(__am_apps.data*)
    *(__am_apps.sdata*)
    __am_apps_data_end = .;
    _data_ex_end = .;
    . = ALIGN(8);
  } > PSRAM AT> flash : dataex
  _data_ex_load = LOADADDR(.data.extra);

  .data : {
    _data_start = .;
    *(.data)
    *(.data*)
    *(.sdata*) /* for small data */
    _data_end = .;
  } > PSRAM AT> flash : data
  _data_load = LOADADDR(.data);

  .bss.extra : {
    . = ALIGN(8);
    __am_apps_bss_start = .;
    *(__am_apps.bss*)
    *(__am_apps.sbss*)
    *(__am_apps.scommon*)
    __am_apps_bss_end = .;
    . = ALIGN(8);
  } > PSRAM

  .bss : {
	_bss_start = .;
    *(.bss*)
    *(.sbss*)
    *(.scommon)
  _bss_end = .;
  } >PSRAM

  

  _stack_top = ALIGN(4);
  . = ORIGIN(PSRAM) + LENGTH(PSRAM);
  _stack_pointer = .;

  _heap_start = ORIGIN(SDRAM);
  . = ORIGIN(SDRAM) + 0x1000000;
  _heap_end = .;
  
}
