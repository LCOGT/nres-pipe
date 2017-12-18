/****************************************************************************/
/*                                                                          */
/*    Load image rows into column histograms.                               */
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
#define NB (col_hist->naxes[0] - 1)

/*--------------------------------------------------------------------------*/
/* Add the specified row to column histograms:                              */
inline
static
void load_row_into_hists   (
                 ezImg *hbin_img,     /* input image (bin number converted) */
                  long  row,          /* row of values to add to histograms */
                 ezImg *col_hist      /* image structure with column hists  */
                           )
{
   const long NX = hbin_img->naxes[0];       /* image ncols */
   //int i, bnum;
   for ( long i = 0; i < NX; i++ ) {
      if ( !isnan(hbin_img->pix2D[row][i]) ) {
         int bnum = (int)(hbin_img->pix2D[row][i]);
         col_hist->pix2D[i][bnum] += 1;   /* increment that bin */
         col_hist->pix2D[i][NB]   += 1;   /* increment hist count */
      }
   }
   return;
}

/*--------------------------------------------------------------------------*/
/* Remove the specified row to column histograms:                           */
inline
static
void drop_row_from_hists   (
                 ezImg *hbin_img,     /* input image (bin number converted) */
                  long  row,          /* row of values to remove from hists */
                 ezImg *col_hist      /* image structure with column hists  */
                           )
{
   const long NX = hbin_img->naxes[0];       /* image ncols */
   //int i, bnum;
   for ( int i = 0; i < NX; i++ ) {
      if ( !isnan(hbin_img->pix2D[row][i]) ) {
         int bnum = (int)(hbin_img->pix2D[row][i]);
         col_hist->pix2D[i][bnum] -= 1;   /* decrement that bin */
         col_hist->pix2D[i][NB]   -= 1;   /* decrement hist count */
      }
   }
   return;
}

/*--------------------------------------------------------------------------*/
/* Load the specified row range into/out of the column histogram set:       */
void hist_prep       (
                  long  get_rmin,     /*  target lower row in column hists  */
                  long  get_rmax,     /*  target upper row in column hists  */
                  long *has_rmin,     /* current lower row in column hists  */
                  long *has_rmax,     /* current upper row in column hists  */
                 ezImg *hbin_img,     /* image structure with bin numbers   */
                 ezImg *col_hist      /* image structure with column hists  */
                     )
{

   //fprintf(stderr, "current min/max: %ld/%ld\n", *has_rmin, *has_rmax);
   //fprintf(stderr, "desired min/max: %ld/%ld\n",  get_rmin,  get_rmax);

   /* Remove 'lower' rows: */
   while ( *has_rmin < get_rmin ) {
      //fprintf(stderr, "Drop row %ld from histograms ...\n", *has_rmin);
      drop_row_from_hists(hbin_img, *has_rmin, col_hist);
      (*has_rmin)++;
   }

   /* Append 'upper' rows: */
   while ( *has_rmax < get_rmax ) {
      (*has_rmax)++;
      //fprintf(stderr, "Load row %ld into histograms ...\n", *has_rmax);
      load_row_into_hists(hbin_img, *has_rmax, col_hist);
   }

   return;
}

#undef NB /* done with hist bins */

