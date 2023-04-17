#include <stdint.h>
#include <stdbool.h>

typedef void *buf_T;
buf_T *buflist_findnr(int nr);
char *ml_get_buf(buf_T *buf, int32_t lnum, bool will_change);

extern int p_lpl;
