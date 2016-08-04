/****************************************************************************/
/*                                                                          */
/*    Cumulate kernel histogram and evaluate chosen quantile.               */
/*                                                                          */
/* NOTES:                                                                   */
/* -- For all cumulator routines below, the result returned is the          */
/*       "effective" or "decimal" bin position.                             */
/* -- hsmooth.h specifies the number of extra bins (padding) above and      */
/*       below the range of interest (for under/overflow and tally).        */
/* -- In the current implementation, there is one bin of underflow, one bin */
/*       of overflow, and one bin for the histogram tally.                  */
/* -- In integer mode, under/overflow results return integer bin position   */
/*       for consistency. Once converted to image units, underflow pixels   */
/*       have value (hmin - 1) and overflow pixels have (hmax + 0).         */
/* -- In floating-point modes, under/overflow results return half-integer   */
/*       bin position for consistency. Once converted to image units,       */
/*       underflow pixels have value (hmin - binsize/2) and overflow pixels */
/*       have value (hmax + binsize/2).                                     */
/* -- Quantile restricted to: 0 < quant < 1.                                */
/* -- In all cases, (total > histq) and (total > qelem) are EQUIVALENT      */
/*       because 'total' is guaranteed to be an integer value.              */
/*                                                                          */
/*                                                                          */
/*                                                                          */
/* i = 0       --> underflow                                                */
/* i = 1       -->   usable                                                 */
/* i = NB - 2  -->   usable                                                 */
/* i = NB - 1  -->  overflow                                                */
/*                                                                          */
/*                                                                          */
/*                                                                          */
/* Rob Siverd                                                               */
/* Created:       2014-05-05                                                */
/* Last modified: 2014-07-11                                                */
/*                                                                          */
/****************************************************************************/
/****************************************************************************/
/*--------------------------------------------------------------------------*/

#include   <math.h>
#include  <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

/* Shared functions: */
#include  "imageIO.h"

/* Short-hand for hist bins (less counter): */
#define NB (kern_hist->naxes[0] - 1)

/*--------------------------------------------------------------------------*/
/*   Evaluate specified quantile (floating-point data, sub-bin resolution). */
/* The value returned is decimal bin number/position.                       */
double fkern_quant_s (
                 ezImg *kern_hist,    /* image structure with kernel hist   */
                double  quantile      /* target cumulation quantile         */
                     )
{
#  define HIST_UFLOW (double)0.5         /* underflow, middle of lower bin */
#  define HIST_OFLOW (double)(NB - 0.5)  /*  overflow, middle of upper bin */

   /* Pixels in the kernel: */
   long npixels = (long)kern_hist->pix1D[NB];
   if ( npixels == 0 ) { return nan(""); }

   /* Element (NOT ARRAY INDEX) corresponding to requested quantile: */
   double qelem = (double)(npixels + 1) * quantile;   /* decimal element */
   double histq = floor(qelem);                       /*    integer part */
   double qfrac = qelem - histq;                      /* fractional part */

   /* Cumulate to find quantile integer part: */
   double total = 0.0;
   int i;
   for ( i = 0; i < NB; i++ ) {
      total += kern_hist->pix1D[i];
      if ( total >= histq ) break;
   }

   /* Accept underflow directly: */
   if ( i == 0 ) { return HIST_UFLOW; }

   /* Accept overflow directly: */
   if ( i == (NB - 1) ) { return HIST_OFLOW; }

   /* Note data points in this bin (contains lower qdex): */
   double lo_counts = (double)kern_hist->pix1D[i];

   /* Identify bin with requested quantile, interpolate if needed: */
   if ( total >= qelem ) {
      /* i.e., total >= ceil(qelem), so lower & upper qdex in bin i */
      /* ---------------------------------------------------------- */
      /* Required quantile passed so we have the correct bin (lower */
      /* and upper qdex fall in the same bin). Interpolate sub-bin  */
      /* position based on overshoot:                               */

      /* Overshoot will be in range: 
       *    0.0 <= overshoot <= (lo_counts - 1.0)
       * double overshoot = total - qelem;
       *
       * overshoot > (lo_counts - 1) implies lower qdex in prev. bin
       */

      /* Effective bin position is found by subtracting the overshoot */
      /* from the center of the rightmost (max) sub-bin center.       */
      /* Max sub-bin center is: i + ((lo_counts - 0.5) / lo_counts).  */
      return ((double)i + (double)1.0 - ((total - qelem) / lo_counts));
   } else {
      /* i.e., total == histq < qelem */
      /* ---------------------------------------------------------- */
      /* Otherwise, lower/upper elements fall in different bins ... */

      /* For lower qdex (floor(qelem)) position, use the center of  */
      /* the rightmost (max) sub-bin as defined above:              */
      double lo_eff_bin = (double)i + ((lo_counts - 0.5) / lo_counts);

      /* Find next populated bin and interpolate: */
      int j;
      for ( j = i + 1; j < NB; j++ ) {
         if ( kern_hist->pix1D[j] > 0.0 ) break;
      }

      /* For upper qdex (ceil(qelem)) position, use the center  */
      /* of the leftmost (min) sub-bin of next populated bin:   */
      double hi_counts  = (double)kern_hist->pix1D[j];
      double hi_eff_bin = (double)j + (0.5 / hi_counts);

      /* Interpolate bin of fractional element: */
      if ( j == (NB - 1) ) {
         return HIST_OFLOW;   /* upper quantile overflow */
      } else {
         return ((1.0 - qfrac) * lo_eff_bin  +  qfrac * hi_eff_bin);
      }
   } 
#  undef HIST_UFLOW
#  undef HIST_OFLOW
}

