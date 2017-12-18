/****************************************************************************/
/*                                                                          */
/*    Functions to simplify reading and writing of FITS images.             */
/*                                                                          */
/* Rob Siverd                                                               */
/* Created:       2010-06-25                                                */
/* Last modified: 2015-06-22                                                */
/*                                                                          */
/****************************************************************************/
/****************************************************************************/
/*--------------------------------------------------------------------------*/

/* Various standard libraries: */
#include    <math.h>
#include   <stdio.h>
#include  <stdlib.h>
#include  <string.h>

/* Specialized memory allocation (if available): */
#include "fastmem.h"

/* Prototypes: */
#include "imageIO.h"

/*--------------------------------------------------------------------------*/
/* Sanity check for FITS file names:                                        */
int name_check_fail(char *fname)
{
   /* Check for NULL pointer: */
   if ( fname == NULL ) {
      fprintf(stderr, "\nName string not defined!\n");
      return 1; /* failure */
   }

   /* Make sure the filename has nonzero length: */
   if ( strlen(fname) == 0 ) {
      fprintf(stderr, "\nFITS filename is blank (zero length)!\n");
      return 1; /* failure */
   } 

   /* Make sure the filename has length < FLEN_FILENAME: */
   if ( strlen(fname) > FLEN_FILENAME ) {
      fprintf(stderr, "\nFile names cannot exceed %d "
            "characters in length! (CFITSIO limitation)\n", FLEN_FILENAME);
      return 1; /* failure */
   }

   return 0;  /* all tests passed */
}

/*--------------------------------------------------------------------------*/
/* Check the size of file names and exit if too large:                      */
void check_fits_name(char *fname)
{  
   /* Make sure the filename has nonzero length: */
   if ( strlen(fname) == 0 ) {
      fprintf(stderr, "\nFITS filename is blank!\n\n");
      exit(EXIT_FAILURE);
   } 

   /* Make sure the filename has length < FLEN_FILENAME: */
   if ( strlen(fname) > FLEN_FILENAME ) {
      fprintf(stderr, "\nFile names cannot exceed %d "
            "characters in length! (CFITSIO limitation)\n\n", FLEN_FILENAME);
      exit(EXIT_FAILURE);
   }
}  

/*--------------------------------------------------------------------------*/
/* Parse FITS root name (i.e., remove CFITSIO filters):                     */
void parse_frootname(char *fname, char *rstring)
{  
   int status = 0;  /* initialize CFITSIO status */
   if ( fits_parse_rootname(fname, rstring, &status) ) {
      fprintf(stderr, "Failed to parse name: %s\n", fname);
      fits_report_error(stderr, status);
      exit(EXIT_FAILURE);
   }
}

/*--------------------------------------------------------------------------*/
/* Compare size and shape of two images:                                    */
int same_size(ezImg *img1, ezImg *img2)
{
   if ( img1->naxis != img2->naxis ) { return 0; }
   for ( int i = 0; i < img1->naxis; i++ ) {
      if ( (img1->naxes)[i] != (img2->naxes)[i] ) { return 0; }
   }
   return 1; 
}

/*--------------------------------------------------------------------------*/
/* Print basic image attributes (e.g., size, shape, & BITPIX) to screen:    */
void print_size( ezImg *img,       /* ezImg structure to store attributes   */
                  FILE *dest )     /* where to print image attributes       */
{
   fprintf(dest,
         "\n"
         "  ----------------------\n"
         "  |  BITPIX:   %6ld  |\n"
         "  |  NAXIS:    %6ld  |\n",
         (long)img->BitPix, (long)img->naxis);

   for ( int i = 0; i < img->naxis; i++ ) {
      fprintf(dest,
         "  |  NAXIS%d:   %6ld  |\n",
         i + 1, img->naxes[i]);
   }

   fprintf(dest,
         "  ----------------------\n"
         "\n");
   return;
}

/*--------------------------------------------------------------------------*/
/* Obtain size and shape of specified FITS image.                           */
int get_img_size  (
                  ezImg *img,      /* ezImg structure to store attributes   */
                   char *imname    /* name of FITS file to open and check   */
                  )
{
   /* Open image, get attributes: */
   if ( ez_open_FITS(img, imname, READONLY) ) { /* error */ return 1; }

   /* Close opened FITS image: */
   if ( ez_close_FITS(img) ) { /* error */ return 1; }

   return 0;
}

