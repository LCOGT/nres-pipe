/****************************************************************************/
/*                                                                          */
/*    Simplify the manipulation of FITS image headers.                      */
/*                                                                          */
/* Rob Siverd                                                               */
/* Created:       2010-07-21                                                */
/* Last modified: 2014-04-24                                                */
/*                                                                          */
/****************************************************************************/
/****************************************************************************/
/*--------------------------------------------------------------------------*/

#include    <math.h>
#include   <stdio.h>
#include  <stdlib.h>
#include  <string.h>

#include "imageIO.h"

#ifndef QUOTEME
#define QUOTEME_(x) #x
#define QUOTEME(x) QUOTEME_(x)
#endif

/****************************************************************************/

/*--------------------------------------------------------------------------*/
/* Add file creation date & time to the specified FITS image header:        */
int add_date_card(ezImg *img)
{
   int status = 0;  /* initialize CFITSIO status */
   return fits_write_date(img->fptr, &status);
}

/*--------------------------------------------------------------------------*/
/* Add a history card to the specified FITS image header:                   */
int add_hist_card(ezImg *img, char *hist)
{
   int status = 0;  /* initialize CFITSIO status */
   return fits_write_history(img->fptr, hist, &status);
}

/****************************************************************************/

/*--------------------------------------------------------------------------*/
/*    Update or write the given keyword in the specified FITS image header. */
int upd_hdr_key  ( 
                   ezImg *img,       /* structure with pointer to FITS file */
                     int  type,      /* CFITSIO type for new FITS keyword   */
                    char *keyName,   /*       name of new FITS keyword      */
                    void *keyVal,    /*     pointer to new keyword value    */
                    char *comment    /*  optional header key comment string */
                 )
{
   int status = 0;  /* initialize CFITSIO status */

   /* Abort if destination not open: */
   if ( !ezImg_is_open(img) ) {
      fputs("\nupd_hdr_key: Destination not open!\n", stderr);
      return 1;
   }

   /* Abort if destination not writeable: */
   if ( img->fmode == 0 ) {
      fputs("\nupd_hdr_key: Destination not open for writing!\n", stderr);
      return 1;
   }

   /* write new keyword, check for error: */
   if ( fits_update_key(img->fptr, type, keyName, keyVal, comment, &status) ) {
      fputs("\nupd_hdr_key: error updating header key!\n", stderr);
      fits_report_error(stderr, status);
      return 1; /* failure */
   }

   return 0; /* success */
}

/*--------------------------------------------------------------------------*/
/*    Add a new header card to the specified FITS image header.             */
int add_hdr_key  ( 
                   ezImg *img,       /* structure with pointer to FITS file */
                     int  type,      /* data type for new FITS keyword      */
                    char *keyName,   /*       name of new FITS keyword      */
                    void *keyVal,    /*     pointer to new keyword value    */
                    char *comment    /*  optional header key comment string */
                 )
{
   int status = 0;  /* initialize CFITSIO status */

   /* Abort if destination not open: */
   if ( !ezImg_is_open(img) ) {
      fputs("\nadd_hdr_key: Destination not open!\n", stderr);
      return 1;
   }

   /* Abort if destination not writeable: */
   if ( img->fmode == 0 ) {
      fputs("\nadd_hdr_key: Destination not open for writing!\n", stderr);
      return 1;
   }

   /* write new keyword: */
   if ( fits_write_key(img->fptr, type, keyName, keyVal, comment, &status) ) {
      fputs("\nadd_hdr_key: error writing key to header!\n", stderr);
      fits_report_error(stderr, status);
      return 1;
   }
   
   return 0; /* success */
}

/*--------------------------------------------------------------------------*/
/*    Add a comment to the specified FITS image header.                     */
int add_hdr_comment (
                     ezImg *img,     /* structure with pointer to FITS file */
                      char *comment  /*  comment string to write to header  */
                    )
{
   int status = 0;  /* initialize CFITSIO status */

   /* Abort if destination not open: */
   if ( !ezImg_is_open(img) ) {
      fputs("\nadd_hdr_comment: Destination not open!\n", stderr);
      return 1;
   }

   /* Abort if destination not writeable: */
   if ( img->fmode == 0 ) {
      fputs("\nadd_hdr_comment: Destination not open for writing!\n", stderr);
      return 1;
   }

   /* Write comment: */
   if ( fits_write_comment(img->fptr, comment, &status) ) {
      fputs("\nadd_hdr_comment: error writing comment to header!\n", stderr);
      fits_report_error(stderr, status);
      return 1;
   }

   return 0; /* success */
}

