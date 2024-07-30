#include <stdbool.h>
#include <stdint.h>
#include <time.h>

typedef void *buf_T;
buf_T *buflist_findnr(int nr);
char *ml_get_buf(buf_T *buf, int32_t lnum, bool will_change);

extern int msg_silent;  // don't print messages
extern int emsg_silent; // don't print error messages
extern bool cmd_silent; // don't echo the command line

/// Message history for `:messages`
typedef struct msg_hist {
  struct msg_hist *next;  ///< Next message.
  char *msg;              ///< Message text.
  const char *kind;       ///< Message kind (for msg_ext)
  int attr;               ///< Message highlighting.
  time_t time;            ///< message occurred time
  bool multiline;         ///< Multiline message.
  void *multiattr;        ///< multiattr message.
} MessageHistoryEntry;
extern MessageHistoryEntry *last_msg_hist;

