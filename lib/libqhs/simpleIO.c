/****************************************************************************/
/*                                                                          */
/*    Simplified (high-level) I/O routines for direct use in programs.      */
/*                                                                          */
/* Rob Siverd                                                               */
/* Created:       2014-04-03                                                */
/* Last modified: 2015-07-01                                                */
/*                                                                          */
/****************************************************************************/
/****************************************************************************/
/*--------------------------------------------------------------------------*/

//#include   <math.h>
#include  <stdio.h>
//#include <stdlib.h>
//#include <string.h>

/* Definitions etc.: */
#include "imageIO.h"
#include "img_hdr.h"

/*--------------------------------------------------------------------------*/
/* Read a FITS image into a floating-point array, noting image size/type.   */
int qreadFITS     (
                    ezImg *image,              /* structure for image data  */
                     char *fname               /* name of FITS file to load */
                  )
{
   /* Make sure no file already open: */
   if ( ez_open_FITS(image, fname, READONLY) ) { /* error */ return 1; }

   /* Allocate image data arrays: */
   if ( alloc_ezImg(image) ) {
      fputs("Failed to allocate image!\n\n", stderr);
      ez_close_FITS(image);
      return 1;
   }

   /* Read entire image: */
   if ( ez_loadpix(image) ) {  /* error loading pixel data */ return 1; }

   /* Close opened FITS image: */
   if ( ez_close_FITS(image) ) { /* error occurred */ return 1; }

   return 0; /* success */
}

/*--------------------------------------------------------------------------*/
/* Write a floating-point FITS image from an array.                         */
int qwriteFITS    (
                ezImg  *image,               /*  structure with image data  */
                 char  *fname                /* output FITS image file name */
                  )
{
   /* Create new FITS file and image HDU: */
   if ( ez_create_FITS(image, fname) ) { /* error occurred */ return 1; }

   /* Write pixels to file: */
   if ( ez_savepix(image) ) {
      ez_close_FITS(image);
      return 1; /* failed to write pixels */
   }

   /* Close opened FITS image: */
   if ( ez_close_FITS(image) ) { /* error occurred */ return 1; }

   return 0; /* success */
}

/*--------------------------------------------------------------------------*/
/* Save image data to disk, optionally copy image headers: */
int hdr_qwrite( ezImg *img,        /*  ezImg structure to store attributes  */
                 char *imname,     /*    name of new FITS file to create    */
                 char *hdr_src )   /* optional: get headers from this image */
#define XTRA_KEYS 200
{
   /* Create new FITS file and image HDU: */
   if ( ez_create_FITS(img, imname) ) { /* error occurred */ return 1; }

   /* Clone headers from source if requested: */
   ezImg hdrImg;
   if ( hdr_src != NULL ) {
      init_ezImg(&hdrImg);
      if ( ez_open_FITS(&hdrImg, hdr_src, READONLY) ) {
         fprintf(stderr, "Failed to open for reading (headers): %s\n", hdr_src);
         return 1; /* error */
      }
      //cpy_all_hdr(&hdrImg, img, XTRA_KEYS); /* old version */
      //cpy_all_hdr(&hdrImg, img, HDR_SET_TOTAL, XTRA_KEYS);
      cpy_all_hdr(&hdrImg, img, HDR_ADD_EXTRA, XTRA_KEYS);
      if ( ez_close_FITS(&hdrImg) ) { /* error occurred */ return 1; }
   }

   /* Write pixels to file: */
   if ( ez_savepix(img) )
   {  /* error writing pixels */
      ez_close_FITS(img);
      return 1; /* failure */
   }

   /* Close opened FITS image: */
   if ( ez_close_FITS(img) ) { /* error occurred */ return 1; }

   return 0; /* success */
}
#undef XTRA_KEYS

/****************************************************************************/
/****************************************************************************/

/*--------------------------------------------------------------------------*/
/* Create blank (allocated) ezImg of specified size:                        */
int blank_image_dimen(ezImg *image, long xpix, long ypix)
#define FUNCNAME "blank_image_dimen"
{
   /* Initialize and copy attributes: */
   init_ezImg(image);

   /* Fill structure: */
   image->naxis = 2;
   image->naxes[0] = xpix;
   image->naxes[1] = ypix;
   image->NumPix = xpix * ypix;
   image->BitPix = -32;

   /* Allocate new image: */
   if ( alloc_ezImg(image) ) {
      fprintf(stderr, "%s: memory allocation failure!\n", FUNCNAME);
      exit(EXIT_FAILURE);
   }

   return 0; /* success */
}
#undef FUNCNAME

/*--------------------------------------------------------------------------*/
/* Create blank (allocated) ezImg of matching size:                         */
int blank_image_like(ezImg *src, ezImg *dst)
#define FUNCNAME "blank_image_like"
{
   /* Initialize and copy attributes: */
   init_ezImg(dst);
   copy_imgSS(src, dst); /* copy image size and shape */

   /* Allocate new image: */
   if ( alloc_ezImg(dst) ) {
      fprintf(stderr, "%s: memory allocation failure!\n", FUNCNAME);
      exit(EXIT_FAILURE);
   }

   return 0; /* success */
}
#undef FUNCNAME

/*--------------------------------------------------------------------------*/
/* Duplicate an image structure, including data (eg, working copy):         */
int new_full_image_copy(ezImg *src, ezImg *dst)
#define FUNCNAME "new_full_image_copy"
{  
   /* Matching blank image: */
   blank_image_like(src, dst);

   /* Copy pixel data: */
   if ( copy_pixels(src, dst) ) {
      fprintf(stderr, "%s: pixel copy error!\n", FUNCNAME);
      return 1;
   }

   return 0; /* success */
}
#undef FUNCNAME


