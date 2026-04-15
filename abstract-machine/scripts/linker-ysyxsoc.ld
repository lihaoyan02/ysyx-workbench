ENTRY(_start)
PHDRS { text PT_LOAD; data PT_LOAD; }
MEMORY {
  MROM : ORIGIN = 0x20000000, LENGTH = 0x1000
  SRAM : ORIGIN = 0x0f000000, LENGTH = 0x2000
}
SECTIONS {
  /* _pmem_start and _entry_offset are defined in LDFLAGS */
  . = _pmem_start + _entry_offset;
  .text : {
    *(entry)
    *(.text*)
  } > MROM : text
  etext = .;
  _etext = .;
  .rodata : {
    *(.rodata*)
  } > MROM
  .data : {
    *(.data*)
  } > MROM : data
  edata = .;
  _data = .;
  .bss : {
	_bss_start = .;
    *(.bss*)
    *(.sbss*)
    *(.scommon)
  } >SRAM
  /* _stack_top = ALIGN(4); */
  . = ORIGIN(SRAM) + LENGTH(SRAM);
  _stack_pointer = .;
  _heap_start = .;
  _heap_end = .;
}
