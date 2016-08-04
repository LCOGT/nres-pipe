/****************************************************************************/
/*                                                                          */
/*    Histogram-based quantile smooth driver routine.                       */
/*                                                                          */
/* Rob Siverd                                                               */
/* Created:       2014-06-22                                                */
/* Last modified: 2014-07-05                                                */
/*                                                                          */
/****************************************************************************/
/****************************************************************************/
/*--------------------------------------------------------------------------*/

//#include   <math.h>
#include  <stdio.h>
#include <stdlib.h>
//#include <string.h>

/* Program-specific definitions: */
#include        "hsmooth.h"
#include "load_hist_rows.h"
#include "load_kern_cols.h"
#include      "kern_calc.h"

/* Shared functions: */
#include       "misc.h"
#include    "imageIO.h"
#include   "simpleIO.h"
#include "img_qstats.h"

///* OpenMP multi-threading: */
//#ifdef _OPENMP
//   #include      <omp.h>
//#endif

/* Useful min/max macro definitions: */
#ifndef MIN
#  define MIN(a,b) ((a) > (b) ? (b) : (a))
#endif
#ifndef MAX
#  define MAX(a,b) ((a) < (b) ? (b) : (a))
#endif

/* Verbosity and diagnostics: */
//extern int debug;
//extern int timer;
//extern int vlevel;

