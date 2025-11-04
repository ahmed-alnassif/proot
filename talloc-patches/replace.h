#ifndef REPLACE_H
#define REPLACE_H

#include <sys/types.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <stdarg.h>
#include <errno.h>
#include <time.h>
#include <sys/time.h>

/* Essential macros and definitions */
#define discard_const_p(type, ptr) ((type *)((void *)(ptr)))

/* Function declarations for Android compatibility */
#ifndef HAVE_STRDUP
static inline char *strdup(const char *s) {
    size_t len = strlen(s) + 1;
    char *dup = malloc(len);
    if (dup) memcpy(dup, s, len);
    return dup;
}
#endif

#ifndef HAVE_STRNDUP
static inline char *strndup(const char *s, size_t n) {
    size_t len = strnlen(s, n);
    char *dup = malloc(len + 1);
    if (dup) {
        memcpy(dup, s, len);
        dup[len] = '\0';
    }
    return dup;
}
#endif

#ifndef HAVE_MEMMEM
static inline void *memmem(const void *haystack, size_t haystacklen,
                          const void *needle, size_t needlelen) {
    if (needlelen == 0) return (void*)haystack;
    if (haystacklen < needlelen) return NULL;
    
    const char *h = (const char*)haystack;
    const char *n = (const char*)needle;
    
    for (size_t i = 0; i <= haystacklen - needlelen; i++) {
        if (memcmp(h + i, n, needlelen) == 0) {
            return (void*)(h + i);
        }
    }
    return NULL;
}
#endif

/* Simple getpass implementation for Android */
#ifndef HAVE_GETPASS
static inline char *getpass(const char *prompt) {
    static char buf[128];
    printf("%s", prompt);
    fflush(stdout);
    if (fgets(buf, sizeof(buf), stdin)) {
        buf[strcspn(buf, "\n")] = 0;
        return buf;
    }
    return NULL;
}
#endif

#endif /* REPLACE_H */