/*--------------------------------------------------------------------------*/
/* Quick check for inconsistent dimensions:                                 */
int has_bad_dims(ezImg *img)
{
   /* Count 'naxes' pixels: */
   long npix = 1;
   for ( int i = 0; i < img->naxis; i++ ) { npix *= img->naxes[i]; }

   /* Check for consistency: */
   if ( npix != img->NumPix ) {
      fprintf(stderr, "\nERROR!  Dimensionality not consistent!\n\n");
      fprintf(stderr, "npix:   %ld\n", npix);
      fprintf(stderr, "NumPix: %ld\n", img->NumPix);
      print_size(img, stderr);
      return 1; /* consistency check FAILED */
   } else {
      return 0; /* consistency check passed */
   }
}

/*--------------------------------------------------------------------------*/
/* Convert 1-D pixel coordinate to N-dimensions (NOT ARRAY COORDS):         */
int ezi_pixcoo_1d_to_Nd (
                       ezImg *img,       /*  in: image data structure       */
                        long  pixpos_1,  /*  in: 1-D/linear pixel position  */
                        long *pixpos_n   /* out: array with N-D coordinate  */
                        )
{
   /* Array positions: */
   long mempos_n[MAXDIM]; 
   long mempos_1 = pixpos_1 - 1;

   /* Compute multi-dimensional position: */
   for ( int d = MAXDIM - 1; d >= 0; d-- ) {
      long pixel_stride = img->pstep[d];
      mempos_n[d] = mempos_1 / pixel_stride;    /* multi-dim array coords */
      mempos_1 -= mempos_n[d] * pixel_stride;   /* decrement current posn */
      pixpos_n[d] = mempos_n[d] + 1;            /* multi-dim pixel coords */
   }

   return 0; /* success */
}

/****************************************************************************/
/**************        mid-level pixel access routines          *************/
/****************************************************************************/

/*--------------------------------------------------------------------------*/
/* Read 1D pixel data from open input image:                                */
int ez_loadpix( ezImg *img )  /* ezImg structure stores data and attributes */
{
   int status = 0;                      /* Initialize CFITSIO error status  */
   int anynul = 0;                      /* CFITISO: bad/blank pixel counter */
   DTYPE nulval = (DTYPE)nan("");       /* CFITSIO: undefined pixel value   */
 //long fpixel[2] = { 1,1 };            /* CFITSIO: first pixel in subset   */
 //long fpixel[9] = { 1,1 };            /* CFITSIO: first pixel in subset   */
 //long fpixel[MAXDIM];                 /* CFITSIO: first pixel in subset   */
 //for ( int i = 0; i < MAXDIM; i++ ) fpixel[i] = 1;  /* start at beginning */
   
   /* Make sure image is open: */
   if ( !ezImg_is_open(img) ) {
      fprintf(stderr, "Error!  Not open for reading: %s\n", img->fname);
      return 1; /* failure */ 
   }
   
   /* Check for NULL pointers: */
   if ( (img->pix1D == NULL) || (img->pix2D == NULL) ) {
      fprintf(stderr, "Error!  No memory allocated for: %s\n", img->fname);
      return 1; /* failure */
   }

   /* Read entire image: */
 //fits_read_pix(img->fptr, TDTYPE, fpixel, img->NumPix, &nulval, img->pix1D,
   fits_read_img(img->fptr, TDTYPE,      1, img->NumPix, &nulval, img->pix1D,
                                                         &anynul, &status);
   if ( status ) {
      fprintf(stderr, "Error reading image data: %s\n", img->fname);
      fits_report_error(stderr, status);
      fits_close_file(img->fptr, &status);
      return 1; /* failure */
   }

   return 0; /* success */
}