/*--------------------------------------------------------------------------*/
/* Histogram-based quantile smoother:                                       */
int qhsmooth            (
                ezImg  *src_img,       /*  [in]  input image data structure */
                ezImg  *new_img,       /* [out] output image data structure */
                  int   half_xpix,     /* [par] kernel X half-size (pixels) */
                  int   half_ypix,     /* [par] kernel Y half-size (pixels) */
               double   hquant,        /* [par]  chosen smoothing quantile  */
               double   hmin,          /* [par]  minimum histogram value    */
               double   hmax,          /* [par]  maximum histogram value    */
                  int   hbins,         /* [par]  number of histogram bins   */
                  int   accum,         /* [par]  kernel accumulator method  */
                  int   verbose,       /* [par]  control verbosity level    */
                  int   timer          /* [par]  timing / progress updates  */
              //  int   convert        /* [par]  if true recompute im vals  */
              //  int   silent         /* [par]  disables most output text  */
                        )
{
   int X, Y;
   double tik, tok, thisT, lastT; /* timers */
   double hrange = hmax - hmin;
   double hscale = hrange / (double)hbins;

   //fprintf(stderr, "hmin: %12.3lf\n", hmin);
   //fprintf(stderr, "hmax: %12.3lf\n", hmax);
   //fprintf(stderr, "hrng: %12.3lf\n", hrng);
   //fprintf(stderr, "bins: %4d\n", hbins);

   /* Working copy of image: */
   ezImg wrk_img;
   if ( new_full_image_copy(src_img, &wrk_img) ) {
      fputs("qhsmooth: failed to create working image copy!\n", stderr);
      return 1; /* failure */
   }

 ///* get min/max? */
 //double tmin = 0.0;
 //double tmax = 0.0;

   /* Shorthand: */
#define NCOLS  wrk_img.naxes[0]
#define NROWS  wrk_img.naxes[1]

   /********************************************************************/
   /***********       select kernel accumulator func        ************/
   /********************************************************************/

   /* Specify kernel accumulator: */
   double (*kquant)(ezImg *kern_hist, double quantile) = NULL;
   switch ( accum ) {
      case INTEGER_EXACT:
         kquant = &ikern_quant;
         break;

      case FPT_BIN_CENTERS:
         kquant = &fkern_quant;
         break;

      case FPT_INTERPOLATE:
         kquant = &fkern_quant_s;
         break;

      default:
         fputs("Unhandled accumulator type!!  Fix ...\n\n", stderr);
         abort();
   }

   /********************************************************************/
   /***********       use image for column histograms       ************/
   /********************************************************************/

#  define BINS_PER_HIST (long)(hbins + EXTRA_BINS)
   ezImg col_hist;
   init_ezImg(&col_hist);
   col_hist.naxis = 2;                       /*   use ezImg scratch arrays  */
   col_hist.naxes[0] = BINS_PER_HIST;        /* hist bins, pad, and counter */
   col_hist.naxes[1] = (long)NCOLS;          /*  one hist per input column  */
   col_hist.NumPix = BINS_PER_HIST * NCOLS;  /* total size of histogram set */

   /* Cumulator histogram (the kernel, 1D): */
   ezImg kern_hist;
   init_ezImg(&kern_hist);
   kern_hist.naxis = 2;                      /*   use ezImg scratch arrays  */
   kern_hist.naxes[0] = BINS_PER_HIST;       /* hist bins, pad, and counter */
   kern_hist.naxes[1] = 1;                   /*  only one kernel histogram  */
   kern_hist.NumPix = BINS_PER_HIST;         /* total size of histogram set */

 //kern_hist.naxis = 2;                      /*   easy scratch arrays  */
 //kern_hist.naxes[0] = (long)(hbins + 1);   /* hist bins plus counter */
 //kern_hist.naxes[1] = 1;                   /*   only one cumulator   */
 //kern_hist.NumPix = (long)(hbins + 1);     /* kernel histogram size  */

   /* Allocate histograms: */
   if ( alloc_ezImg(&col_hist) || alloc_ezImg(&kern_hist) ) {
      fprintf(stderr, "%s: Memory allocation failure!\n\n", PROG_NAME);
      free_ezImg(&col_hist);
      free_ezImg(&kern_hist);
      return 1; /* failure */
   }

   /* Fill with zeros: */
   ezi_zero_fill(&col_hist);
   ezi_zero_fill(&kern_hist);
#  undef BINS_PER_HIST

   /********************************************************************/
   /***********     convert input image to bin numbers      ************/
   /********************************************************************/

   /* Compute bin numbers: */
   //register double pix_val;
   if ( verbose >= 0 ) fputs("Computing bin numbers ... ", stdout);
   //double bcalc;
   tik = now();
   for ( long i = 0; i < wrk_img.NumPix; i++ ) {
      /* compute bin number (add 1 to skip over lower OOB counter): */
      double pix_val = (double)(wrk_img.pix1D[i]);
      //bcalc = 1.0 + floor(((double)wrk_img.pix1D[i] - hmin) / hscale);
      //bin_num = BINS_BELOW + floor((pix_val - hmin) / hscale);

      /* NOTES:
       * -- (pix_val == hmax) is treated as OOB for integer-mode compatibility
       */

      /* Assign bin number based on pixel value: */
      if ( pix_val < hmin ) {
         /* put pixels below hmin (OOB) into 0th bin: */
         wrk_img.pix1D[i] = (DTYPE)0;
      } 
      else if ( pix_val >= hmax ) {
         /* put pixels >= hmax (OOB) into 2nd-to-last bin: */
         wrk_img.pix1D[i] = (DTYPE)(BINS_BELOW + hbins);
      }
      else {
         wrk_img.pix1D[i] = 
            (DTYPE)(BINS_BELOW + floor((pix_val - hmin) / hscale));
      }
    //if ( bcalc < 0.0 ) {
    //   wrk_img.pix1D[i] = (DTYPE)0;
    //} else if ( bcalc >= (double)hbins ) {
    //   wrk_img.pix1D[i] = (DTYPE)((double)hbins - 1.0);
    //} else {
    //   wrk_img.pix1D[i] = (DTYPE)bcalc;
    //}
   }
   tok = now();
   vlt_done(verbose, 0, timer, tok-tik, stdout);

   /********************************************************************/
   /***********      quantile smoothing at warp speed       ************/
   /********************************************************************/

   /* Track rows in histogram: */
   long xmin, xmax;
   long ymin, ymax;
   long hist_rmin =  0;
   long hist_rmax = -1;
   long kern_cmin;
   long kern_cmax;

   /* Loop over *output* pixels: */
   tik = now();
   lastT = 0.0;
   for ( Y = 0; Y < NROWS; Y++ ) {
      /* progress report: */
      if ( verbose >= 0 ) {
         thisT = now();
         if ( (thisT - lastT) >= (double)MIN_DELAY ) {
            fprintf(stdout, PROGRESS_FMT,
                  Y+1, NROWS, (float)(Y+1) * 100.0 / (float)NROWS);
            lastT = thisT;
         }
      }

      /* Find row span of kernel: */
      ymin = MAX(0, Y - half_ypix);
      ymax = MIN(Y + half_ypix, NROWS - 1);
      /* ymin,ymax are pixel coords on the INPUT image corresponding *
       * to the first and last image row spanned by the kernel.      *
       * They are NOT relative coordinates. */

      /* Load required rows into column histograms: */
      hist_prep(ymin, ymax, &hist_rmin, &hist_rmax, &wrk_img, &col_hist);

      /* Reset kernel each row: */
      reset_kernel(&kern_hist);
      kern_cmin =  0;
      kern_cmax = -1;

      for ( X = 0; X < NCOLS; X++ ) {
         //if ( Y == X == 7 ) exit(EXIT_FAILURE);
         /* Find column span of kernel: */
         xmin = MAX(0, X - half_xpix);
         xmax = MIN(X + half_xpix, NCOLS - 1);
         /* xmin,xmax are pixel coords on the INPUT image corresponding *
          * to the first and last image column spanned by the kernel.   *
          * They are NOT relative coordinates. */

         /* Load required col. hists into kernel hist: */
         kern_prep(xmin, xmax, &kern_cmin, &kern_cmax, &col_hist, &kern_hist);

         /* Evaluate chosen quantile: */
         new_img->pix2D[Y][X] = (DTYPE)kquant(&kern_hist, hquant);
       //if ( isnan(new_img->pix2D[Y][X]) ) {
       //   fprintf(stderr, "already foobar ... Y=%d, X=%d\n", Y, X);
       //   fprintf(stderr, "kern_cmin: %ld\n", kern_cmin);
       //   fprintf(stderr, "kern_cmax: %ld\n", kern_cmax);
       //   for ( int i = 0; i < hbins; i++ ) {
       //      fprintf(stderr, "kern_hist[%d]: %10.5f\n", i, 
       //                                             kern_hist.pix1D[i]);
       //   }
       //   exit(EXIT_FAILURE);
       //}

       //if ( Y == 0 && X == 3 ) {
       //   fputc('\n', stderr);
       //   float cum = 0.0;
       //   int i;
       //   for ( i = 0; i < hbins+2; i++ ) {
       //      cum += kern_hist.pix1D[i];
       //      fprintf(stderr, "kern_hist[%d]: %10.5f, cum: %10.5f\n",
       //            i, kern_hist.pix1D[i], cum);
       //   }
       //   fprintf(stderr, "kern_hist[%d]: %10.5f\n", i, kern_hist.pix1D[i]);
       //   //fprintf(stderr, "total: %lf\n", kern_hist[);
       //   exit(EXIT_FAILURE);
       //}
      }
   }

   /* Final progress report: */
   if ( verbose >= 0 ) fprintf(stdout, PROGRESS_FMT, (int)NROWS, NROWS, 100.0);

   /* Smoothing time: */
   tok = now();
   if ( verbose >= 0 ) fprintf(stdout, "done.  (%.3f s)\n", tok-tik);

 //fprintf(stderr, "\n----------------------------------\n");
 //fprintf(stderr, "wrk_img:\n");
 //ezi_find_minmax(&wrk_img, &tmin, &tmax);
 //fprintf(stderr, "tmin: %10.5lf\n", tmin);
 //fprintf(stderr, "tmax: %10.5lf\n", tmax);

 //fprintf(stderr, "\n----------------------------------\n");
 //fprintf(stderr, "new_img:\n");
 //ezi_find_minmax(new_img, &tmin, &tmax);
 //fprintf(stderr, "tmin: %10.5lf\n", tmin);
 //fprintf(stderr, "tmax: %10.5lf\n", tmax);

   /********************************************************************/
   /***********      convert bins back to image values      ************/
   /********************************************************************/

   if ( verbose >= 0 ) fputs("Converting to image values ... ", stdout);
   tik = now();
   for ( long i = 0; i < new_img->NumPix; i++ ) {
      //new_img->pix1D[i] = hmin + (hrng / (double)hbins) * new_img->pix1D[i];
      new_img->pix1D[i] = hmin + hscale * (new_img->pix1D[i] - BINS_BELOW);
   }
   tok = now();
   vlt_done(verbose, 0, timer, tok-tik, stdout);
 //fprintf(stderr, "hmin:   %10.5f\n", hmin);
 //fprintf(stderr, "hscale: %10.5f\n", hscale);

   /********************************************************************/
   /***********          clean up and return result         ************/
   /********************************************************************/

   /* Clean up scratch space: */
   free_ezImg(&wrk_img);
   free_ezImg(&col_hist);
   free_ezImg(&kern_hist);

   return 0; /* success */
}

