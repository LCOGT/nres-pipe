/****************************************************************************/
/*                                                                          */
/*    Load image rows into column histograms.                               */
/*                                                                          */
/* Rob Siverd                                                               */
/* Created:       2014-05-05                                                */
/* Last modified: 2014-05-05                                                */
/*                                                                          */
/****************************************************************************/
/****************************************************************************/
/*--------------------------------------------------------------------------*/

#include   <math.h>
#include  <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Shared functions: */
#include  "imageIO.h"

/*--------------------------------------------------------------------------*/
/* Load the specified row range into/out of the column histogram set:       */
void hist_prep       (
                  long  get_rmin,     /*  target lower row in column hists  */
                  long  get_rmax,     /*  target upper row in column hists  */
                  long *has_rmin,     /* current lower row in column hists  */
                  long *has_rmax,     /* current upper row in column hists  */
                 ezImg *hbin_img,     /* image structure with bin numbers   */
                 ezImg *col_hist      /* image structure with column hists  */
                     );

