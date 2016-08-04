/****************************************************************************/
/*                                                                          */
/*    Load column histograms into/from kernel histogram.                    */
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
/* Load the specified column range into/out of the kernel histogram:        */
void kern_prep       (
                  long  get_cmin,     /*  target lower col in kernel hist   */
                  long  get_cmax,     /*  target upper col in kernel hist   */
                  long *has_cmin,     /* current lower col in kernel hist   */
                  long *has_cmax,     /* current upper col in kernel hist   */
                 ezImg *col_hist,     /* image structure with bin numbers   */
                 ezImg *kern_hist     /* image structure with kernel hist   */
                     );

/*--------------------------------------------------------------------------*/
/* Empty the kernel at the start of each row (no snaking):                  */
void reset_kernel    (
                 ezImg *kern_hist     /* image structure with kernel hist   */
                     );

