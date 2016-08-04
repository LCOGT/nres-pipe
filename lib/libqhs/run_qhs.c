/****************************************************************************/
/*                                                                          */
/*    Wrapper to stuff IDL array data into my custom ezImg structure.       */
/*                                                                          */
/* Rob Siverd                                                               */
/* Created:       2015-12-10                                                */
/* Last modified: 2015-12-10                                                */
/*                                                                          */
/****************************************************************************/
/****************************************************************************/
/*--------------------------------------------------------------------------*/

#include       <math.h>
#include      <stdio.h>
#include     <stdlib.h>
#include     <string.h>
#include    "imageIO.h"
#include "idl_export.h"
#include   "qhsmooth.h"

//#include "quick_ezimg.h"
/*--------------------------------------------------------------------------*/
/* Initialize an ezImg structure:                                           */
//void ezi_populate (

/*--------------------------------------------------------------------------*/
/* Compute min, max, and mean of an array:                                  */
//void ezi_testing  (   DTYPE *data,       /*  [input] data array             */
//                // IDL_LONG  naxis1,     /*  [input] X axis size            */
//                // IDL_LONG  naxis2      /*  [input] Y axis size            */
//                        int *naxis1,     /*  [input] X axis size            */
//                        int *naxis2      /*  [input] Y axis size            */
//                  // double *min,        /* [output] minimum data value     */
//                  // double *max,        /* [output] maximum data value     */
//                  // double *mean        /* [output] mean data value        */
//                  )

/*--------------------------------------------------------------------------*/
/* Set up array of pointers to rows: */
int alloc_row_ptrs( ezImg *img ) {
   /* Temporary X,Y dimensions: */
   long NX = (img->naxes)[0];
   long NY = (img->naxes)[1];

   /* Allocate row-pointer storage (128-byte alignment if possible): */
   long bytes = NY * sizeof(*(img->pix2D));
   if ( allocate_aligned_array((void**)&(img->pix2D), bytes, IMG_ALIGN) ) {
      fputs("\nFailed to allocate row pointer array!!\n\n", stderr);
      return 1;
   }

   /* Fill array with pointers to rows: */
   for ( long Y = 0; Y < NY; Y++ ) { 
      (img->pix2D)[Y] = &( (img->pix1D)[NX*Y] ); /* set up row access */
   }


   return 0; /* success */
}

/*--------------------------------------------------------------------------*/
/* Stuff an IDL array into ezImg structure:                                 */
void ezi_from_idl          (
                        ezImg *image,
                        DTYPE *data,
                     IDL_LONG  naxis1,
                     IDL_LONG  naxis2
                           )
{
   init_ezImg(image);
   image->BitPix = 0;
   image->naxis = 2;

   image->naxes[0] = naxis1;
   image->naxes[1] = naxis2;
   image->NumPix = image->naxes[0] * image->naxes[1];
   image->pix1D = data;
   alloc_row_ptrs(image);

   return;
}

/*--------------------------------------------------------------------------*/
/* Test out data exchange between IDL and C:                                */
void run_qhsmooth (int argc, void *argv[])
{
   /* Collect args: */
   IDL_LONG naxis1 = *((IDL_LONG *)argv[0]);
   IDL_LONG naxis2 = *((IDL_LONG *)argv[1]);
   DTYPE *idata = argv[2];                   /* allocated  input image */
   DTYPE *odata = argv[3];                   /* allocated output image */
   IDL_LONG hkx = *((IDL_LONG *)argv[4]);    /* kernel X half-size (pixels) */
   IDL_LONG hky = *((IDL_LONG *)argv[5]);    /* kernel X half-size (pixels) */
   double quant = *((double *)argv[6]);      /* smoothing quantile */
   double  hmin = *((double *)argv[7]);      /* histograms lower bound */
   double  hmax = *((double *)argv[8]);      /* histograms upper bound */
   IDL_LONG hbins = *((IDL_LONG *)argv[9]);  /* accumulator type */
   IDL_LONG accum = *((IDL_LONG *)argv[10]); /* accumulator type */
   //int verbose = -5;
   int verbose = 0;
   int timer = 0;

   /* Initialize image structures: */
   ezImg src_img, new_img;
   ezi_from_idl(&src_img, idata, naxis1, naxis2);
   ezi_from_idl(&new_img, odata, naxis1, naxis2);

   /* simple stuff first: */
   //print_size(&src_img, stderr);

   /* smooth input image: */
   int error = qhsmooth(&src_img, &new_img, (int)hkx, (int)hky, 
         quant, hmin, hmax, (int)hbins, (int)accum, 
         verbose, timer);

   /* Clean up and return: */
   if ( src_img.pix2D ) { free(src_img.pix2D); src_img.pix2D = NULL; }
   if ( new_img.pix2D ) { free(new_img.pix2D); new_img.pix2D = NULL; }
   return;
}

