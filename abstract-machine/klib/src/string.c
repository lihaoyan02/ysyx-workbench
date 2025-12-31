#include <klib.h>
#include <klib-macros.h>
#include <stdint.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

size_t strlen(const char *s) {
  panic("Not implemented");
}

char *strcpy(char *dst, const char *src) {
	char *dest = dst;
	while (*src) {
		*dest = *src;
		dest++;
		src++;
	};
	*dest = *src;
	return dst;
  panic("Not implemented");
}

char *strncpy(char *dst, const char *src, size_t n) {
  panic("Not implemented");
}

char *strcat(char *dst, const char *src) {
	char *dest = dst;
	while (*dest) {
		dest++;
	}
	while (*src) {
		*dest = *src;
		dest++;
		src++;
	}
	*dest = *src;
	return dst;
  panic("Not implemented");
}

int strcmp(const char *s1, const char *s2) {
	while ( *s1 && (*s1 == *s2)) {
		s1++;
		s2++;
	}
	return *(const unsigned char *)s1 - *(const unsigned char *)s2;
}

int strncmp(const char *s1, const char *s2, size_t n) {
  panic("Not implemented");
}

void *memset(void *s, int c, size_t n) {
	unsigned char *ptr = (unsigned char *)s;
	while (n--) {
		*ptr = (unsigned char)c;
		ptr++;
	}
	return s;
  panic("Not implemented");
}

void *memmove(void *dst, const void *src, size_t n) {
  panic("Not implemented");
}

void *memcpy(void *out, const void *in, size_t n) {
  panic("Not implemented");
}

int memcmp(const void *s1, const void *s2, size_t n) {
 	while (n--) {
		if (*(const unsigned char *)s1 != *(const unsigned char *)s2) {
			return *(const unsigned char *)s1 - *(const unsigned char *)s2;
		}
		s1++;
		s2++;
	}
	return 0;
 panic("Not implemented");
}

#endif
