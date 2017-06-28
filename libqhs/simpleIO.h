/****************************************************************************/
/*                                                                          */
/*    Simplified (high-level) I/O routines for direct use in programs.      */
/*                                                                          */
/* Rob Siverd                                                               */
/* Created:       2014-04-03                                                */
/* Last modified: 2014-11-08                                                */
/*                                                                          */
/****************************************************************************/
/****************************************************************************/
/*--------------------------------------------------------------------------*/

#include "imageIO.h"

/*--------------------------------------------------------------------------*/
/* Read a FITS image into a floating-point array, noting image size/type.   */
int qreadFITS ( ezImg  *image,                 /* image structure for data  */
                 char  *fname  );              /* name of FITS file to load */

/*--------------------------------------------------------------------------*/
/* Write a floating-point FITS image from an array.                         */
int qwriteFITS( ezImg  *image,               /*  structure with image data  */
                 char  *fname  );            /* output FITS image file name */

/*--------------------------------------------------------------------------*/
/* Save image data to disk, optionally copy image headers: */
int hdr_qwrite( ezImg *img,        /*  ezImg structure to store attributes  */
                 char *imname,     /*    name of new FITS file to create    */
                 char *hdr_src );  /* optional: get headers from this image */

/*--------------------------------------------------------------------------*/
/* Create blank (allocated) ezImg of specified size:                        */
int blank_image_dimen(ezImg *image, long xpix, long ypix);

/*--------------------------------------------------------------------------*/
/* Create blank (allocated) ezImg of matching size:                         */
int blank_image_like(ezImg *src, ezImg *dst);

/*--------------------------------------------------------------------------*/
/* Duplicate an image structure, including data (eg, working copy):         */
int new_full_image_copy(ezImg *src, ezImg *dst);