/*--------------------------------------------------------------------------*/
/*    Copy all safe headers from one image to another.  This routine skips  */
/* protected FITS keywords.  It also skips scaling and checksum keys since  */
/* these are written automatically by CFITSIO as necessary.                 */
int cpy_all_hdr (
                  ezImg *src,               /*  source image data structure */
                  ezImg *dst,               /*  target image data structure */
                  //int  hdr_flags,         /* choose which headers to copy */
                    int  hdr_mode,          /* controls meaning of new_keys */
                    int  new_keys           /*   number of keys to add/have */
                )
{
   int j = 0;
   int status = 0;          /*      CFITSIO error status      */
   char card[FLEN_CARD];    /* scratch string for header card */

   /* src keyword params: */
   int keyClass = 0;             /*  type of header data in key   */
   int haveKeys = 0;             /* used src keys (excludes END!) */

   /* dst keyword params: */
   int dst_usedKeys = 0;        /* used dst keys (excluding END!) */
   int dst_fullKeys = 0;        /* used dst keys (including END!) */
   int dst_wantKeys = 0;        /* desired number of output keys  */
 //int dst_xtraKeys = 0;        /* remaining unused keyword slots */
   int dst_plusKeys = 0;        /* additional key cards requested */
 
   /* keyword selections: */
 //int skip_wcsKeys = 0;         /* by default, copy WCS keywords */

   /* Check if source image is open: */
   if ( !ezImg_is_open(src) ) {
      fputs("cpy_all_hdr:  src image not open!  Please fix ...\n", stderr);
      abort();  /* oops! */
      //return 1; /* error */
   }
   
   /* Check if destination image is open: */
   if ( !ezImg_is_open(dst) ) {
      fputs("cpy_all_hdr:  dst image not open!  Please fix ...\n", stderr);
      abort();  /* oops! */
      //return 1; /* error */
   }

   /* Access / count src image headers: */
   if ( fits_get_hdrspace(src->fptr, &haveKeys, NULL, &status) ) {
      fputs("cpy_all_hdr:  can't access src headers!\n", stderr);
      fits_report_error(stderr, status); 
      return 1; /* error */
   }

   /* Access / count dst image headers: */
   if ( fits_get_hdrspace(dst->fptr, &dst_usedKeys, NULL, &status) ) {
      fputs("cpy_all_hdr:  can't access dst headers!\n", stderr);
      fits_report_error(stderr, status); 
      return 1; /* error */
   }
   dst_fullKeys = dst_usedKeys + 1;  /* includes END keyword! */

   /* ----------------------------------------------------------- */

   /* Calculate size adjustment: */
   if ( new_keys > 0 ) {
      switch ( hdr_mode ) {

         case HDR_ADD_EXTRA:
            dst_wantKeys = dst_fullKeys + new_keys;
            break;

         case HDR_SET_TOTAL:
            dst_wantKeys = new_keys;
            /* fix bad choices and warn user:*/
            if ( dst_wantKeys < dst_fullKeys ) {
               fprintf(stderr, "%s: cpy_all_hdr warning: keyword overflow!\n",
                     QUOTEME(ERROR_SOURCE));
               dst_wantKeys = dst_fullKeys + new_keys; /* HDR_ADD_EXTRA mode */
            }
            break;

         default:
            fputs("cpy_all_hdr: unhandled header request!\n", stderr);
            return 1; /* error */
      }

      /* How many to add: */
      dst_plusKeys = dst_wantKeys - dst_fullKeys;
   }

   /* Set output header size: */
   if ( fits_set_hdrsize(dst->fptr, dst_plusKeys, &status) ) {
      fputs("ERROR!  can't allocate dst headers!\n", stderr);
      fits_report_error(stderr, status); 
      return 1; /* error */
   }

   /* ---------------------------------------------------------------- */

   /* Copy header keys: */
   for ( j = 1; j <= haveKeys; j++ ) {
      if ( fits_read_record(src->fptr, j, card, &status) ) break;

      /* Omit any pre-compression checksums: */
      if ( strncmp(card, "ZHECKSUM", 8) == 0 ) continue;
      if ( strncmp(card, "ZDATASUM", 8) == 0 ) continue;
      if ( strncmp(card, "ZQUANTIZ", 8) == 0 ) continue;
      if ( strncmp(card, "ZDITHER0", 8) == 0 ) continue;

      /* Copy select keywords: */
      keyClass = fits_get_keyclass(card);
      if ( keyClass > TYP_SCAL_KEY ) {
         if ( keyClass != TYP_CKSUM_KEY ) {
            fits_write_record(dst->fptr, card, &status);
            if ( status ) {
               fputs("ERROR!  Failed to write header!\n", stderr);
               fits_report_error(stderr, status); 
               return 1; /* error */
            }
         }
      }
   }

   return 0; /* success */
}

