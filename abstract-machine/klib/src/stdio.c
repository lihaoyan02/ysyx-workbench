#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

int printf(const char *fmt, ...) {
	char out[128];
	va_list ap;
	va_start(ap, fmt);
	int ret = vsprintf(out, fmt, ap);
	va_end(ap);
	for (const char *p = out; *p; p++) {
		putch(*p);
	}
	return ret;
  panic("Not implemented");
}

int vsprintf(char *out, const char *fmt, va_list ap) {
	char *start = out;
	while (*fmt) {
		if (*fmt == '%') {
			fmt++;
			switch (*fmt++) {
				case 'c':
					char charct = va_arg(ap, int);
					*out++ = charct;
					break;
				case 's':
					char *str = va_arg(ap, char *);
					while (*str) {
						*out++ = *str++;
					}
					break;
				case 'd':
					int value = va_arg(ap, int);
					if (value < 0) {
						*out++ = '-';
						value = -value;
					}
					char buffer[32];
					char *ptr = buffer;
					do {
						*ptr++ = '0' + (value % 10);
						value /= 10;
					} while (value > 0);
					while (buffer != ptr) {
						*out++ = *--ptr;
					}
					break;
				case '%':
					*out++ = '%';
					break;
				default: panic("Not implemented"); 
			}
		}else {
			*out++ = *fmt++;
		}
	}
	*out = '\0';
	return out - start;

  panic("Not implemented");
}

int sprintf(char *out, const char *fmt, ...) {
	va_list ap;
	va_start(ap, fmt);
	int ret = vsprintf(out, fmt, ap);
	va_end(ap);
	return ret;
  panic("Not implemented");
}

int snprintf(char *out, size_t n, const char *fmt, ...) {
  panic("Not implemented");
}

int vsnprintf(char *out, size_t n, const char *fmt, va_list ap) {
  panic("Not implemented");
}

#endif
