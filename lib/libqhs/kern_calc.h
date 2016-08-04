/****************************************************************************/
/*                                                                          */
/*    Cumulate kernel histogram and evaluate chosen quantile.               */
/*                                                                          */
/* Rob Siverd                                                               */
/* Created:       2014-05-05                                                */
/* Last modified: 2014-07-06                                                */
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
/* Evaluate specified quantile (floating-point data, sub-bin resolution):   */
double fkern_quant_s (
                 ezImg *kern_hist,    /* image structure with kernel hist   */
                double  quantile      /* target cumulation quantile         */
                     );

/*--------------------------------------------------------------------------*/
/* Evaluate specified quantile (floating-point data, bin centers):          */
double fkern_quant   (
                 ezImg *kern_hist,    /* image structure with kernel hist   */
                double  quantile      /* target cumulation quantile         */
                     );

/*--------------------------------------------------------------------------*/
/* Evaluate specified quantile (for integer data):                          */
double ikern_quant   (
                 ezImg *kern_hist,    /* image structure with kernel hist   */
                double  quantile      /* target cumulation quantile         */
                     );

