ENTRY(_start)
PHDRS { text PT_LOAD; data PT_LOAD;}
MEMORY {
  MROM : ORIGIN = 0x20000000, LENGTH = 0x1000
  flash : ORIGIN = 0x30000000, LENGTH = 0x10000000
  SRAM : ORIGIN = 0x0f000000, LENGTH = 0x2000
  PSRAM : ORIGIN = 0x80000000, LENGTH = 0x400000
}
SECTIONS {
  /* _pmem_start and _entry_offset are defined in LDFLAGS */
  . = _pmem_start + _entry_offset;
  .bootloader : {
    *(entry)
  } > flash

  .text : {
    _text_start = .;
    *(.text*)
    _text_end = .;
  } > flash : text
  .rodata : {
    *(.rodata*)
    *(.srodata*) /* for small read-only data */
  } > SRAM AT> flash
  _text_load = LOADADDR(.text);
  etext = .;
  _etext = .;
  .data : {
    _data_start = .;
    *(.data*)
    *(.sdata*) /* for small data */
    _data_end = .;
  } > SRAM AT> flash : data
  _data_load = LOADADDR(.data);
  .bss : {
	_bss_start = .;
    *(.bss*)
    *(.sbss*)
    *(.scommon)
  _bss_end = .;
  } >PSRAM
  /* _stack_top = ALIGN(4); */
  _heap_start = ALIGN(4);
  . = ORIGIN(PSRAM) + 0x100000;
  _heap_end = .;
  _stack_top = .;
  . = ORIGIN(PSRAM) + LENGTH(PSRAM);
  _stack_pointer = .;
  
}