/*--------------------------------------------------------------------------*/
/* Write 1D pixel data to open output image:                                */
int ez_savepix(ezImg *img)    /* ezImg structure stores data and attributes */
{
   int status = 0;
 //long fpixel[2] = { 1,1 };       /*  CFITSIO: first pixel in subset       */
 //long fpixel[MAXDIM];                 /* CFITSIO: first pixel in subset   */
 //for ( int i = 0; i < MAXDIM; i++ ) fpixel[i] = 1;  /* start at beginning */

   /* make sure pixels exist: */
   if ( (img->pix1D == NULL) || (img->pix2D == NULL) ) {
      fprintf(stderr, "\nsavepix error: pixel array(s) not allocated!\n\n");
      abort(); /* oops! */
      //return 1; /* failure */ 
   }

   /* make sure image is open: */
   if ( !ezImg_is_open(img) ) {
      fprintf(stderr, "\nsavepix error: image not open for writing!\n\n");
      abort(); /* oops! */
      //return 1; /* failure */ 
   }
   
   /* write pixel data to image file: */
 //fits_write_pix(img->fptr, TDTYPE, fpixel, img->NumPix, img->pix1D, &status);
   fits_write_img(img->fptr, TDTYPE, 1, img->NumPix, img->pix1D, &status);
   if ( status ) {
      fprintf(stderr, "\nError writing pixels to image!\n\n");
      fits_report_error(stderr, status);
      return 1; /* failure */
   }

   return 0; /* success */
}

/****************************************************************************/
/**************       lower-level structure manipulation        *************/
/****************************************************************************/

/*--------------------------------------------------------------------------*/
/* Initialize an ezImg structure with useful (wrong) default values:        */
int init_ezImg(ezImg *img)    /* ezImg structure stores data and attributes */
{
   img->BitPix = 0;
   img->naxis  = 0;
   img->NumPix = 0;
 //img->naxes[0] = 0;
 //img->naxes[1] = 0;
   for ( int i = 0; i < MAXDIM; i++ ) img->naxes[i] = 0;
   for ( int i = 0; i < MAXDIM; i++ ) img->pstep[i] = 0;
   img->pix1D  = NULL;
   img->pix2D  = NULL;
   img->fptr   = NULL;
   img->FType  = 0;
   img->fname  = NULL;
   img->fmode  = 0;      /* file access mode (READONLY or READWRITE) */
   img->eqType = 0;      /* equivalent image type */
   img->nKeys  = 0;      /* number of header keywords */

   return 0; /* success */ 
}

/*--------------------------------------------------------------------------*/
/* Duplicate an existing ezImg structure, (shares data pointers):           */
int copy_ezImg    (
                  ezImg *src,     /* source structure for image data+params */
                  ezImg *dst      /* target structure for image data+params */
                  )
{
   /* Make sure source structure is initialized: */
   if ( src->NumPix == 0 ) {
      fputs("\ncopy_ezImg: Source ezImg structure is empty!\n", stderr);
      return 1;
   }

   /* Copy size and shape info: */
   copy_imgSS(src, dst);
 //dst->BitPix   = src->BitPix;
 //dst->naxis    = src->naxis;
 //dst->NumPix   = src->NumPix;
 //for ( int i = 0; i < MAXDIM; i++ ) dst->naxes[i] = src->naxes[i];
 //dst->FType    = src->FType; 

   /* Copy other attributes: */
   dst->eqType   = src->eqType;
   dst->nKeys    = src->nKeys;
   dst->pix1D    = src->pix1D;
   dst->pix2D    = src->pix2D;
 //dst->fptr     = src->fptr;

   return 0; /* success */
}

/*--------------------------------------------------------------------------*/
/* Copy image size and shape from one ezImg structure to another:           */
int copy_imgSS(ezImg *src, ezImg *dst)
{
   /* Make sure source structure is initialized: */
   if ( src->NumPix == 0 ) {
      fputs("\ncopy_imgSS: Source ezImg structure is empty!\n", stderr);
      return 1;
   }

   dst->BitPix   = src->BitPix;
   dst->naxis    = src->naxis;
   dst->NumPix   = src->NumPix;
 //dst->naxes[0] = src->naxes[0];
 //dst->naxes[1] = src->naxes[1];
   for ( int i = 0; i < MAXDIM; i++ ) dst->naxes[i] = src->naxes[i];
   for ( int i = 0; i < MAXDIM; i++ ) dst->pstep[i] = src->pstep[i];
   dst->FType    = src->FType; 

   return 0; /* success */
}

/*--------------------------------------------------------------------------*/
/* Swap pixel arrays between two ezImg structures:                          */
int swap_pixels(ezImg *img1, ezImg *img2)
{
   DTYPE  *px1 = img1->pix1D;
   DTYPE **px2 = img1->pix2D;
   img1->pix1D = img2->pix1D;
   img1->pix2D = img2->pix2D;
   img2->pix1D = px1;
   img2->pix2D = px2;
   return 0;
}

