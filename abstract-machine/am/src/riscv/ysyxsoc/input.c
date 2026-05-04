#include <am.h>

#define KBD_BASE 0x10011000
#define BREAK_CODE 0xf0

static int code2amcode (int code) {
  switch (code)
  {
  case 0x76: return AM_KEY_ESCAPE; break;
  case 0x05: return AM_KEY_F1; break;
  case 0x06: return AM_KEY_F2; break;
  case 0x04: return AM_KEY_F3; break;
  case 0x0c: return AM_KEY_F4; break;
  case 0x03: return AM_KEY_F5; break;
  case 0x0b: return AM_KEY_F6; break;
  case 0x83: return AM_KEY_F7; break;
  case 0x0a: return AM_KEY_F8; break;
  case 0x01: return AM_KEY_F9; break;
  case 0x09: return AM_KEY_F10; break;
  case 0x70: return AM_KEY_F11; break;
  case 0x07: return AM_KEY_F12; break;
  case 0x0e: return AM_KEY_GRAVE; break;
  case 0x16: return AM_KEY_1; break;
  case 0x1e: return AM_KEY_2; break;
  case 0x26: return AM_KEY_3; break;
  case 0x25: return AM_KEY_4; break;
  case 0x2e: return AM_KEY_5; break;
  case 0x36: return AM_KEY_6; break;
  case 0x3d: return AM_KEY_7; break;
  case 0x3e: return AM_KEY_8; break;
  case 0x46: return AM_KEY_9; break;
  case 0x45: return AM_KEY_0; break;
  case 0x4e: return AM_KEY_MINUS; break;
  case 0x55: return AM_KEY_EQUALS; break;
  case 0x66: return AM_KEY_BACKSPACE; break;
  case 0x0d: return AM_KEY_TAB; break;
  case 0x15: return AM_KEY_Q; break;
  case 0x1d: return AM_KEY_W; break;
  case 0x24: return AM_KEY_E; break;
  case 0x2d: return AM_KEY_R; break;
  case 0x2c: return AM_KEY_T; break;
  case 0x35: return AM_KEY_Y; break;
  case 0x3c: return AM_KEY_U; break;
  case 0x43: return AM_KEY_I; break;
  case 0x44: return AM_KEY_O; break;
  case 0x4d: return AM_KEY_P; break;
  case 0x54: return AM_KEY_LEFTBRACKET; break;
  case 0x5b: return AM_KEY_RIGHTBRACKET; break;
  case 0x5d: return AM_KEY_BACKSLASH; break;
  case 0x58: return AM_KEY_CAPSLOCK; break;
  case 0x1c: return AM_KEY_A; break;
  case 0x1b: return AM_KEY_S; break;
  case 0x23: return AM_KEY_D; break;
  case 0x2b: return AM_KEY_F; break;
  case 0x34: return AM_KEY_G; break;
  case 0x33: return AM_KEY_H; break;
  case 0x3b: return AM_KEY_J; break;
  case 0x42: return AM_KEY_K; break;
  case 0x4b: return AM_KEY_L; break;
  case 0x4c: return AM_KEY_SEMICOLON; break;
  case 0x52: return AM_KEY_APOSTROPHE; break;
  case 0x5a: return AM_KEY_RETURN; break;
  case 0x12: return AM_KEY_LSHIFT; break;
  case 0x1a: return AM_KEY_Z; break;
  case 0x22: return AM_KEY_X; break;
  case 0x21: return AM_KEY_C; break;
  case 0x2a: return AM_KEY_V; break;
  case 0x32: return AM_KEY_B; break;
  case 0x31: return AM_KEY_N; break;
  case 0x3a: return AM_KEY_M; break;
  case 0x41: return AM_KEY_COMMA; break;
  case 0x49: return AM_KEY_PERIOD; break;
  case 0x4a: return AM_KEY_SLASH; break;
  case 0x59: return AM_KEY_RSHIFT; break;
  case 0x14: return AM_KEY_LCTRL; break;
  case 0x11: return AM_KEY_LALT; break;
  case 0x29: return AM_KEY_SPACE; break;
  default: return AM_KEY_SPACE;
    break;
  }
}

void __am_input_keybrd(AM_INPUT_KEYBRD_T *kbd) {
  kbd->keydown = 0;
  kbd->keycode = AM_KEY_NONE;
  uint32_t volatile scancode = *(uint32_t *)(KBD_BASE);
  if (scancode==BREAK_CODE)
  {
    kbd->keydown = 0;
    scancode = *(uint32_t *)(KBD_BASE);
    kbd->keycode = code2amcode(scancode);
  } else if (scancode==0)
  {
    kbd->keydown = 0;
    kbd->keycode = AM_KEY_NONE;
  } else {
    kbd->keydown = 1;
    kbd->keycode = code2amcode(scancode);
  }
  
}