/*--------------------------------------------------------------------------*/
/*   Evaluate specified quantile (floating-point data, bin centers):        */
/* The value returned is decimal bin number/position.                       */
double fkern_quant   (
                 ezImg *kern_hist,     /* image structure with kernel hist  */
                double  quantile       /* target cumulation quantile        */
                     )
{
#  define HIST_UFLOW (double)0.5         /* underflow */
#  define HIST_OFLOW (double)(NB - 0.5)  /*  overflow */

   /* Pixels in the kernel: */
   long npixels = (long)kern_hist->pix1D[NB];
   if ( npixels == 0 ) { return nan(""); }

   /* Element (NOT ARRAY INDEX) corresponding to requested quantile: */
   double qelem = (double)(npixels + 1) * quantile;   /* decimal element */
   double histq = floor(qelem);                       /*    integer part */
   double qfrac = qelem - histq;                      /* fractional part */

   /* Cumulate to find quantile integer part: */
   double total = 0.0;
   int i;
   for ( i = 0; i < NB; i++ ) {
      total += kern_hist->pix1D[i];
      if ( total >= histq ) break;
   }

   /* Accept underflow directly: */
   if ( i == 0 ) { return HIST_UFLOW; }

   /* Accept overflow directly: */
   if ( i == (NB - 1) ) { return HIST_OFLOW; }

   /* Identify bin with requested quantile, interpolate if needed: */
   if ( total >= qelem ) {
      /* i.e., total >= ceil(qelem), so lower & upper qdex in bin i */
      /* ---------------------------------------------------------- */
      /* Required quantile passed so we have the correct bin (lower */
      /* and upper qdex fall in the same bin). Return bin center:   */
      return ((double)i + 0.5);
   } else {
      /* i.e., total == histq < qelem */
      /* ---------------------------------------------------------- */
      /* Otherwise, lower/upper elements fall in different bins ... */
      /* If full bin used, find next populated bin and interpolate: */
      int j;
      for ( j = i + 1; j < NB; j++ ) {
         if ( kern_hist->pix1D[j] > 0.0 ) break;
      }

      /* Interpolate bin of fractional element: */
      if ( j == (NB - 1) ) {
         return HIST_OFLOW;   /* upper quantile overflow */
      } else {
         return (0.5 + ((1.0 - qfrac) * (double)i  +  qfrac * (double)j));
         //return (0.5 * (double)(i + j) + 0.5);
      }
   } 
#  undef HIST_UFLOW
#  undef HIST_OFLOW
}

/*--------------------------------------------------------------------------*/
/*   Evaluate specified quantile (for integer data).                        */
double ikern_quant   (
                 ezImg *kern_hist,    /* image structure with kernel hist   */
                double  quantile      /* target cumulation quantile         */
                     )
{
#  define HIST_UFLOW (double)0.0         /* underflow */
#  define HIST_OFLOW (double)(NB - 1)    /*  overflow */

   /* Pixels in the kernel: */
   long npixels = (long)kern_hist->pix1D[NB];
   if ( npixels == 0 ) { return nan(""); }

   /* Element (NOT ARRAY INDEX) corresponding to requested quantile: */
   double qelem = (double)(npixels + 1) * quantile;   /* decimal element */
   double histq = floor(qelem);                       /*    integer part */
   double qfrac = qelem - histq;                      /* fractional part */

   /* Cumulate to find quantile integer part: */
   int i;
   double total = 0.0;
   for ( i = 0; i < NB; i++ ) {
      total += kern_hist->pix1D[i];
      if ( total >= histq ) break;     /* stop if lower qdex reached */
   }

   /* Accept underflow directly: */
   if ( i == 0 ) { return HIST_UFLOW; }

   /* Accept overflow directly: */
   if ( i == (NB - 1) ) { return HIST_OFLOW; }

   /* Identify bin with requested quantile, interpolate if needed: */
   if ( total >= qelem ) {
      /* i.e., total >= ceil(qelem), so lower & upper qdex in bin i */
      /* ---------------------------------------------------------- */
      /* Required quantile passed so we have the correct bin (lower */
      /* and upper qdex fall in the same bin). Since interpolation  */
      /* is not used in integer mode, return bin as-is:             */
      return (double)i;
   } else {
      /* i.e., total == histq < qelem */
      /* ---------------------------------------------------------- */
      /* Otherwise, lower/upper elements fall in different bins ... */
      /* If full bin used, find next populated bin and interpolate: */
      int j;
      for ( j = i + 1; j < NB; j++ ) {
         if ( kern_hist->pix1D[j] > 0.0 ) break;
      }

      /* Interpolate bin of fractional element: */
      if ( j == (NB - 1) ) { 
         return HIST_OFLOW;   /* upper quantile overflow */
      } else {
         return ((1.0 - qfrac) * (double)i  +  qfrac * (double)j);
      }
   }

#  undef HIST_UFLOW
#  undef HIST_OFLOW
}

#undef NB /* done with hist bins */