/*--------------------------------------------------------------------------*/
/*    Extend the image header length to leave room for future keys.         */
int extend_header (
                   ezImg *img,       /* structure with pointer to FITS file */
                     int  add_keys   /* leave space for this many more keys */
                  )
{
   int nKeys = 0;        /* Number of header cards found */
   int status = 0;       /* CFITSIO error status         */

   /* Check if target image is open: */
   if ( !ezImg_is_open(img) ) {
      fputs("ERROR!  Target image not open!\n", stderr);
      return 1;
   }

   /* Abort if target image not writeable: */
   if ( img->fmode == 0 ) {
      fputs("\nextend_header: target not open for writing!\n", stderr);
      return 1;
   }

   /* Access image header space: */
   if ( fits_get_hdrspace(img->fptr, &nKeys, NULL, &status) ) {
      fputs("ERROR!  can't access headers!\n", stderr);
      fits_report_error(stderr, status); 
      return 1; /* error */
   }

   /* Allocate destination header space: */
   if ( fits_set_hdrsize(img->fptr, add_keys, &status) ) {
      fputs("ERROR!  can't allocate new headers!\n", stderr);
      fits_report_error(stderr, status); 
      return 1; /* error */
   }

   return 0; /* success */
}

/*--------------------------------------------------------------------------*/
/* Extend the image header length to a specific size.                       */
int set_new_hsize (
                   ezImg *img,       /* structure with pointer to FITS file */
                     int  new_size   /* desired number of header keys/cards */
                  )
{
   int nKeys = 0;          /* Number of header cards found  */
   int status = 0;         /* CFITSIO error status          */
   int add_keys = 0;       /* number of additional keywords */

   /* Check if source image is open: */
   if ( !ezImg_is_open(img) ) {
      fputs("ERROR!  Output image not open!\n", stderr);
      return 1;
   }

   /* Abort if target image not writeable: */
   if ( img->fmode == 0 ) {
      fputs("\nset_new_hsize: target not open for writing!\n", stderr);
      return 1;
   }

   /* Access image header space: */
   if ( fits_get_hdrspace(img->fptr, &nKeys, NULL, &status) ) {
      fputs("ERROR!  Can't access headers!\n", stderr);
      fits_report_error(stderr, status); 
      return 1; /* error */
   }

   /* Require new size >= current size: */
   if ( nKeys >= new_size ) {
      fprintf(stderr, "\nset_new_hsize: requested size is smaller than "
            "existing header! (%d <= %d)\n", new_size, nKeys);
      return 1; /* error */
   }

   /* Allocate destination header space: */
   add_keys = new_size - nKeys;          /* number of extra slots needed */
   if ( fits_set_hdrsize(img->fptr, add_keys, &status) ) {
      fputs("ERROR!  Can't allocate new headers!\n", stderr);
      fits_report_error(stderr, status); 
      return 1; /* error */
   }

   return 0; /* success */
}

/*--------------------------------------------------------------------------*/
/* Remove the specified header card image:                                  */
int delete_hcard (
                   ezImg *img,          /* structure with image and headers */
                    char *key_name,     /* name of header keyword to remove */
                     int  silent        /* disables missing keyword warning */
                 )
{
   int nKeys = 0;        /* Number of header cards found */
   int status = 0;       /* CFITSIO error status         */

   /* Select source header space: */
   if ( fits_get_hdrspace(img->fptr, &nKeys, NULL, &status) ) {
      fputs("ERROR!  Can't access FITS headers!\n", stderr);
      fits_report_error(stderr, status);
      return 1; /* error */
   }

   /* Remove the specified key: */
   fits_delete_key(img->fptr, key_name, &status);

   /* Note missing-key error (not a problem): */
   if ( status == KEY_NO_EXIST ) {
      if ( !silent ) fprintf(stderr, "Key '%s' not found.\n", key_name);
      return 0; /* success */
   }

   /* Other errors are bad: */
   if ( status ) {
      fputs("ERROR!  Failed to read/delete header record!\n", stderr);
      fits_report_error(stderr, status);
      return 1; /* error */
   }

   return 0; /* success */
}

/*--------------------------------------------------------------------------*/

#undef QUOTEME
#undef QUOTEME_