/*--------------------------------------------------------------------------*/
/* Copy pixel data from one ezImg structure to another:                     */
int copy_pixels(ezImg *img1, ezImg *img2)
{
   /* Check for allocated memory in image 1: */
   if ( (img1->pix1D == NULL) || (img1->pix2D == NULL) ) {
      fputs("copy_pixels error:  img1 not allocated!\n", stderr);
      abort(); /* oops! */
      //return 1; /* failure */
   }
   
   /* Check for allocated memory in image 2: */
   if ( img2->pix1D == NULL || img2->pix2D == NULL ) {
      fputs("copy_pixels error:  img2 not allocated!\n", stderr);
      abort(); /* oops! */
      //return 1; /* failure */
   }

   /* Require that images be same size: */
   if ( !same_size(img1, img2) ) {
      fputs("copy_pixels error:  imgs not same size!\n", stderr);
      return 1; /* failure */
   }

   /* Copy pixels from image 1 to image 2: */
   for ( int i = 0; i < img1->NumPix; i++ ) { 
      (img2->pix1D)[i] = (img1->pix1D)[i];
   }

   return 0; /* success */
}

/*--------------------------------------------------------------------------*/
/* Initialize an ezImg structure with useful (wrong) default values:        */
int alloc_ezImg(ezImg *img)   /* ezImg structure stores data and attributes */
{
   long Y, bytes;

   /* Check dimensional consistency: */
   if ( has_bad_dims(img) ) abort();

   /* Check image data pointers: */
   if ( (img->pix1D) || (img->pix2D) )
   {  /* data arrays not blank (probably allocated) */
      fprintf(stderr, "\n");
      fprintf(stderr, "ERROR! alloc_ezImg: arrays already allocated!\n\n");
      fprintf(stderr, "img->pix1D: %p\n", img->pix1D);
      fprintf(stderr, "img->pix2D: %p\n", img->pix2D);
      fprintf(stderr, "img->fname: %s\n", img->fname);
      fprintf(stderr, "\n");
      return 1;
   }

   /* Temporary X,Y dimensions: */
   //int ndim = img->naxis;
   long NX = (img->naxes)[0];
   long NY = (img->naxes)[1];

   /* Allocate image storage (128-byte alignment for SSEx if possible): */
   bytes = img->NumPix * sizeof(*(img->pix1D)); /* memory needed */
   if ( allocate_aligned_array((void**)&(img->pix1D), bytes, IMG_ALIGN) ) {
      fputs("\nFailed to allocate 1D image array!!\n\n", stderr);
      return 1;
   }

   /* Allocate row-pointer storage (128-byte alignment if possible): */
   bytes = NY * sizeof(*(img->pix2D));
   if ( allocate_aligned_array((void**)&(img->pix2D), bytes, IMG_ALIGN) ) {
      fputs("\nFailed to allocate row pointer array!!\n\n", stderr);
      return 1;
   }

   /* Fill array with pointers to rows: */
   for ( Y = 0; Y < NY; Y++ ) { 
      (img->pix2D)[Y] = &( (img->pix1D)[NX*Y] ); /* set up row access */
   }

   return 0; /* success */
}

/*--------------------------------------------------------------------------*/
/* Zero out all ezImg pixels:                                               */
int ezi_zero_fill(ezImg *img)
{
   /* Image must be allocated: */
   if ( (img->pix1D == NULL) || (img->pix2D == NULL) ) {
      fputs("ezi_zero_fill error:  img not allocated!\n", stderr);
      abort(); /* oops! */
   }

   /* Check dimensional consistency: */
   if ( has_bad_dims(img) ) abort();

   /* Set all pixels to 0: */
   for ( long i = 0; i < img->NumPix; i++ ) { img->pix1D[i] = (DTYPE)0; }

   return 0; /* success */
}

/*--------------------------------------------------------------------------*/
/* De-allocate all storage currently allocate in ezImg structure:           */
int free_ezImg(ezImg *img)
{
   if ( img->pix2D ) {
      free(img->pix2D);
      img->pix2D = NULL;
   }
   if ( img->pix1D ) {
      free(img->pix1D);
      img->pix1D = NULL;
   }
   return 0; /* success */ 
}

