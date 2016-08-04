/****************************************************************************/
/*                                                                          */
/*    Function prototypes for misc.c.                                       */
/*                                                                          */
/* Rob Siverd                                                               */
/* Created:       2010-06-22                                                */
/* Last modified: 2015-06-19                                                */
/*                                                                          */
/****************************************************************************/
/****************************************************************************/
/*--------------------------------------------------------------------------*/

#ifdef __cplusplus   /* C++ compatibility */
extern "C" {         /* C++ compatibility */
#endif               /* C++ compatibility */

/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

#ifndef HAVE_MISC_H /* begin include-guard */

#define HAVE_MISC_H

#define SHARED_MISC_VERSION 1.8.5

/*--------------------------------------------------------------------------*/
/* Return the lesser or greater of two integers:                            */
/* inline int imin( int, int ); */
/* inline int imax( int, int ); */

/*--------------------------------------------------------------------------*/
/* Return base name of file (strip directory)                               */
char *basename(char *file_name);

/*--------------------------------------------------------------------------*/
/* Return file extension (after last '.') or blank if none found:           */
char *file_ext(char *file_name);

/*--------------------------------------------------------------------------*/
/* The current time (decimal seconds since beginning of epoch):             */
double now(void);

/*--------------------------------------------------------------------------*/
/* Return pointer to duplicate of input string (mimics strdup()):           */
char *strclone(const char *in_str);

/*--------------------------------------------------------------------------*/
/* Even/odd testing:                                                        */
//long is_odd(long value);
static inline
long is_odd(long value)
{
   return (value & 1);
}

/*--------------------------------------------------------------------------*/
/* Convenience function for non-quiet, timer-aware "done" message:          */
static inline
void nqt_done(int quiet, int timer, double ttook, FILE *stream)
{
   if ( !quiet ) {
      fputs("done.", stream);
      if ( timer ) fprintf(stream, "  (%.3f s)", ttook);
      fputc('\n', stream);
   }
}

/*--------------------------------------------------------------------------*/
/* Convenience function for vlevel- and timer-aware "done" message:         */
static inline
void vlt_done(int vlevel, int vmin, int timer, double ttook, FILE *stream)
{
   if ( vlevel >= vmin ) {
      fputs("done.", stream);
      if ( timer ) fprintf(stream, "  (%.3f s)", ttook);
      fputc('\n', stream);
   }
}

/*--------------------------------------------------------------------------*/
/* String type-checks (pre-conversion):                                     */
//int   is_int(char *numStr);  /* returns 1 if string is integer        */
//int is_float(char *numStr);  /* returns 1 if string is floating-point */

/*--------------------------------------------------------------------------*/
/* String conversion with robust checking:                                  */
//int   long_from_string(char *numStr,   long *result);
//int double_from_string(char *numStr, double *result);

/*--------------------------------------------------------------------------*/
/* Read rectangle dimensions from string:                                   */
//int get_box_dim(char *boxStr, long *nX, long *nY);

/*--------------------------------------------------------------------------*/
/* Read (split) two doubles from string with selectable delimiter:          */
//int   split_dub_dub(char *numStr, int delim, double *val1, double *val2);
//int split_long_long(char *numStr, int delim,   long *val1,   long *val2);

/*--------------------------------------------------------------------------*/

#endif             /* end of include-guard */

/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

#ifdef __cplusplus   /* C++ compatibility */
}                    /* C++ compatibility */
#endif               /* C++ compatibility */

