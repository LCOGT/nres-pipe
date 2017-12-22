/****************************************************************************/
/*                                                                          */
/*    Header file for hsmooth program.                                      */
/*                                                                          */
/* Rob Siverd                                                               */
/* Created:       2014-04-24                                                */
/* Last modified: 2015-12-10                                                */
/*                                                                          */
/****************************************************************************/
/****************************************************************************/
/*--------------------------------------------------------------------------*/

/* Required definitions: */
#include <stdio.h>

/* Program-wide settings: */
#define PROG_NAME "hsmooth"
#define CODE_VERSION 1.7.6
#define LAST_UPDATE "Dec 10 2015"

/* Preprocessor macros: */
#define QUOTEME_(x) #x
#define QUOTEME(x) QUOTEME_(x)

/* Default names: */
#define DEFAULT_ONAME "!smooth_hist.fits"

/* Progress reporting: */
#define MIN_DELAY     0.2    /* minimum time (sec) between reports */
//#define MIN_DELAY     0.1    /* minimum time (sec) between reports */
//#define PROGRESS_FMT  "\rFiltering row %ld of %ld ... "
#define PROGRESS_FMT "\rSmoothing row %d of %ld (%5.1f%%) ... "

/* Histogram bounds: */
#define MANUAL_LIMITS 0
#define  IMAGE_STATS  1
#define IMAGE_MINMAX  2
#define QUANT_MINMAX  3

/* Histogram layout: */
#define   BINS_BELOW  1       /* number of bins for values <  hmin */
#define   BINS_ABOVE  1       /* number of bins for values >= hmax */
#define   TALLY_BINS  1       /* number of bins for pixel counter  */
#define   EXTRA_BINS (BINS_BELOW + BINS_ABOVE + TALLY_BINS)

/* Accumulator choice: */
#define INT_KERNEL 0
#define INTEGER_EXACT   0
#define FPT_BIN_CENTERS 1
//#define FPT_TRUBIN 2
#define FPT_INTERPOLATE 3

/* Functions: */
void   help(FILE *stream);
int    parse_arguments(int argc, char **argv);
void   report_version_info(FILE *stream);