/*--------------------------------------------------------------------------*/
/* Verify that an ezImg structure is in use:                                */
int ezImg_is_open(ezImg *img)
{
   /* non-NULL pointer indicates open image: */
   if ( img->fptr ) {
      return 1;  /* return true */
   } else { 
      return 0;  /* return false */
   }
}

/*--------------------------------------------------------------------------*/
/* Update CHECKSUM and DATASUM header keywords.                             */
int ez_checksum(ezImg *img)
{
   int status = 0;            /* Initialize CFITSIO status */

   /* New CHECKSUM and DATASUM values: */
   if ( fits_write_chksum(img->fptr, &status) ) {
      fputs("Error updating checksum!\n", stderr);
      fits_report_error(stderr, status);
      return 1; /* error */
   }
   
   return 0; /* success */
}

/*--------------------------------------------------------------------------*/
/* Open a FITS image for reading.  Populates ezImg structure.               */
int ez_open_FITS(ezImg *img, char *imname, int mode)
{
   int nKeys = 0;             /* number of header keywords */
   int status = 0;            /* Initialize CFITSIO status */
   int exists = 0;            /* does image exist on disk? */
   int isfile = 1;            /* note special file streams */

   /* Check file access mode: */
   if ( mode != READONLY && mode != READWRITE ) {
      fputs("\nInvalid FITS file access mode !!\n\n", stderr);
      abort(); /* oops! */
      //return 1; /* error */
   }
   /* Check for already-open image in structure: */
   if ( ezImg_is_open(img) ) {
      fputs("\nError!  ezImg structure already in use!\n\n", stderr);
      abort(); /* oops! */
      //return 1; /* error */
   }

   /* Check if image is special stream: */
   if ( (strnlen(imname, 8) == 1) && (strncmp(imname, "-", 1) == 0) ) {
      isfile = 0;
   }
   if ( (strnlen(imname, 8) == 5) && (strncmp(imname, "stdin", 1) == 0) ) {
      isfile = 0;
   }

   /* Check that image exists (except special streams): */
   if ( isfile ) {
      fits_file_exists(imname, &exists, &status);
      switch ( exists ) {
         case -1:
            fprintf(stderr, "Warning: input URL could not be verified ...\n");
            break;
         case 0:
            fprintf(stderr, "\nError!  File not found: %s\n\n", imname);
            return 1; /* error */
            break;
         case 1:
            /* file found, do nothing */
            break;
         case 2:
            fprintf(stderr, "Warning: using compressed version of file!\n");
            break;
         default:
            fprintf(stderr, "\n"
                  "Error!!  Unhandled 'exists' value in ez_open_FITS: %d\n\n"
                  "PLEASE FIX THIS !!\n\n", exists);
            exit(EXIT_FAILURE); /* error */
      }
   }

   /* Record input image name and access mode: */
   img->fname = imname;
   img->fmode = mode;

   /* pre-set all NAXISn to 1 to simplify multi-dimensional indexing: */
   for ( int i = 0; i < MAXDIM; i++ ) { img->naxes[i] = (long)1; }

   /* open image, record parameters: */
   if ( !fits_open_image(&(img->fptr), imname, mode, &status) ) {
      /* count TRUE dimensions: */
      int tru_naxis;
      fits_get_img_dim(img->fptr, &tru_naxis, &status);
      //fprintf(stderr, "tru_naxis: %d\n", tru_naxis);

      /* fetch parameters: */
      fits_get_img_param(img->fptr, MAXDIM, &(img->BitPix),
            &(img->naxis), img->naxes, &status);

      /* abort if image dimensionality is too great: */
      if ( tru_naxis > MAXDIM ) {
         fprintf(stderr, "\n\nPROBLEM: image has too many dimensions!\n\n");
         fprintf(stderr, "NAXIS:   %5d  <-- image contains\n", tru_naxis);
         fprintf(stderr, "MAXDIM:  %5d  <-- max supported\n", MAXDIM);
         fprintf(stderr, "\n\n");
         abort();
      }
    //fprintf(stderr, "status: %d\n\n", status);
    //print_size(img, stderr);
    //img->NumPix = (img->naxes)[0] * (img->naxes)[1]; /* total image pixels */

      /* Tally up all the pixels: */
      img->NumPix = 1;
      for ( int i = 0; i < img->naxis; i++ ) { img->NumPix *= img->naxes[i]; }
    //fputc('\n', stderr);
    //for ( int i = 0; i < MAXDIM; i++ ) { 
    //   fprintf(stderr, "NAXIS%d:   %4ld\n", i+1, img->naxes[i]);
    //}

      /* Fill pstep array (per-axis pixel step size): */
      img->pstep[0] = 1;
      for ( int i = 1; i < MAXDIM; i++ ) {
         img->pstep[i] = img->pstep[i-1] * img->naxes[i-1];
      }

      /* Determine equivalent image type: */
      if ( fits_get_img_equivtype(img->fptr, &(img->eqType), &status) ) {
         fprintf(stderr, "\nError reading image attributes: %s\n", imname );
         fits_report_error(stderr, status);
         fits_close_file(img->fptr, &status);
         return 1; /* error */
      }
   } else {
      fprintf(stderr, "\nFailed to open file: %s\n", imname);
      if ( status ) fits_report_error(stderr, status);
      fits_close_file(img->fptr, &status);
      return 1; /* error */
   }

   /* Count image headers: */
   fits_get_hdrspace(img->fptr, &nKeys, NULL, &status);
   img->nKeys = nKeys; /* save header count */

   return 0; /* success */
}

