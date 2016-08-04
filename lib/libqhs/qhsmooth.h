/****************************************************************************/
/*                                                                          */
/*    Histogram-based quantile smooth driver routine.                       */
/*                                                                          */
/* Rob Siverd                                                               */
/* Created:       2014-06-22                                                */
/* Last modified: 2015-12-07                                                */
/*                                                                          */
/****************************************************************************/
/****************************************************************************/
/*--------------------------------------------------------------------------*/

/* Shared functions: */
#include    "imageIO.h"

/*--------------------------------------------------------------------------*/
/* Histogram-based quantile smoother:                                       */
int qhsmooth            (
                ezImg  *image,         /*  [in]  input image data structure */
                ezImg  *smooth,        /* [out] output image data structure */
                  int   half_xpix,     /* [par] kernel X half-size (pixels) */
                  int   half_ypix,     /* [par] kernel Y half-size (pixels) */
               double   hquant,        /* [par]  chosen smoothing quantile  */
               double   hmin,          /* [par]  minimum histogram value    */
               double   hmax,          /* [par]  maximum histogram value    */
                  int   hbins,         /* [par]  number of histogram bins   */
                  int   accum,         /* [par]  kernel accumulator method  */
                  int   verbose,       /* [par]  control verbosity level    */
                  int   timer          /* [par]  timing / progress updates  */
             //   int   convert        /* [par]  if true recompute im vals  */
             //   int   silent         /* [par]  disables most output text  */
                        );

