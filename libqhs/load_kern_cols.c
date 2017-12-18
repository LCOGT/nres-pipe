/****************************************************************************/
/*                                                                          */
/*    Load column histograms into/from kernel histogram.                    */
/*                                                                          */
/* Rob Siverd                                                               */
/* Created:       2014-05-05                                                */
/* Last modified: 2014-06-23                                                */
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

/* Short-hand for hist bins (less counter): */
#define NB (kern_hist->naxes[0] - 1)

/*--------------------------------------------------------------------------*/
/* Load the specified column histogram into the kernel:                     */
inline
static
void load_hcol_into_kernel (
                 ezImg *col_hist,     /* image structure with bin numbers   */
                  long  col,          /* column hist go load into kernel    */
                 ezImg *kern_hist     /* [out] current kernel histogram     */
                           )
{
   for ( int i = 0; i < NB; i++ ) {
      kern_hist->pix1D[i] += col_hist->pix2D[col][i];
   }

   /* increment kernel counter: */
   kern_hist->pix1D[NB] += col_hist->pix2D[col][NB];

   return;
}

/*--------------------------------------------------------------------------*/
/* Drop the specified column histogram from the kernel:                     */
inline
static
void drop_hcol_from_kernel (
                 ezImg *col_hist,     /* image structure with bin numbers   */
                  long  col,          /* column hist to drop from kernel    */
                 ezImg *kern_hist     /* [out] current kernel histogram     */
                           )
{
   for ( int i = 0; i < NB; i++ ) {
      kern_hist->pix1D[i] -= col_hist->pix2D[col][i];
   }

   /* decrement kernel counter: */
   kern_hist->pix1D[NB] -= col_hist->pix2D[col][NB];

   return;
}

/*--------------------------------------------------------------------------*/
/* Load the specified row range into/out of the column histogram set:       */
void kern_prep       (
                  long  get_cmin,     /*  target lower col in kernel hist   */
                  long  get_cmax,     /*  target upper col in kernel hist   */
                  long *has_cmin,     /* current lower col in kernel hist   */
                  long *has_cmax,     /* current upper col in kernel hist   */
                 ezImg *col_hist,     /* image structure with bin numbers   */
                 ezImg *kern_hist     /* image structure with kernel hist   */
                     )
{

   //fprintf(stderr, "current min/max: %ld/%ld\n", *has_cmin, *has_cmax);
   //fprintf(stderr, "desired min/max: %ld/%ld\n",  get_cmin,  get_cmax);

   /* Remove 'lower' columnss: */
   while ( *has_cmin < get_cmin ) {
      //fprintf(stderr, "Drop hcol %ld from kernel ...\n", *has_cmin);
      drop_hcol_from_kernel(col_hist, *has_cmin, kern_hist);
      (*has_cmin)++;
   }

   /* Append 'upper' rows: */
   while ( *has_cmax < get_cmax ) {
      (*has_cmax)++;
      //fprintf(stderr, "Load hcol %ld into kernel ...\n", *has_cmax);
      load_hcol_into_kernel(col_hist, *has_cmax, kern_hist);
   }

   return;
}

/*--------------------------------------------------------------------------*/
/* Empty the kernel at the start of each row (no snaking):                  */
void reset_kernel    (
                 ezImg *kern_hist     /* image structure with kernel hist   */
                     )
{
   for ( int i = 0; i < kern_hist->naxes[0]; i++ ) {
      kern_hist->pix2D[0][i] = 0;
   }

   return;
}

#undef NB /* done with hist bins */