/*--------------------------------------------------------------------------*/
/* Close an open FITS image and check for errors.                           */
int ez_close_FITS(ezImg *img)
{
   int status = 0;   /* CFITSIO current error status */

   /* make sure image is open: */
   if ( ezImg_is_open(img) ) 
   {  /* image was open, close file: */
      fits_close_file(img->fptr, &status);
      if ( status ) { 
         fputs("Error closing file!\n", stderr);
         fits_report_error(stderr, status);
         return 1; /* error */
      }
      img->fptr  = NULL; /* reset file pointer */
      img->fname = NULL; /* unlearn image name */
      img->fmode = 0;    /* reset access mode  */
   }
   else 
   {  /* image was not open! */ 
      fputs("ezImg is not open!\n\n", stderr);
      return 1; /* error */
   }

   return 0; /* success */
}


/****************************************************************************/
/* Create a new FITS image and open for write access:                       */
int ez_create_FITS(ezImg *img, char *imname)
{
   int status = 0;   /* CFITSIO current error status */

   /* Check for already-open image in structure: */
   if ( ezImg_is_open(img) ) {
      fputs("Error!  ezImg already in use!  Please fix ...\n\n", stderr);
      abort(); /* oops! */
      //return 1; /* error */
   }

   /* Check for selected file type (FType): */
   if ( img->FType == 0 ) {
      fputs("Error!  ezImg type not set!  Please fix ...\n\n", stderr);
      abort(); /* oops! */
      //return 1; /* error */
   }

   /* Check image size: */
   if ( img->naxis == 0 )
   {  /* invalid size! */
      fputs("Error!  ezImg NAXIS undefined!\n\n", stderr);
      abort(); /* oops! */
      //return 1; /* error */
   }

   /* Check each dimension: */
   for ( int i = 0; i < img->naxis; i++ ) {
      if ( img->naxes[i] == 0 ) {
         fprintf(stderr, "\nError!  Dimension %d size not set!\n\n", i);
         return 1; /* error */
      }
   }

   /* Check dimensional consistency: */
   if ( has_bad_dims(img) ) abort();

   /* Record output image name: */
   img->fname = imname;

   /* Create new FITS file: */
   if ( !fits_create_file( &(img->fptr), imname, &status ) )
   {  /* image created successfully */
      fits_create_img(img->fptr, img->FType, img->naxis, img->naxes, &status);
      if ( status ) 
      {  /* error creating image in new FITS file */
         fprintf(stderr, "Error creating image in file: %s\n", imname);
         fits_report_error(stderr, status);
         fits_close_file(img->fptr, &status);
         return 1; /* failure */
      }
   } 
   else 
   {
      fprintf(stderr, "Failed to create file: %s\n", imname);
      if ( status ) fits_report_error(stderr, status);
      fits_close_file(img->fptr, &status);
      return 1; /* failure */
   }

   /* Mark image structure as writeable: */
   img->fmode = READWRITE;

   /* Record creation data in header: */
   fits_write_date(img->fptr, &status);

   return 0; /* success */
}

/****************************************************************************/

