#include <stdbool.h>
#include <stdint.h>

typedef void *buf_T;
buf_T *buflist_findnr(int nr);
char *ml_get_buf(buf_T *buf, int32_t lnum, bool will_change);

extern int msg_silent;  // don't print messages
extern int emsg_silent; // don't print error messages
extern bool cmd_silent; // don't echo the command line
